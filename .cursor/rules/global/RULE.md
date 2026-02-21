---
description: "Project-wide rules for tech stack, commands, and architecture policies"
alwaysApply: true
globs: []
---
# Project Global Rules

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter 3.35.6, Dart 3.5, Melos |
| UI | Material Design 3, Adaptive Widgets |
| State Management | Riverpod (riverpod_generator), Flutter Hooks |
| Navigation | GoRouter |
| Architecture | Feature Sliced Design (FSD) |
| Data Models | Freezed (immutable models) |
| HTTP Client | Dio + Retrofit |
| i18n | slang (type-safe translations) |
| Backend | FastAPI (Python), Supabase Edge Functions (Deno) |
| Database | PostgreSQL, Drizzle ORM |
| Auth | Supabase Flutter Client |

## Core Policies (MANDATORY)

以下のポリシーは**必須**です。詳細は各ルールを参照:

| ポリシー | ルール |
|---------|--------|
| Research-First | `@research` - 実装前に Context7/Dart MCP/Supabase MCP 確認 |
| TDD | `@tdd` - テスト駆動開発、All Green必須 |
| Commands | `@commands` - Makefileコマンド使用必須 |
| Auto-Generated | `@auto-generated` - `*.g.dart`, `*.freezed.dart` 編集禁止 |
| Supabase-First | `@supabase-first` - Supabase Flutter Client優先 |
| i18n | `@i18n` - 多言語対応必須（slang） |
| DateTime | `@datetime` - UTC保存、Frontend変換 |

## Commands

```bash
# Quality
make check-quality           # 全プロジェクトチェック
make fix-format              # 全プロジェクトformat
make test-all                # 全テスト

# Flutter
make frontend                # Web開発サーバー起動
make frontend-generate       # コード生成（Riverpod, Freezed, slang）
make frontend-test           # Flutter unit + widget tests
make frontend-widgetbook     # Widgetbook起動（UIカタログ）
make frontend-patrol         # Patrol E2Eテスト

# Database
make migrate-dev             # マイグレーション生成+適用（承認必須）
make migrate-deploy          # マイグレーション適用（承認必須）
```

## i18n (MANDATORY)

- All UI text via **slang**
- Both `en.i18n.json` and `ja.i18n.json` required
- Type-safe access: `t.common.save`, `t.auth.login`

## Architecture (Feature Sliced Design)

```
app → pages → features → entities → shared
(上位 → 下位へのみインポート可能)
```

## Code Generation

After modifying Freezed models, Riverpod providers, or i18n:

```bash
make frontend-generate
```

## Supabase MCP Usage

Before any database operations:
- Check schema: Use Supabase MCP
- Verify RLS policies: Use Supabase MCP
- Inspect relationships: Use Supabase MCP
