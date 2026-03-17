# Codex CLI プロジェクト固有指示

このドキュメントは、Codex CLIがこのFlutter Boilerplateプロジェクトで作業する際の追加コンテキストと実践的なガイダンスを提供します。

## コード変更時の必須チェックリスト

### Flutter/Dart変更時

```bash
# 1. コード生成（Riverpod、i18n、Drift）
cd frontend && flutter pub run build_runner build --delete-conflicting-outputs

# または
make frontend-generate

# 2. フォーマット自動修正
make fix-format-flutter

# 3. 品質チェック
make check-flutter
```

### Edge Functions変更時

```bash
# 1. フォーマット自動修正
make fix-format-edge-functions

# 2. 品質チェック
make check-edge-functions
```

### Python Backend変更時

```bash
# 1. フォーマット自動修正
make fix-format-backend

# 2. 品質チェック
make check-backend
```

### データベーススキーマ変更時

```bash
# 1. Supabase MCPで現在のスキーマ確認
# （Codex内で実行）

# 2. drizzle/schema/*.ts を編集

# 3. マイグレーション生成と適用
make migrate-dev

# 4. Supabase MCPで変更を検証
# （Codex内で実行）

# 5. 型生成確認
make build-model
```

### 複数コンポーネント変更時

```bash
# 全コンポーネントのフォーマットと品質チェック
make frontend-generate
make fix-format
make check-quality
```

## よく使うコマンドパターン

### 初回セットアップ

```bash
# プロジェクト全体の初期化
make init

# フロントエンド開発サーバー起動
make frontend
```

### 日常開発フロー

```bash
# 1. バックエンド + Supabase起動
make run

# 2. 別ターミナルでフロントエンド起動
make frontend

# 3. コード変更後の品質チェック
make check-quality

# 4. テスト実行
make test-all
```

### 新機能開発時のMCPツール活用

```bash
# 1. Context7で技術調査
# プロンプト例: "Riverpodで無限スクロールを実装するベストプラクティスを教えてください"

# 2. Supabase MCPでDB確認
# プロンプト例: "postsテーブルの構造とインデックスを確認してください"

# 3. Dart MCPでパターン確認（利用可能な場合）
# プロンプト例: "GoRouterでの認証ガード実装パターンを教えてください"

# 4. 実装

# 5. IDE MCPで診断確認
# プロンプト例: "現在のエラーと警告を確認してください"
```

### Melos操作

```bash
# パッケージ依存関係の再解決
make frontend-bootstrap

# 全パッケージのクリーン
make frontend-clean

# 特定パッケージでのコマンド実行
cd frontend
melos exec --scope=core_auth -- flutter pub get
melos exec --scope=core_i18n -- flutter pub run build_runner build
```

## トラブルシューティング

### Riverpod生成エラー

**症状**: `flutter pub run build_runner build`が失敗

**原因と対処**:

```bash
# 1. キャッシュクリーン
cd frontend/apps/web
flutter clean
flutter pub get

# 2. 競合削除オプション付きで再生成
flutter pub run build_runner build --delete-conflicting-outputs

# 3. それでもエラーの場合、生成ファイルを手動削除
find . -name "*.g.dart" -delete
find . -name "*.freezed.dart" -delete
flutter pub run build_runner build
```

### Melos bootstrap失敗

**症状**: `melos bootstrap`がエラーになる

**原因と対処**:

```bash
# 1. Melosキャッシュクリーン
cd frontend
melos clean

# 2. Dart pubキャッシュ修復
dart pub cache repair

# 3. 再bootstrap
melos bootstrap
```

### Supabase接続エラー

**症状**: フロントエンドからSupabaseに接続できない

**原因と対処**:

```bash
# 1. Supabaseが起動しているか確認
docker ps | grep supabase

# 2. Supabase起動
make run

# 3. 環境変数確認
cat env/secrets.env | grep SUPABASE

# 4. Supabase設定リセット（開発環境のみ）
make stop
make db-reset
make init
```

### マイグレーションエラー

**症状**: `make migrate-dev`が失敗

