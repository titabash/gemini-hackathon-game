# Contributing to flutter-boilerplate

flutter-boilerplateへのコントリビューションに興味を持っていただきありがとうございます！

## 開発環境のセットアップ

### 必要な環境

- [Flutter](https://flutter.dev/) 3.35.6 以上
- [Docker](https://www.docker.com/)
- [asdf](https://asdf-vm.com/)（推奨）
- [Supabase CLI](https://supabase.com/)
- [Melos](https://melos.invertase.dev/)
- Make

### セットアップ手順

1. リポジトリをクローン
   ```bash
   git clone https://github.com/[your-org]/flutter-boilerplate.git
   cd flutter-boilerplate
   ```

2. 初期セットアップを実行
   ```bash
   make init
   ```

3. 環境変数を設定
   ```bash
   # env/secrets.env を編集して必要な環境変数を設定
   vi env/secrets.env
   ```

4. Monorepoのセットアップ（Melos）
   ```bash
   # パッケージのリンクとbootstrap
   make frontend-bootstrap
   # または
   cd frontend && melos bootstrap
   ```

5. バックエンドとフロントエンドを起動
   ```bash
   # ターミナル1: バックエンド
   make run

   # ターミナル2: フロントエンド
   make frontend
   ```

## コードスタイル

### Frontend Flutter

- **Linter**: Dart analyzer
- **Formatter**: dart format
- **Architecture**: Feature-Sliced Design (FSD)
- **Style**: 2-space indentation, trailing commas

```bash
# Lint & Format
make check-flutter        # analyze + format check + test
make fix-format-flutter   # auto-format
```

### Backend Python

- **Linter**: Ruff（line length: 88）
- **Type Checker**: MyPy（strict mode）
- **Architecture**: Clean Architecture

```bash
# Lint & Format
make check-backend        # ruff check + mypy
make fix-format-backend   # ruff format
```

### Edge Functions (Deno)

- **Runtime**: Deno
- **Linter/Formatter**: Deno native tools

```bash
# Lint & Format
make check-edge-functions   # deno lint + check
make fix-format-edge-functions  # deno fmt
```

### Drizzle (Database)

- **Linter/Formatter**: Biome
- **Style**: 2-space indentation, single quotes

```bash
# Drizzle は make check-quality に含まれる
```

### 統合コマンド

全プロジェクトを一括でチェック:

```bash
make check-quality     # 全体の品質チェック
make fix-format        # 全体のformat
```

## テスト

### Frontend (Monorepo)

```bash
# Makeコマンド（推奨）
make frontend-test       # 全パッケージのテスト

# Melosコマンド
cd frontend
melos run test           # 全パッケージのテスト
melos run test_coverage  # カバレッジ付き

# 特定のパッケージのみ
melos run test --scope=web              # webアプリのみ
melos run test --scope=core_api         # core/apiパッケージのみ
```

### Backend

```bash
cd backend-py/app
uv run pytest
uv run pytest --cov
```

## コード生成

Flutter では、Riverpod、i18n、Drift のコード生成が必要です：

```bash
# Makeコマンド（推奨）
make frontend-generate   # すべてのパッケージのコード生成

# Melosコマンド
cd frontend
melos run generate       # すべてのパッケージのコード生成
melos run generate:watch # ウォッチモード（開発時推奨）

# 個別パッケージ
cd frontend/apps/web
flutter pub run build_runner build --delete-conflicting-outputs
flutter pub run build_runner watch  # ウォッチモード
```

### コード生成が必要な場合

以下の場合はコード生成を実行してください：

- Riverpodプロバイダーを追加・変更した時（`@riverpod`アノテーション）
- 翻訳ファイル（`.i18n.json`）を更新した時
- Driftデータベーススキーマを変更した時
- RetrofitのAPIエンドポイントを追加・変更した時

## データベースマイグレーション

スキーマ変更時は、Drizzleマイグレーションを生成・適用：

```bash
# drizzle/schema/ を編集後
make migrate-dev    # マイグレーション生成 + 適用 + 型生成
```

## コミット前の確認

プルリクエストを作成する前に、必ず以下を実行してください:

```bash
make check-quality
```

このコマンドは以下を実行します:
- Lint（全プロジェクト）
- Format check（全プロジェクト）
- Analyze（Flutter）
- Type check（Python）

## プルリクエストの作成

1. feature branchを作成
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. 変更をコミット
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

3. `make check-quality`を実行してすべてのチェックをパス

4. テストを実行して全てパスすることを確認
   ```bash
   make test-all
   ```

5. プッシュしてプルリクエストを作成
   ```bash
   git push origin feature/your-feature-name
   ```

6. GitHub上でプルリクエストを作成し、詳細な説明を記載

## コミットメッセージのガイドライン

Conventional Commits形式を推奨します:

- `feat:` 新機能追加
- `fix:` バグ修正
- `docs:` ドキュメント変更
- `style:` コードスタイルの変更（機能に影響なし）
- `refactor:` リファクタリング
- `test:` テストの追加・修正
- `chore:` ビルドプロセスやツールの変更

例:
```
feat: add user authentication with Supabase Auth
fix: resolve state management issue in counter feature
docs: update setup instructions in README
```

## Test-Driven Development (TDD)

このプロジェクトはTDDを推奨しています：

1. **テストを先に書く**: 期待される動作を定義
2. **テストが失敗することを確認**: Red
3. **実装する**: Green
4. **リファクタリング**: Refactor
5. **すべてのテストが通るまで繰り返す**

## アーキテクチャガイドライン

### Frontend (Flutter - Monorepo)

#### Monorepo構造

- **Melos**でモノレポ管理
- **apps/web/**: メインWebアプリケーション（FSD構造）
- **packages/core/**: コア機能パッケージ
  - `api/`: Dio + Retrofitによる型安全なAPIクライアント
  - `auth/`: 認証状態管理とユーティリティ
  - `i18n/`: slangによる型安全な国際化
  - `utils/`: 共通ユーティリティとロガー
- **packages/shared/ui/**: 再利用可能UIコンポーネント

#### Feature-Sliced Design (FSD)

- **apps/web/**はFSDアーキテクチャに準拠
- 各featureは`api/`, `model/`, `ui/`のセグメントを持つ
- 下位レイヤーのみインポート可能: `app` → `pages` → `features` → `entities` → `shared`

#### 状態管理とナビゲーション

- **Riverpod + Flutter Hooks**で状態管理
- **GoRouter**で宣言的ルーティング（認証ガード実装済み）
- **slang**で型安全な国際化

### Backend (Python)

- **Clean Architecture**に準拠
- Controller → UseCase → Gateway → Domain の階層
- すべての関数に型アノテーション必須
- Google-styleのdocstring
- McCabe complexity ≤ 3

### Edge Functions (Deno)

- Deno.serve native API
- `npm:` prefixでnpmパッケージをインポート
- 型安全性を維持

### Database (Drizzle)

- TypeScriptでスキーマ定義
- RLSポリシーは`pgPolicy`で宣言的に管理
- マイグレーションファイルは`supabase/migrations/`に生成

## 質問や問題がある場合

- GitHub Issuesで質問を作成してください
- 既存のIssuesを確認して、同じ質問がないか確認してください
- [CLAUDE.md](./CLAUDE.md)や[AGENTS.md](./AGENTS.md)も参照してください

## ライセンス

このプロジェクトにコントリビュートすることで、あなたの貢献がMITライセンスの下でライセンスされることに同意したものとみなされます。
