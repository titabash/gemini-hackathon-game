# DB設計ドキュメント：GenUI×Flame×AI GM TRPG

## 0. このドキュメントの目的

テーブル定義の詳細は `drizzle/schema/schema.ts` を参照。
本ドキュメントでは**なぜこの設計になっているか**――設計思想、各テーブルの役割、トレードオフの判断を記述する。

---

## 1. 設計原則

### 1.1 シングルプレイヤー前提

本ゲームはシングルプレイヤーTRPGである。この前提が設計全体を貫いている。

- NPC関係値テーブル（`npc_relationships`）は1NPC:1レコードのユニーク制約。マルチプレイヤーでは NPC×PC の多対多になるが、MVPでは不要。
- アイテムテーブル（`items`）は `session_id` で暗黙的にPCの所有物。PCが1人なのでアイテムの所有者カラムは不要。
- RLSポリシーは全テーブルで `sessions.user_id = auth.uid()` の単一パターンに収束する。

### 1.2 JSONBと専用テーブルの使い分け

**原則：UIに一覧表示・個別操作するデータは専用テーブル、AIの参照用メタデータはJSONB。**

| データ | 格納方式 | 理由 |
|--------|---------|------|
| アイテム | `items` テーブル | 画像パス・装備状態など個別操作が必要。一覧UIでフィルタ・ソートする |
| クエスト/目標 | `objectives` テーブル | ステータス遷移（active→completed/failed）を明示的に管理。一覧UIで表示 |
| NPC関係値 | `npc_relationships` テーブル | 数値を個別に更新。関係値一覧UIで表示 |
| PCステータス | `stats` JSONB | HP/MP/STR等のゲームパラメータ。構造がシナリオにより可変。AI GMが一括参照する |
| NPCプロフィール | `profile` JSONB | 口調・価値観・禁則等。AI GMプロンプトへの注入が主用途 |
| NPC目的 | `goals` JSONB | NPC行動判断用。AI GMが内部的に参照するだけ |
| NPC状態 | `state` JSONB | HP・気分・フラグ等。ゲームごとに構造が異なる |
| ゲーム全体状態 | `current_state` JSONB | グローバルフラグ・環境状態など。AI GMが毎ターン参照する巨大コンテキスト |
| ターン出力 | `output` JSONB | GenUI用の構造化出力。UIコンポーネント定義を含む |
| 勝利/敗北条件 | JSONB | シナリオ定義の一部。条件構造がシナリオにより可変 |

**判断基準のまとめ：**
- CRUDの頻度が高い → 専用テーブル
- フィルタ・ソート・ページネーションが必要 → 専用テーブル
- 画像パスなどストレージ連携がある → 専用テーブル
- AI GMが一括で読み書きする → JSONB
- 構造がシナリオ/ジャンルにより可変 → JSONB

### 1.3 UUID主キー

全テーブルでUUID（`defaultRandom()`）を使用。

- Supabase Auth（`auth.users.id`）がUUIDのため統一
- 連番はレコード数が推測可能でセキュリティ上望ましくない
- 分散システムでの衝突回避（将来のスケール対応）

唯一の例外は `users.id` で、`auth.users.id` を直接受け取るため `defaultRandom()` を付けない。

### 1.4 RLSの一貫パターン

全テーブルでRow Level Security (RLS)を有効化。ポリシーは3パターンに集約される。

| パターン | 対象テーブル | ロジック |
|---------|------------|---------|
| 直接所有 | `users`, `sessions` | `auth.uid() = user_id` （または `= id`） |
| セッション経由 | `player_characters`, `npcs`, `turns`, `items`, `objectives`, `context_summaries` | `EXISTS (SELECT 1 FROM sessions WHERE sessions.id = *.session_id AND sessions.user_id = auth.uid())` |
| 多段経由 | `npc_relationships` | `EXISTS (SELECT 1 FROM npcs JOIN sessions ... WHERE sessions.user_id = auth.uid())` |

特殊ケース：
- `scenarios`: 公開シナリオは全員閲覧可、自分のシナリオのみ全操作可
- `scene_backgrounds`: シナリオ定義の背景とセッション動的生成の背景で条件分岐
- `users`: Auth Hook用に `supabase_auth_admin` の INSERT ポリシーを別途設定

**RLSヘルパー関数は使わない**（`drizzle/schema/` 内にインライン定義）。理由は `.claude/rules/database.md` に記載。

---

## 2. テーブル設計の思想

### 2.1 users — プレイヤーアカウント

**役割：** Supabase Authと連携するアプリケーション側のユーザーテーブル。

