# GM AIエージェントワークフロー（Google ADK）

## 概要

本プロジェクトのゲームマスター（GM）AIは **Google ADK（Agent Development Kit）** を基盤として構築されたエージェントワークフローです。プレイヤーの入力を受け付け、ゲーム状態を参照してナラティブを生成し、SSE（Server-Sent Events）でフロントエンドにリアルタイム配信します。

---

## アーキテクチャ全体図

```
Flutter Frontend
      │  POST /api/gm/turn
      ▼
GmController
      │
      ▼
GmTurnUseCase ─────────────────────────────────────────────────────────────────────┐
      │                                                                             │
      ├─ ContextService (プロンプト構築)                                            │
      │      └─ DB (sessions, turns, npcs, items, objectives, context_summaries)   │
      │                                                                             │
      ├─ GmDecisionService ──── AdkGmClient ──── ADK Runner                       │
      │      └─ リトライ (最大3回) + フォールバック   └─ LlmAgent (Gemini)          │
      │                                                 └─ DatabaseSessionService   │
      │                                                       └─ PostgreSQL (adk schema)
      │
      ├─ StateMutationService (状態反映)
      ├─ ConditionEvaluationService (勝敗条件チェック)
      ├─ TurnGateway (ターン永続化)
      ├─ ContextService.compress (コンテキスト圧縮)
      ├─ GenuiBridgeService (NPC画像生成)
      └─ BgmService (BGM生成)
              │
              ▼
         SSE Events → Flutter Frontend
```

---

## コンポーネント詳細

### 1. AdkGmClient（`src/infra/adk_gm_client.py`）

ADK Runner と DatabaseSessionService をラップした最薄の LLM 呼び出し層。

```python
class AdkGmClient:
    MODEL = "gemini-3-flash-preview"

    def __init__(self) -> None:
        agent = LlmAgent(
            name="gm_agent",
            model=Gemini(model=self.MODEL),
            instruction=GM_SYSTEM_PROMPT,
            output_schema=GmDecisionResponse,  # Pydantic直接指定
        )
        self._runner = Runner(
            agent=agent,
            app_name="gm",
            session_service=_adk_session_service(),
            auto_create_session=True,
        )

    async def decide(self, *, prompt: str, session_id: str) -> GmDecisionResponse:
        ...

    async def cleanup_session(self, session_id: str) -> None:
        ...
```

**設計上の重要な選択**

| 項目 | 選択 | 理由 |
|------|------|------|
| LangChain 不採用 | ✗ | `response_json_schema` が `langchain-google-genai` 未対応 |
| `use_interactions_api` 不採用 | ✗ | `output_schema` と組み合わせると構造化出力が保証されない |
| `auto_create_session=True` | ✅ | セッション作成を ADK に委譲 |
| `DatabaseSessionService` | ✅ | PostgreSQL に ADK セッション履歴を永続化 |
| `output_schema=GmDecisionResponse` | ✅ | Pydantic 直接指定で構造化出力を保証 |

---

### 2. GmDecisionService（`src/domain/service/gm_decision_service.py`）

リトライ・フォールバックを含む GM 決定ドメインサービス。

```python
class GmDecisionService:
    MAX_RETRIES = 3

    async def decide(
        self,
        prompt: str,
        *,
        runtime: GmDecisionRuntime | None = None,
    ) -> GmDecisionResponse:
        for attempt in range(self.MAX_RETRIES):
            try:
                session_id = self._get_or_create_session_id(runtime)
                return await self._adk.decide(prompt=prompt, session_id=session_id)
            except Exception:
                logger.exception("GM decision attempt failed", attempt=attempt + 1)

        # 全リトライ失敗時のフォールバック
        return GmDecisionResponse(
            decision_type="narrate",
            narration_text="The world seems to pause for a moment...",
        )
```

**GmDecisionRuntime（セッション管理の制御）**

```python
@dataclass
class GmDecisionRuntime:
    use_interactions: bool = False  # True: auto-advance マルチターンで同一セッションを継続
    adk_session_id: str | None = None
```

| `use_interactions` | 動作 |
|--------------------|----|
| `False`（デフォルト） | ターンごとに独立した UUID を生成 → 独立セッション |
| `True` | 同一リクエスト内で `adk_session_id` を共有 → 会話履歴を引き継ぎ |

---

### 3. GmTurnUseCase（`src/usecase/gm_turn_usecase.py`）

1ターン分のパイプライン全体を制御するオーケストレーター。

#### ターン処理フロー

