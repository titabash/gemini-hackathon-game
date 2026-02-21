# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**CRITICAL - 推測実装の完全禁止**:

- **推測・記憶・一般知識に基づく実装は一切禁止**
- 実装前に必ず **Context7 MCP**、**Dart MCP**、**Supabase MCP** で公式ドキュメントを確認すること
- ライブラリの API、設定ファイル形式、CLI 構文は**必ずファクトを調査**してから使用
- 「たぶんこうだろう」「以前こうだった」という推測での実装は**絶対に行わない**
- **モジュール・パッケージは必ず最新バージョンを調査し、最新のAPIを使用すること**
- **ビルド・テスト・リント等は必ず Makefile のコマンドを使用すること**（詳細は `.claude/rules/commands.md`）
- 詳細は `.claude/rules/research.md` を参照

## Memory Structure

このプロジェクトは `.claude/` ディレクトリでメモリを構造化しています：

```
.claude/
├── CLAUDE.md       # このファイル（概要・クイックリファレンス）
├── settings.json   # Claude Code設定
├── rules/          # 常に適用されるポリシー・制約
│   ├── tdd.md            # テスト駆動開発（TDD）必須
│   ├── research.md       # Research-First ポリシー
│   ├── supabase-first.md # Supabase優先アーキテクチャ
│   ├── commands.md       # Makefile コマンド必須
│   ├── database.md       # マイグレーション承認必須
│   ├── auto-generated.md # 自動生成ファイル編集禁止
│   ├── clean-code.md     # クリーンコード（後方互換禁止・重複禁止）
│   ├── frontend.md       # Flutter/Riverpod/FSD規約
│   ├── backend-py.md     # Python コード規約
│   ├── edge-functions.md # Edge Functions 規約
│   ├── i18n.md           # 多言語対応（slang必須）
│   ├── datetime.md       # 日時処理（UTC保存）
│   ├── ui-testing.md     # UIテスト（Widgetbook + Widget Tests）
│   └── logging.md        # ロギング（logger パッケージ）
│
├── agents/         # サブエージェント定義
│   ├── task-planner.md   # タスク分解専門家
│   ├── task-executor.md  # タスク実行専門家
│   ├── spec.md           # 技術調査専門家
│   └── quality-checker.md # 品質チェック専門家
│
└── skills/         # 質問時に参照するガイダンス
    ├── fsd/              # Feature Sliced Design
    ├── flutter-widgets/  # Material Design 3, Adaptive
    ├── riverpod/         # State Management
    ├── gorouter/         # Navigation
    ├── freezed/          # Immutable Models
    ├── melos/            # Monorepo Management
    ├── supabase/         # Supabase Flutter
    ├── drizzle/          # Drizzle ORM (Edge Functions用)
    ├── i18n/             # slang 多言語対応
    ├── datetime/         # DateFormat
    ├── widgetbook/       # UIコンポーネントカタログ
    ├── patrol/           # E2Eテスト
    ├── polar/            # Polar.sh決済統合
    └── onesignal/        # OneSignal通知統合
```

## Domain Documentation

詳細なドメイン情報は各 README を参照：

| ドメイン          | ドキュメント                                               |
| ----------------- | ---------------------------------------------------------- |
| Frontend (Flutter)| [`frontend/README.md`](frontend/README.md)                 |
| Core Packages     | [`frontend/packages/core/*/README.md`](frontend/packages/) |
| Database Schema   | [`drizzle/README.md`](drizzle/README.md)                   |
| Backend Python    | [`backend-py/README.md`](backend-py/README.md)             |
| Edge Functions    | [`supabase/functions/README.md`](supabase/functions/README.md) |

---

## Architecture Overview

Full-stack application boilerplate with Flutter multi-platform frontend and backend services.

### Tech Stack

| Layer                  | Technology                                           |
| ---------------------- | ---------------------------------------------------- |
| **Frontend**           | Flutter 3.35.6, Dart 3.5, Melos                      |
| **UI**                 | Material Design 3, Adaptive Widgets                  |
| **State Management**   | Riverpod (riverpod_generator), Flutter Hooks         |
| **Navigation**         | GoRouter (authentication-aware routing)              |
| **Architecture**       | Feature Sliced Design (FSD)                          |
| **i18n**               | slang (type-safe, en/ja)                             |
| **HTTP Client**        | Dio + Retrofit (type-safe API)                       |
| **Data Models**        | Freezed (immutable, json_serializable)               |
| **Local DB**           | Drift (type-safe SQLite ORM)                         |
| **Code Generation**    | build_runner (Freezed, Riverpod, Drift, slang)       |
| **Backend**            | FastAPI (Python), Supabase Edge Functions (Deno)     |
| **Database**           | PostgreSQL, Drizzle ORM, pgvector                    |
| **Auth**               | Supabase Flutter Client                              |