**原因と対処**:

```bash
# 1. マイグレーション履歴確認
make migrate-status

# 2. Drizzle Studio でDB状態確認
make drizzle-studio
# ブラウザで http://localhost:4983 にアクセス

# 3. 開発環境でDBリセット（注意: データ消失）
make db-reset
make migrate-dev

# 4. スキーマファイル構文チェック
cd drizzle
npx tsc --noEmit
```

### コード生成が遅い

**症状**: `build_runner`の実行に時間がかかる

**対処**:

```bash
# 1. ウォッチモード使用（開発中）
cd frontend/apps/web
flutter pub run build_runner watch

# 2. 生成ファイルをGitにコミット
# （CI/CD高速化のため）

# 3. キャッシュディレクトリ除外設定確認
# .gitignoreに以下が含まれていることを確認:
# *.g.dart（ただしコミットする場合は削除）
# .dart_tool/
# build/
```

### ポート競合エラー

**症状**: `make frontend`で「ポート8080が使用中」エラー

**対処**:

```bash
# 1. ポート使用プロセス確認
lsof -i :8080

# 2. プロセス終了
kill -9 <PID>

# 3. または別ポート指定
cd frontend/apps/web
flutter run -d chrome --web-port 8081
```

## プロンプト例集

### 新機能実装

```
Feature Sliced Designに従って、ユーザープロフィール編集機能を実装してください。

要件:
- features/profile/に配置
- api、model、uiセグメントで構成
- Riverpodで状態管理
- Supabaseでプロフィール更新
- バリデーションとエラーハンドリング
- i18n対応（日英）

実装前に以下を確認してください:
1. Context7でRiverpodのフォームハンドリングベストプラクティス
2. Supabase MCPでuser_profilesテーブル構造確認
3. Dart MCPでフォームバリデーションパターン確認
```

### コードレビュー

```
このPRのコードレビューをしてください。

チェック項目:
- Feature Sliced Design準拠
- Riverpodの適切な使用
- エラーハンドリング
- テストカバレッジ
- パフォーマンス考慮事項
- セキュリティ脆弱性
- i18n対応

レビュー後、以下を実行してください:
make check-quality
```

### リファクタリング

```
counter機能をリファクタリングして、より保守性の高いコードにしてください。

要件:
- 既存のテストは全て通過すること
- Feature Sliced Designの原則に従う
- 不要な依存関係を削減
- パフォーマンスを維持または改善

実装前に以下を確認してください:
1. Context7でFlutterリファクタリングベストプラクティス
2. 既存のテストコード分析
```

### データベーススキーマ変更

```
user_profilesテーブルにavatar_urlカラムを追加してください。

要件:
- nullable
- URL検証
- RLSポリシー更新
- 既存データへの影響確認

実装前に以下を実行してください:
1. Supabase MCPで現在のuser_profilesテーブル構造確認
2. Context7でPostgreSQLのURL型とバリデーション調査
3. RLSポリシーへの影響確認

実装後:
make migrate-dev
make build-model
```

### テスト追加

```
counter機能のユニットテストとウィジェットテストを追加してください。

要件:
- TDDアプローチ
- カバレッジ90%以上
- エッジケースのテスト
- Riverpodプロバイダーのモック
- ウィジェットテストでのインタラクション確認

実装後:
make frontend-test
```

## ベストプラクティス

### 1. 常にMCPツールを活用

- **実装前**: Context7、Supabase MCP、Dart MCPで調査
- **実装中**: IDE MCPで診断確認
- **実装後**: 品質チェックツールで検証

### 2. コミット前の必須確認

```bash
# 全ての品質チェックをパス
make check-quality

# テストカバレッジ確認
make test-all

# Gitステータス確認
git status
```

### 3. Feature Sliced Design厳守

- レイヤー: `app/` → `pages/` → `features/` → `entities/` → `shared/`
- セグメント: `api/`, `model/`, `ui/`
- 同一レイヤー間の依存は禁止
- 上位レイヤーから下位レイヤーへの依存のみ許可

### 4. 環境変数管理