```
GmTurnUseCase.execute(request)
│
├─ [1] セッション検証 ─── session_gw.get_by_id()
│
├─ [2] NPCクローン ─────── NpcCloneService.clone_npcs_for_session()
│         └─ start ターンのみ。シナリオNPCをセッションにコピー
│
├─ [ループ開始] ─────────── auto_advance 時に最大 max_auto_turns 回繰り返す
│
├─ [3] コンテキスト構築 ── ContextService.build_context()
│         └─ DB からゲーム状態を収集 → GameContext → プロンプト文字列
│
├─ [4] GM 決定取得 ──────── GmDecisionService.decide()
│         └─ AdkGmClient.decide() → ADK Runner → Gemini API
│         └─ 失敗時は最大3回リトライ → フォールバック
│
├─ [5] 状態反映 ─────────── StateMutationService.apply()
│         └─ stats_delta, item_updates, location_change など DB に反映
│
├─ [6] 勝敗条件評価 ──────── ConditionEvaluationService.evaluate()
│
├─ [7] ターン永続化 ──────── TurnGateway.create()
│
├─ [8] コンテキスト圧縮 ──── ContextService.compress() (閾値超過時のみ)
│         └─ 直近ターンを GeminiClient で要約 → context_summaries テーブル
│
├─ [9] NPC画像生成 ──────── GenuiBridgeService (非同期)
│
├─ [10] SSE ストリーム ───── _stream_turn_events()
│         └─ decision, npc_images, bgm, done イベントを yield
│
└─ [ループ終了判定]
      └─ will_continue=False → break
      └─ continue → current_input_type="do", current_input_text="continue"
```

#### auto_advance モード

`auto_advance_until_user_action=True` が指定された場合、ループが継続します。

```
条件           継続判定
─────────────────────────────
is_ending       → stop
requires_user_action (choice/clarify) → stop
auto_limit_reached (max_auto_turns)   → stop
上記以外        → continue
```

`GEMINI_INTERACTIONS_ENABLED=true` 環境変数 + `auto_advance` 時のみ `GmDecisionRuntime.use_interactions=True` が有効になり、同一 ADK セッションで複数ターンの会話履歴を引き継ぎます。

---

### 4. ADK セッションサービス（`_adk_session_service()`）

#### PostgreSQL スキーマ分離

ADK が自動生成するテーブル（`sessions`, `events`, `app_states` 等）を PostgreSQL の `adk` スキーマに隔離することで、`public` スキーマと衝突しません。

```python
def _adk_session_service() -> DatabaseSessionService:
    raw_url = os.getenv("DATABASE_URL", "postgresql://...@localhost:54322/postgres")

    # 1. asyncpg ダイアレクトに変換
    asyncpg_url = f"postgresql+asyncpg://{raw_url.split('://', 1)[1]}"

    # 2. sslmode=require を URL から除去して connect_args に変換
    #    asyncpg は sslmode クエリパラメータを解釈しない (asyncpg#737)
    parsed = urlparse(asyncpg_url)
    query = parse_qs(parsed.query)
    sslmode = query.pop("sslmode", [None])[0]
    clean_url = urlunparse(parsed._replace(query=urlencode(...)))

    connect_args: dict[str, object] = {
        "server_settings": {"search_path": "adk"},  # スキーマ分離
    }
    if sslmode == "require":
        connect_args["ssl"] = True  # SSL 有効化

    return DatabaseSessionService(clean_url, connect_args=connect_args)
```

**スキーマ分離の効果**

| ツール | 動作 |
|--------|------|
| Drizzle ORM | `schemaFilter: ['public']` のため `adk` スキーマを無視 |
| sqlacodegen | `--schemas public` のため `adk` スキーマをスキャンしない |
| ADK | `adk.sessions`, `adk.events` 等を使用（`public` と完全分離） |

---

### 5. GmDecisionResponse（構造化出力スキーマ）

ADK の `output_schema` に指定する Pydantic モデル。1回の LLM 呼び出しで全情報を返します。

```python
class GmDecisionResponse(BaseModel):
    decision_type: Literal["narrate", "choice", "clarify", "repair"]
    narration_text: str                          # 全ノードのサマリー

    nodes: list[SceneNode] | None = None         # ビジュアルノベル形式の出力

    scene_description: str | None = None         # 背景画像生成トリガー
    selected_background_id: str | None = None    # 既存背景の選択
    bgm_mood: str | None = None                  # BGMムード
    bgm_music_prompt: str | None = None          # BGM生成プロンプト

    choices: list[ChoiceOption] | None = None    # 選択肢
    clarify_question: str | None = None          # 確認質問
    repair: RepairData | None = None             # 矛盾修正

    npc_dialogues: list[NpcDialogue] | None = None
    npc_intents: list[NpcIntent] | None = None

    state_changes: StateChanges | None = None    # ゲーム状態の変更
```

#### decision_type の動作

| 値 | 動作 | auto_advance への影響 |
|----|------|----------------------|
| `narrate` | ストーリーを進行 | 継続 → 次ターン自動生成 |
| `choice` | プレイヤーに選択肢を提示 | **停止** → ユーザー入力待ち |
| `clarify` | 入力が曖昧 → 確認質問 | **停止** → ユーザー入力待ち |
| `repair` | 確立された事実との矛盾を修正 | **停止** → ユーザー入力待ち |

---

