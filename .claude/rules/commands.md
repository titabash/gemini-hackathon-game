# Makefile Commands Policy

**MANDATORY**: ビルド・テスト・リント等の操作は必ず Makefile のコマンドを使用すること。

## 基本原則

直接 CLI コマンド（`flutter`, `dart`, `melos` 等）を実行せず、**必ず `make` コマンドを使用**する。

## 理由

1. **一貫性**: 全開発者が同じコマンドを使用
2. **環境設定**: 環境変数やパスが自動で設定される
3. **依存関係**: 必要な前処理が自動実行される
4. **エラー防止**: 誤ったオプションの指定を防ぐ

## 主要コマンド

### 初期化・セットアップ

| 操作 | コマンド | 直接実行（禁止） |
|------|---------|----------------|
| プロジェクト初期化 | `make init` | ❌ |
| Melos Bootstrap | `make frontend-bootstrap` | ❌ `melos bootstrap` |
| 依存関係インストール | `make frontend-bootstrap` | ❌ `flutter pub get` |

### 開発サーバー

| 操作 | コマンド | 直接実行（禁止） |
|------|---------|----------------|
| Flutter Web | `make frontend` | ❌ `flutter run -d chrome` |
| Flutter iOS | `make frontend-ios` | ❌ `flutter run -d ios` |
| Flutter Android | `make frontend-android` | ❌ `flutter run -d android` |
| Backend | `make run` | ❌ `docker compose up` |

### コード生成

| 操作 | コマンド | 直接実行（禁止） |
|------|---------|----------------|
| Flutter コード生成 | `make frontend-generate` | ❌ `flutter pub run build_runner build` |
| DB マイグレーション生成 | `make migrate-dev` | ❌ `bun run drizzle-kit generate` |
| 型定義生成のみ | `make build-model` | ❌ `supabase gen types` |

### テスト

| 操作 | コマンド | 直接実行（禁止） |
|------|---------|----------------|
| Flutter テスト | `make frontend-test` | ❌ `flutter test` |
| 統合テスト | `make frontend-integration-test` | ❌ `flutter test integration_test/` |
| E2Eテスト（Patrol） | `make frontend-patrol` | ❌ `patrol test` |
| 全テスト | `make test-all` | ❌ |
| Backend テスト | `make test-backend-py` | ❌ `pytest` |

### コード品質

| 操作 | コマンド | 直接実行（禁止） |
|------|---------|----------------|
| 全Lint | `make check-quality` | ❌ |
| Flutter Lint | `make check-flutter` | ❌ `flutter analyze` |
| Backend Lint | `make check-backend` | ❌ `ruff check` |
| 全Format | `make fix-format` | ❌ |
| Flutter Format | `make fix-format-flutter` | ❌ `dart format .` |

### データベース

| 操作 | コマンド | 直接実行（禁止） | 承認 |
|------|---------|----------------|------|
| マイグレーション生成+適用 | `make migrate-dev` | ❌ | **必須** |
| マイグレーション適用 | `make migrate-deploy` | ❌ | **必須** |
| Drizzle Studio | `make drizzle-studio` | ❌ `bun run drizzle-kit studio` | 不要 |
| DBリセット | `make db-reset` | ❌ | **必須** |

**IMPORTANT**: データベース操作（`make migrate-*`, `make db-reset`）は必ずユーザー承認を得てから実行すること。

### Widgetbook & UI

| 操作 | コマンド | 直接実行（禁止） |
|------|---------|----------------|
| Widgetbook 起動 | `make frontend-widgetbook` | ❌ `flutter run -t widgetbook/main.dart` |

### その他

| 操作 | コマンド | 直接実行（禁止） |
|------|---------|----------------|
| 全サービス停止 | `make stop` | ❌ |
| クリーン | `make frontend-clean` | ❌ `melos clean` |

## 禁止パターン

```bash
# ❌ 直接 CLI コマンド実行
flutter test
dart format .
flutter pub get
melos run test
bun run drizzle-kit generate

# ✅ Makefile コマンド使用
make frontend-test
make fix-format-flutter
make frontend-bootstrap
make test-all
make migrate-dev
```

## 例外

以下の場合のみ直接 CLI コマンドを使用可能：

1. **探索的作業**: 新しいパッケージの試用、デバッグ作業
2. **Makefile に存在しないコマンド**: 特殊なオプションが必要な場合
3. **ドキュメント化後**: 使用後は Makefile に追加することを推奨

## Enforcement

この Makefile ポリシーは **NON-NEGOTIABLE**。直接 CLI コマンドを使用するコード例は却下される。