Auth Hook（`handle_new_user()`）によりサインアップ時に自動挿入される。`id` は `auth.users.id` と一致させ、アプリケーション固有の属性（表示名、アバター画像パス）を保持する。

`account_name` はユニーク制約付きで、サインアップ時に `raw_user_meta_data` から取得。将来のUGCシナリオ共有やプロフィール表示に使用する。

### 2.2 scenarios — シナリオテンプレート

**役割：** ゲームの「型」を定義する再利用可能なテンプレート。

シナリオはセッションから独立して存在する。同じシナリオから複数回セッションを開始できる。これにより：
- プリセットシナリオの提供が容易
- 将来のUGCシナリオ共有の基盤になる
- シナリオ改善時に既存セッションに影響しない

`initial_state` JSONBがシナリオの核心。PC初期ステータス、NPC定義、初期目標、コンテキストシードなど、セッション開始時に展開されるすべての初期データを含む。JSONBにした理由は、ジャンル（ファンタジー、SF、現代ミステリ等）によってパラメータ構造が根本的に異なるため。

`win_conditions` / `fail_conditions` もJSONBで、エンディング判定に使用する。条件の複雑さ（「3つの証拠のうち2つ以上を集める」等）をスキーマで縛らず柔軟に表現する。

### 2.3 sessions — ゲームプレイスルー

**役割：** 1回のゲームプレイ全体を管理する中心テーブル。

ほぼ全てのゲームデータがこのテーブルにぶら下がる（`session_id` FK）。セッション削除時にCASCADEで関連データが全て消える設計。

`current_state` JSONBは**最新のゲーム全体状態**を持つ。AI GMが毎ターン参照するコンテキストのベースになる。各子テーブル（player_characters, npcs等）のデータを正規化して保持しつつ、`current_state` にはAI GMが効率的に読めるフラット化された状態を入れる二重管理の構造。これは：
- AI GMへの入力を最小化するパフォーマンス上の理由
- ゲーム状態のスナップショットとしての役割

`status` は `active` / `completed` / `abandoned` の3状態。`ending_summary` と `ending_type` は完了時のみ使用。

### 2.4 player_characters — プレイヤーキャラクター

**役割：** 1セッションに1体のPCデータ。

`session_id` にユニーク制約を付けて1:1を保証。シングルプレイヤー前提なので複数PCは想定しない。

`stats` JSONBは `{hp, maxHp, mp, maxMp, str, dex, int, cha}` のような構造だが、シナリオのジャンルによって項目が変わる（クトゥルフならSAN値、SFならシールド値等）ためJSONB。

`location_x` / `location_y` はFlame盤面上の座標。整数カラムにした理由は、Flame側で高頻度に参照・更新するため、JSONB内に埋めるよりクエリ効率が良い。

`image_path` はPCの立ち絵/アイコン画像のStorage上のパス。Supabase StorageのPublic URLで直接アクセスする。

### 2.5 npcs — NPCインスタンス

**役割：** セッション内に存在するNPCの実体。

シナリオの `initial_state.npcs` から展開され、セッション中に状態が変化する。同じシナリオから始めても、セッションごとに別のNPCインスタンスが生まれる。

`profile` JSONB（口調、価値観、禁則等）はセッション中に変化しない静的データ。AI GMプロンプトに注入してNPCの一貫性を保つ。

`goals` JSONB（短期/中期/長期目的）はAI GMがNPCの行動提案を生成する際の根拠。設計ドキュメント（Section 7.3）の「NPCの行動は提案、決定はGM」の仕組みを支える。

`state` JSONB（HP、気分、フラグ等）はセッション中に変化する動的データ。ゲームジャンルにより構造が異なるためJSONB。

`is_active` は退場・死亡のフラグ。`false` になったNPCはAI GMのコンテキストから除外されるが、データは残す（ログ参照、復活の可能性）。

### 2.6 npc_relationships — NPC→PC関係値

**役割：** NPCからPCに対する関係パラメータ。

設計ドキュメント（Section 7.2）で定義された5軸：
- `affinity`（好感度 -100〜100）
- `trust`（信頼 0〜100）
- `fear`（恐怖 0〜100）
- `debt`（恩義/貸し借り）
- `flags` JSONB（離散フラグ：`knows_secret`, `romance_locked` 等）

これを専用テーブルにした理由：
1. 個々の値をAI GMが頻繁に読み書きする
2. 関係値一覧UIで表示する
3. 数値の範囲チェックやバリデーションをアプリ層で行いやすい

`npc_id` にユニーク制約を付けて1NPC:1レコード。シングルプレイヤーなので「誰に対する関係値か」は自明（PCは1人）。