## SSE イベント形式

`/api/gm/turn` エンドポイントは以下の SSE イベントを順番に配信します。

```
event: decision
data: { nodes, narration_text, decision_type, ... }

event: npc_images
data: { npc_name: image_url, ... }

event: bgm
data: { mood, url, ... }

event: done
data: { turn_number, requires_user_action, is_ending, will_continue, stop_reason }
```

---

## データベース構成

### PostgreSQL スキーマ

```
public スキーマ（Drizzle 管理）
├── sessions        ゲームセッション
├── turns           ターン履歴
├── npcs            NPCデータ（セッション内クローン）
├── player_characters プレイヤーキャラクター
├── items           所持アイテム
├── objectives      クエスト目標
└── context_summaries コンテキスト圧縮ログ

adk スキーマ（ADK 自動生成）
├── adk.sessions    ADK セッション（会話履歴）
├── adk.events      ADK イベントログ
└── adk.app_states  ADK アプリ状態
```

### スキーマ作成

`adk` スキーマは `drizzle/config/pre-migration/02_adk_schema.sql` で作成されます。

```sql
CREATE SCHEMA IF NOT EXISTS adk;
```

---

## 環境変数

| 変数名 | 用途 | デフォルト |
|--------|------|-----------|
| `GEMINI_API_KEY` | Gemini API キー（優先） | - |
| `GOOGLE_API_KEY` | Gemini API キー（フォールバック） | - |
| `DATABASE_URL` | PostgreSQL 接続 URL | `postgresql://postgres:postgres@localhost:54322/postgres` |
| `GEMINI_INTERACTIONS_ENABLED` | auto_advance 時のセッション共有 | `false` |

---

## 技術的制約と理由

### asyncpg の sslmode 問題

asyncpg は URL クエリの `sslmode` パラメータを解釈しません（[asyncpg#737](https://github.com/MagicStack/asyncpg/issues/737)）。

```python
# ❌ 動作しない
"postgresql+asyncpg://...?sslmode=require"

# ✅ connect_args で指定
connect_args={"ssl": True}
```

`_adk_session_service()` では `DATABASE_URL` に `sslmode=require` が含まれる場合（本番環境の Supabase 等）に自動変換します。

### Supabase 本番環境での接続

| 接続方式 | ポート | ADK との相性 |
|---------|--------|------------|
| 直接接続 | 5432 | ✅ 推奨 |
| セッションプーラー | 5432 | ✅ 利用可 |
| トランザクションプーラー (pgbouncer) | 6543 | ⚠️ `statement_cache_size=0` + `NullPool` 必須 |

ADK の `DatabaseSessionService` は prepared statements を使用するため、トランザクションプーラーとの組み合わせには追加設定が必要です。

### create_async_engine の遅延初期化

SQLAlchemy の `create_async_engine` はエンジン作成時に実際の DB 接続を行いません（lazy initialization）。そのため：

- テストでは `runner.run_async` をモックすることで、PostgreSQL サーバーなしでも単体テストが実行可能
- `_adk_session_service()` は起動時に DB 接続を確立しない

---

## 関連ファイル一覧

| ファイル | 役割 |
|---------|------|
| `src/infra/adk_gm_client.py` | ADK Runner ラッパー（LLM 呼び出し層） |
| `src/domain/service/gm_decision_service.py` | GM 決定ドメインサービス（リトライ・フォールバック） |
| `src/domain/entity/gm_types.py` | `GmDecisionResponse` 等の Pydantic 型定義 |
| `src/domain/entity/gm_prompts.py` | GM システムプロンプト・コンテキストテンプレート |
| `src/usecase/gm_turn_usecase.py` | ターン処理パイプライン全体 |
| `src/controller/gm_controller.py` | HTTP エンドポイント（`/api/gm/turn`） |
| `src/domain/service/context_service.py` | ゲームコンテキスト構築・圧縮 |
| `src/domain/service/state_mutation_service.py` | ゲーム状態反映 |
| `src/domain/service/condition_evaluation_service.py` | 勝敗条件評価 |
| `src/domain/service/genui_bridge_service.py` | NPC 画像生成ブリッジ |
| `src/domain/service/bgm_service.py` | BGM 生成サービス |
| `drizzle/config/pre-migration/02_adk_schema.sql` | `adk` スキーマ作成 SQL |
| `tests/infra/test_adk_gm_client.py` | AdkGmClient 単体テスト（20件） |

---

## 参考資料

- [Google ADK 公式ドキュメント](https://google.github.io/adk-docs/)
- [DatabaseSessionService ソースコード](https://github.com/google/adk-python/blob/main/src/google/adk/sessions/database_session_service.py)
- [asyncpg Issue #737: sslmode 未サポート](https://github.com/MagicStack/asyncpg/issues/737)
- [`docs/_research/2026-03-03-google-adk-database-session-service.md`](./docs/_research/2026-03-03-google-adk-database-session-service.md) — 調査レポート
