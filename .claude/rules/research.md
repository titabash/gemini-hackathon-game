# Research-First Development Policy

**MANDATORY**: Before starting any implementation or planning, you MUST conduct thorough research.

## Pre-Implementation Research (REQUIRED)

Before writing any code or creating a plan, you MUST:

1. **Use Context7 MCP** to fetch the latest documentation for all relevant libraries and frameworks
2. **Use Dart MCP** to understand Flutter/Dart implementation patterns and best practices
3. **Use Supabase MCP** to check database schema, RLS policies, and indexes before modifications
4. **Use WebSearch** to verify current best practices and common pitfalls
5. **Use WebFetch** to read official documentation directly

## What to Research

**ALWAYS research**:
- Library/package versions (pub.dev) and their current APIs
- Deprecated features and their replacements
- Breaking changes in recent versions
- Official recommended patterns and anti-patterns
- Dart type definitions and interfaces
- Flutter widget signatures and parameters
- Configuration file formats (pubspec.yaml, analysis_options.yaml)
- CLI command syntax (flutter, dart, melos)
- Riverpod provider patterns and code generation
- Freezed model patterns and json_serializable
- Database schema (via Supabase MCP)

**NEVER**:
- Make assumptions based on memory or general knowledge
- Use outdated patterns without verification
- Implement features without checking official docs
- Guess API signatures or parameter types
- Modify database without checking current schema (Supabase MCP)

## Mandatory Research Scenarios

Research is REQUIRED when:
- Using any external Flutter package or Dart library
- Implementing authentication or security features
- Configuring build tools (build_runner, Melos)
- Setting up database schemas or migrations
- Integrating third-party APIs or services (Polar.sh, OneSignal)
- Using CLI tools with specific syntax (flutter, dart, melos)
- Implementing real-time features (Supabase Realtime)
- Working with type definitions (Freezed, json_serializable)
- Writing Riverpod providers (generator patterns)
- Creating navigation routes (GoRouter)
- Implementing internationalization (slang)

## MCP Tools Usage

### Context7 MCP
- **Purpose**: Retrieve up-to-date documentation for any library/framework
- **When**: Before implementing with any external package
- **Example**: Research Riverpod 3.0 latest patterns, Freezed usage, Dio configuration

### Dart MCP
- **Purpose**: Flutter/Dart implementation patterns and best practices
- **When**: Before writing any Flutter/Dart code
- **Example**: Widget implementation, Riverpod provider patterns, async/await best practices

### Supabase MCP
- **Purpose**: Check database structure, RLS policies, indexes
- **When**: Before any database operations or modifications
- **Example**: Verify table schema, check RLS policies, inspect relationships

### IDE MCP
- **Purpose**: Get diagnostics and error information
- **When**: Debugging or checking IDE state
- **Example**: Check analyzer warnings, verify build errors

## spec サブエージェントとの連携

技術選定や新規モジュールのセットアップ時は、`spec` サブエージェントを積極的に活用してください。

### spec エージェントを使用すべき場面

- 新しいFlutterパッケージ/Dartライブラリの導入
- 既存パッケージのメジャーアップデート
- pubspec.yaml の設定・変更
- build_runner の設定
- Melos の設定
- GoRouter の設定
- CI/CD の設定

### 調査レポートの保存先

spec エージェントは調査結果を `docs/_research/` に保存します：

```
docs/_research/
├── 2024-01-15-riverpod-3.0.md
├── 2024-01-16-gorouter-14.md
├── 2024-01-17-freezed-2.0.md
└── ...
```

これらのレポートは将来の参照用に保持され、同じ技術の再調査時に参考にできます。

## Flutter Specific Research Checklist

### Before Implementing State Management (Riverpod)
- [ ] Context7: Check Riverpod latest version and patterns
- [ ] Dart MCP: Verify provider generator usage
- [ ] Research: AsyncNotifier vs FutureProvider vs StreamProvider

### Before Creating Data Models (Freezed)
- [ ] Context7: Check Freezed + json_serializable patterns
- [ ] Dart MCP: Verify immutable model best practices
- [ ] Research: Union types and sealed classes usage

### Before Database Operations
- [ ] Supabase MCP: Check current table schema
- [ ] Supabase MCP: Verify RLS policies
- [ ] Context7: Research Supabase Flutter client latest API

### Before Navigation Implementation (GoRouter)
- [ ] Context7: Check GoRouter latest patterns
- [ ] Dart MCP: Verify declarative routing best practices
- [ ] Research: Authentication guards and deep linking

### Before Adding External Services
- [ ] Context7: Check service SDK/client documentation
- [ ] Research: Flutter integration patterns
- [ ] Research: Platform-specific configuration (iOS/Android/Web)

## Enforcement

This research-first approach is **NON-NEGOTIABLE**. Any implementation without proper research is considered incomplete and must be revised.

### Workflow Summary

```
1. Receive task
2. Research (Context7/Dart MCP/Supabase MCP)
3. Plan implementation
4. Write tests (TDD Red phase)
5. Implement
6. Verify (All tests pass)
```

**Research comes FIRST, before planning and implementation.**