**MANDATORY**: すべてのユーザー向けテキストは多言語対応（i18n）必須。詳細は `.claude/skills/i18n/` を参照。

**MANDATORY**: すべての実装はテスト駆動開発（TDD）を厳守。**作業終了時は必ず All Green（全テスト通過）を確認**。詳細は `.claude/rules/tdd.md` を参照。

**MANDATORY**: 単体テストでは**外部SDK（pipモジュール）を丸ごとMockしない**。本物のSDKを使い、I/O層（HTTP/DB）のみ差し替えることで、**TypeError・ValueError・RuntimeError を単体テスト時点で検知**し、型安全で堅牢な状態を維持する。詳細は `.claude/rules/backend-py.md` および `.claude/skills/python-testing/` を参照。

**MANDATORY**: コードは常にクリーンな状態を維持。後方互換コード・重複コード・未使用コードは残さない（明示的な指示がある場合を除く）。詳細は `.claude/rules/clean-code.md` を参照。

### Package Management

| Component                               | Package Manager      |
| --------------------------------------- | -------------------- |
| Frontend (`frontend/`)                  | **Melos** (monorepo) |
| Flutter Packages                        | **Flutter pub**      |
| Backend Python (`backend-py/`)          | **uv**               |
| Drizzle (`drizzle/`)                    | **Bun**              |
| Edge Functions (`supabase/functions/`)  | **Deno**             |

### Monorepo Structure (Melos)

```
frontend/
├── apps/
│   └── web/              # Main Flutter application
├── packages/
│   ├── core/
│   │   ├── api/          # HTTP client (Dio + Retrofit)
│   │   ├── auth/         # Authentication
│   │   ├── i18n/         # Internationalization (slang)
│   │   ├── polar/        # Polar.sh payment integration
│   │   ├── notification/ # OneSignal push notifications
│   │   └── utils/        # Utilities (Logger, constants)
│   └── shared/
│       └── ui/           # Shared UI components
└── melos.yaml            # Melos configuration
```

---

## Quick Reference

### Development Commands

```bash
# Setup
make init                        # Full project initialization

# Services
make run                         # Start backend (Supabase + Docker)
make frontend                    # Start Flutter web dev (includes bootstrap)
make frontend-ios                # Start iOS development
make frontend-android            # Start Android development
make stop                        # Stop all services

# Monorepo (Melos)
make frontend-bootstrap          # Setup workspace and link packages
make frontend-generate           # Run code generation (Riverpod, Freezed, Drift, i18n)
make frontend-clean              # Clean all packages
make frontend-test               # Run unit and widget tests
make frontend-integration-test   # Run integration tests (device required)
make frontend-test-all           # Run all tests (unit, widget, integration)

# Quality
make check-quality               # All quality checks
make fix-format                  # Auto-fix all code formatting
make test-all                    # Run all tests (Flutter + Edge Functions + Backend)

# Database (user approval required)
make migrate-dev                 # Generate + apply migration + types
make migrate-deploy              # Apply existing migrations (ENV=stg|prod)
make drizzle-studio              # Open Drizzle Studio (visual DB management)
```

**IMPORTANT**: Always use `make frontend` for development server startup instead of direct `flutter run` commands. The make command ensures proper Melos bootstrap and environment variable loading.

### Environment Configuration

```
env/
├── frontend/local.json           # Flutter environment (--dart-define-from-file)
├── backend/local.env             # Backend service
├── migration/local.env           # Database migration
├── secrets.env                   # Secrets (.gitignore)
└── secrets.env.example           # Template
```

### Code Generation Workflow

```bash
# After modifying Freezed models, Riverpod providers, or i18n translations
make frontend-generate

# Or run directly in specific package
cd frontend/apps/web && flutter pub run build_runner build --delete-conflicting-outputs
```

**Generated Files** (DO NOT EDIT):
- `*.g.dart` - Riverpod, json_serializable, build_runner
- `*.freezed.dart` - Freezed immutable models
- `*.gr.dart` - auto_route (if used)
- `*/generated/*` - All files in generated directories

---

## Supabase Configuration