### 2.7 turns — ターンログ

**役割：** ゲームの全入出力履歴を時系列で記録。

TRPGのコアループ「入力 → GM判断 → 出力」の各ターンを1レコードとして記録する。

`input_type` はプレイヤーの入力種別（do / say / choice / roll_result / clarify_answer / system）。`gm_decision_type` はAI GMの判断種別（narrate / choice / roll / clarify / repair）。これらのenum値が設計ドキュメント（Section 3.1, 6.2）のゲームループと直接対応する。

`output` JSONBはGenUI用の構造化出力。narrationBlock、choiceGroup、rollPanel等のUIコンポーネント定義を含む（設計ドキュメント Section 4.3のUI語彙に対応）。JSONBにした理由は、GM判断タイプごとに出力構造が根本的に異なるため。

`(session_id, turn_number)` のユニーク制約でターンの順序を保証。

**MVP簡素化：** Undo/Retry/Edit機能はMVPスコープ外としたため、`status`（active/undone/retried）、`state_snapshot_id`、`retried_from_id` は削除済み。ターンは追記のみで巻き戻しはできない。

### 2.8 context_summaries — AI GMコンテキスト管理

**役割：** AI GMの長期記憶を構造化して管理。

設計ドキュメント（Section 10）の「3層コンテキスト」をDBで実現する。

- `plot_essentials` JSONB（Layer 1）：目的・危機・重要NPC・未解決事項。常時AI GMプロンプトに注入。
- `short_term_summary`（Layer 2）：直近数ターンの要約テキスト。2〜3ターンごとに更新。
- `confirmed_facts` JSONB（Layer 3）：重要イベント発生時に追加される確定事実のリスト。

`session_id` ユニーク制約で1セッション1コンテキスト。`last_updated_turn` で更新タイミングを管理し、必要なときだけ要約を再生成する。

このテーブルの存在意義は**LLMのコンテキストウィンドウ制限への対策**。全ターンログをそのままプロンプトに入れるとトークン数が爆発するため、構造化された要約を維持する。

### 2.9 objectives — クエスト/目標追跡

**役割：** プレイヤーが追跡すべきクエストや目標を明示的に管理。

設計ドキュメントでは「目的・手がかり・未解決を短く提示（迷子防止）」（Section 2.1）、「勝利条件／敗北条件」（Section 13.3）が言及されている。これを実現するためのテーブル。

`status` enum（active / completed / failed）で進捗を3状態管理。`sort_order` で表示順を制御。

`context_summaries.plot_essentials` にもクエスト情報は含まれるが、こちらはAI GMの内部参照用。`objectives` テーブルはプレイヤーUIに直接表示するためのデータソース。この分離により：
- UIの表示制御（フィルタ・ソート）が容易
- AI GMの要約更新とプレイヤー向け表示を独立に管理できる

### 2.10 items — アイテム管理

**役割：** セッション内のアイテムを個別管理。

当初はPCの `inventory` JSONBで管理する設計だったが、以下の理由で専用テーブルに変更：
- アイテムごとに画像（`image_path`）を持たせる必要がある
- 装備状態（`is_equipped`）の個別トグル操作
- アイテム一覧UIでのフィルタ・ソート
- 数量管理（`quantity`）の個別更新

`session_id` で暗黙的にPC所有。シングルプレイヤーなのでアイテムの所有者は常にそのセッションのPC。

### 2.11 scene_backgrounds — ロケーション背景画像

**役割：** Flame盤面の背景画像を管理。

TRPGのシーン演出に不可欠な背景画像を管理する。2種類の用途がある：

1. **シナリオ定義の背景**（`scenario_id` が NOT NULL）：シナリオ作成時に用意する定番ロケーション
2. **セッション中の動的生成**（`session_id` が NOT NULL）：AI GMがセッション中に新しい場所を生成した場合

`scenario_id` と `session_id` は両方NULLableだが、CHECK制約（`at_least_one_parent`）で少なくとも一方が必須。両方指定されるケース（シナリオ定義の背景をセッションで使用中）も許容する。

RLSポリシーはこの2パターンを反映：シナリオの背景は公開シナリオなら誰でも閲覧可、セッションの背景はセッション所有者のみ。

---

## 3. ストレージ設計

### 3.1 バケット構成

| バケット | 公開 | 用途 |
|---------|------|------|
| `scenario-assets` | Public | シナリオの背景画像、NPC肖像等 |
| `session-exports` | Public | セッションのJSONバックアップ |
| `user-avatars` | Public | ユーザーアバター画像 |