- 秘密情報は`env/secrets.env`に配置
- `.gitignore`に含める
- チーム共有は安全な方法で（1Password、AWS Secrets Manager等）

### 5. データベース変更の慎重な実施

- 必ずSupabase MCPで現状確認
- マイグレーションには必ずロールバック計画
- 本番適用前にステージング環境で検証
- RLSポリシーへの影響を必ず確認

### 6. TDD原則

- テストファースト
- Red-Green-Refactorサイクル
- カバレッジ90%以上を目標
- エッジケースも忘れずにテスト

## セキュリティチェックリスト

- [ ] API keyやsecretsをハードコードしていない
- [ ] 環境変数から機密情報を取得している
- [ ] RLSポリシーが適切に設定されている
- [ ] 入力バリデーションが実装されている
- [ ] SQLインジェクション対策済み
- [ ] XSS対策済み（Web）
- [ ] 認証トークンが安全に保存されている
- [ ] CORS設定が適切（Edge Functions）

## パフォーマンスチェックリスト

- [ ] 不要なリビルドを防ぐRiverpod設計
- [ ] 大きなリストには仮想スクロール実装
- [ ] 画像は適切なサイズで読み込み
- [ ] 非同期処理でUIをブロックしない
- [ ] データベースクエリは最適化済み
- [ ] インデックスが適切に設定されている
- [ ] N+1問題が発生していない

## CRITICAL: Google ADK GM Agent パターン

GMエージェントは LangChain ではなく **Google ADK** を使用（`backend-py/app/src/infra/adk_gm_client.py`）。

### 選択肢アクセス（ADK 導入後の重要な変更）

```python
# ✅ ADK 後の正しい方法
choice_node = next(
    (n for n in reversed(decision.nodes) if n.type == "choice" and n.choices),
    None,
)

# ❌ 禁止: ADK 導入後は decision.choices は存在しない
choices = decision.choices  # AttributeError になる
```

`decision_type="choice"` の場合、選択肢は `decision.nodes` の中の `type="choice"` ノードの `.choices` に格納される。

### ADK セットアップ必須事項

```python
agent = LlmAgent(
    name="gm_agent",
    model=Gemini(model="gemini-3-flash-preview"),
    instruction=GM_SYSTEM_PROMPT,
    output_schema=GmDecisionResponse,  # Pydantic 直接指定
    # use_interactions_api=True は絶対に指定しない（構造化出力が壊れる）
)
```

ADK セッションテーブルは `adk` PostgreSQL スキーマに隔離する：
```python
connect_args={"server_settings": {"search_path": "adk"}}
```

## CRITICAL: TrpgSession Surface 優先順位

`frontend/apps/web/lib/features/trpg/model/trpg_session_provider.dart`

### resolvePostPagingMode ルール（絶対厳守）

```dart
// hasSurface=true は isProcessing=true より必ず優先される
static NovelDisplayMode resolvePostPagingMode({
  required bool isProcessing,
  required bool hasSurface,
}) {
  if (hasSurface) return NovelDisplayMode.surface;  // ← 最優先
  if (isProcessing) return NovelDisplayMode.processing;
  return NovelDisplayMode.input;
}
```

これが逆順（isProcessing 先）だと auto-advance シナリオで choice UI が永遠に表示されないバグが発生する。

## CRITICAL: genui game-surface パターン

```
# SSE イベント順序（1ターン分）
nodesReady → stateUpdate → game-npcs (A2UI) → game-narration (A2UI) → game-surface (A2UI) → done
```

`surfaceUpdate` + `beginRendering` は**必ずセット**で送る（片方だけでは surface が表示されない）。

## 参考リソース

- プロジェクトCLAUDE.md: `/Users/tknr/Development/flutter-boilerplate/CLAUDE.md`
- Makefile: `/Users/tknr/Development/flutter-boilerplate/Makefile`
- Melos設定: `/Users/tknr/Development/flutter-boilerplate/melos.yaml`
- Drizzle設定: `/Users/tknr/Development/flutter-boilerplate/drizzle/config/`