| Setting                | Location                       |
| ---------------------- | ------------------------------ |
| Auth (OAuth, JWT, MFA) | `supabase/config.toml`         |
| Storage buckets        | `supabase/config.toml`         |
| API settings           | `supabase/config.toml`         |
| Tables                 | `drizzle/schema/`              |
| RLS policies           | `drizzle/schema/`              |
| Realtime               | `drizzle/config/functions.sql` |

---

## Flutter Specific Guidelines

### State Management (Riverpod)

- Use `riverpod_generator` for all providers
- Annotate with `@riverpod` or `@Riverpod(keepAlive: true)`
- Generate code after changes: `make frontend-generate`

### Data Models (Freezed)

- All domain models use Freezed for immutability
- Add `@freezed` annotation
- Include `@JsonSerializable()` for API/database integration
- Generate code after changes: `make frontend-generate`

### Navigation (GoRouter)

- Declarative routing with type-safe navigation
- Authentication guards and automatic redirects
- Deep linking support

### Internationalization (slang)

- JSON-based translations in `packages/core/i18n/lib/translations/`
- Type-safe access via generated `strings.g.dart`
- Import from `package:core_i18n/generated/strings.g.dart`
- Use `t.xxx` for accessing translations

### Logging

- Use `Logger` class from `package:core_utils/core_utils.dart`
- **Never use `print()` or `debugPrint()` directly**
- Log levels: `trace`, `debug`, `info`, `warning`, `error`, `fatal`
- Development: Colorful output with emoji indicators
- Production: Warning/Error/Fatal only (future: Sentry/Crashlytics)
- See `.claude/rules/logging.md` for details

```dart
import 'package:core_utils/core_utils.dart';

Logger.info('App started');
Logger.error('Failed to fetch data', error, stackTrace);
```

### Testing Strategy

**Test Types**:
1. **Unit Tests**: Test business logic and models
2. **Widget Tests**: Test Flutter widgets and UI
3. **Integration Tests**: Test complete user flows
   - Located in `integration_test/` directory
   - Device/simulator required (or ChromeDriver for Web)

**Supabase Mocking**:
- Use `mock_supabase_http_client` for CRUD operations
- Use Fake classes for Auth/Realtime/Storage

**UI Component Catalog**:
- Use Widgetbook (Storybook equivalent for Flutter)
- Run: `make frontend-widgetbook`

**E2E Testing**:
- Use Patrol (Maestro equivalent for Flutter)
- Run: `make frontend-patrol`

---

## AI/ML Features

- **Vector Search**: pgvector
- **LLM Orchestration**: LangChain/LangGraph
- **Providers**: OpenAI, Anthropic, Replicate, FAL
- **Real-time**: LiveKit

→ 詳細は [`backend-py/README.md`](backend-py/README.md)

---

## Payment & Notification Integration

### Polar.sh (Payment & Subscriptions)

- **Flutter Package**: `frontend/packages/core/polar/`
  - Riverpod providers for checkout and subscription management
  - HTTP client with Retrofit for API communication
  - Models with Freezed for type-safe data handling
- **Backend API**: `supabase/functions/polar-api/`
  - Edge Function proxy for Polar.sh SDK
  - Endpoints: checkouts, subscriptions, orders, products, customer portal
- **Webhooks**: `supabase/functions/polar-webhooks/`
  - HMAC SHA-256 signature verification
  - Automated database updates for subscriptions and orders
  - Customer profile synchronization
- **Database Schema**: `drizzle/schema/schema.ts`
  - `subscriptions` table with RLS policies
  - `orders` table for one-time purchases
  - Polar customer ID tracking in `general_user_profiles`

### OneSignal (Push Notifications)

- Flutter package: `frontend/packages/core/notification/`
- `onesignal_flutter` integration
- Edge Functions for webhooks: `supabase/functions/onesignal-webhooks/`

---

## MCP (Model Context Protocol) Tools

Claude Code has access to specialized MCP tools. **Use them actively for Research-First development**:

### 1. Context7 MCP
- **Purpose**: Retrieve up-to-date documentation for any library
- **When**: Before implementing with new libraries/frameworks

### 2. Dart MCP
- **Purpose**: Flutter/Dart implementation patterns and best practices
- **When**: Before writing any Flutter/Dart code

### 3. Supabase MCP
- **Purpose**: Check database schema, RLS policies, indexes
- **When**: Before modifying database or writing Supabase code

### 4. IDE MCP
- **Purpose**: Get diagnostics, error information
- **When**: Debugging or checking IDE state

**Workflow**: Research (MCP) → Plan → Implement → Test → Verify (MCP)

---

For detailed rules and skills, refer to files in `.claude/rules/` and `.claude/skills/`.