全バケットをPublic（`getPublicUrl` でアクセス可能）にしている理由：
- MVPではアクセス制御の複雑さを避ける
- 画像URLをそのまま `<img>` タグやFlameスプライトに渡せる
- Signed URLの有効期限管理が不要

### 3.2 パス設計（RESTful）

```
scenario-assets/
├── scenarios/{scenario_id}/background.webp
├── scenarios/{scenario_id}/npcs/{npc_name}.webp
└── scenarios/{scenario_id}/items/{item_id}.webp

session-exports/
└── users/{user_id}/sessions/{session_id}/export.json

user-avatars/
└── users/{user_id}/avatar.webp
```

### 3.3 DBとストレージの連携

DBの各テーブルには `*_path` カラム（`avatar_path`, `image_path`, `thumbnail_path`）でストレージ上のパスを保持する。パスからURLへの変換はフロントエンド側で `getPublicUrl()` を使う。

フルURLではなくパスを保存する理由：
- Supabaseプロジェクトの移行時にURLが変わっても、パスは不変
- 開発環境（localhost）と本番環境でURLのドメインが異なる

---

## 4. Auth Hook連携

### 4.1 仕組み

`auth.users` にレコードが挿入されると、PostgreSQLトリガー（`auth_hook`）が `handle_new_user()` 関数を実行し、`public.users` に対応レコードを自動作成する。

```
Supabase Auth サインアップ
  → auth.users に INSERT
  → トリガー: handle_new_user()
  → public.users に INSERT (id, account_name)
```

`handle_new_user()` は `SECURITY DEFINER` で実行されるため、RLSポリシーの `supabase_auth_admin` INSERT権限で動作する。

### 4.2 updated_at 自動更新

`updated_at` カラムを持つ全テーブルに `update_updated_at_column()` トリガーを設定。`UPDATE` 時に自動で現在時刻が設定される。アプリケーション側で明示的に `updated_at` を指定する必要がない。

対象テーブル（7つ）：users, scenarios, sessions, player_characters, npcs, npc_relationships, context_summaries, objectives, items

---

## 5. MVPで意図的に除外した設計

### 5.1 Undo/Retry/Edit

設計ドキュメントでは「安全弁」として定義されているが、MVPでは工数対効果の観点から除外。

除外したもの：
- `state_snapshots` テーブル（ターンごとのフルスナップショット）
- `turns.status`（active/undone/retried）
- `turns.state_snapshot_id`（スナップショットへの参照）
- `turns.retried_from_id`（リトライ元ターンへの参照）
- `turn_status` enum

将来実装する場合は、スナップショットテーブルとターンの状態管理を追加する。

### 5.2 マルチプレイヤー

- `npc_relationships` は1NPC:1レコード（PC IDカラムなし）
- `items` はセッション所有（PC IDカラムなし）
- RLSは全て `sessions.user_id` ベース

マルチプレイヤー対応には、PC IDの追加とRLSポリシーの全面改修が必要。

### 5.3 画像生成

`image_path` / `thumbnail_path` カラムは用意しているが、MVPでは手動アップロードまたはプリセット画像のみ。AI画像生成の統合は後回し。

---

## 6. ER図

```
users (1) ──< sessions (N)
                       │
scenarios (1) ──────< sessions (N)
                       │
                       ├──── player_characters (1:1)
                       │
                       ├──< npcs (N)
                       │       │
                       │       └──── npc_relationships (1:1)
                       │
                       ├──< turns (N)
                       │
                       ├──< objectives (N)
                       │
                       ├──< items (N)
                       │
                       └──── context_summaries (1:1)

scenarios (1) ──< scene_backgrounds (N)
sessions  (1) ──< scene_backgrounds (N)
```

**カーディナリティの注目点：**
- `player_characters` はセッションと1:1（ユニーク制約）
- `context_summaries` はセッションと1:1（ユニーク制約）
- `npc_relationships` はNPCと1:1（ユニーク制約、シングルプレイヤー前提）
- `scene_backgrounds` は `scenario_id` と `session_id` の両方にFKを持つ（CHECK制約で少なくとも一方が必須）

---

## 7. sqlacodegen 互換性

Python Backend（FastAPI）では `sqlacodegen` でSQLModelを自動生成する。以下の制約を考慮：

- 同一テーブルへの複数FK参照は `AmbiguousForeignKeysError` を引き起こす
- `turns.retried_from_id`（削除済み）はFK制約を付けない設計だった（自己参照の回避）
- `scene_backgrounds` の `scenario_id` / `session_id` は別テーブルへの参照なので問題なし
