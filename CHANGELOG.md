# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- 初期ボイラープレートセットアップ
- Flutter 3.35.6 マルチプラットフォームフロントエンド
- Melos モノレポ構成（apps/web/ + packages/）
  - apps/web/ - メイン Web アプリケーション（FSD 構造）
  - packages/core/api - Dio + Retrofit による型安全な API 統合
  - packages/core/auth - 認証状態管理とユーティリティ
  - packages/core/i18n - slang による型安全な国際化
  - packages/core/utils - 共通ユーティリティとロガー
  - packages/shared/ui - 再利用可能な UI コンポーネント
- GoRouter 実装（認証対応の宣言的ルーティング）
- Drizzle ORM によるデータベーススキーマ管理（Prisma/Atlas から移行）
- Supabase 統合（認証、データベース、Edge Functions）
- FastAPI Python バックエンド（Clean Architecture）
- Feature-Sliced Design (FSD) アーキテクチャ
- Riverpod + Flutter Hooks による状態管理（コード生成対応）
- slang による型安全な国際化（i18n）
- Drift ローカルデータベース（型安全なクエリ）
- Dart analyzer + dart format によるコード品質管理
- Ruff + MyPy による Python コード品質管理
- Deno Edge Functions サポート
- AI/ML 統合（LangChain, OpenAI, Anthropic, Perplexity, PyTorch 等）
- Docker Compose による開発環境
- 統一的な Makefile コマンド
- 日本語ドキュメント（README.md, CLAUDE.md, AGENTS.md）
- 標準ファイル（LICENSE, CONTRIBUTING.md, SECURITY.md, CHANGELOG.md）
- Flutter test フレームワーク（Frontend）
- pytest テストフレームワーク（Backend）
- GitHub Actions CI/CD ワークフロー
- Dependabot による依存関係自動更新
- VSCode 推奨設定・拡張機能

### Changed

- Prisma ORM から Atlas へ移行（後に Drizzle へ再移行）
- Atlas から Drizzle ORM へ移行（TypeScript ベースのスキーマ管理）
- レガシーフロントエンドファイルの削除（モノレポ移行に伴う）

### Removed

- Prisma 関連ファイル（完全削除）
- Atlas 関連ファイル（完全削除）
- レガシーな.env ファイル（dotenvx 移行に伴う）

### Fixed

### Security

## [0.1.0] - 2025-01-04

### Added

- 初回リリース
- 基本的なボイラープレート構成

[Unreleased]: https://github.com/[your-org]/flutter-boilerplate/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/[your-org]/flutter-boilerplate/releases/tag/v0.1.0
