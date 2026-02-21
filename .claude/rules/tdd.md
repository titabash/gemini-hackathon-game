# Test-Driven Development Policy

**MANDATORY**: All implementations MUST follow Test-Driven Development (TDD) methodology.

## TDD Workflow (REQUIRED)

Every implementation MUST follow this strict sequence:

1. **Write Tests First**
   - Define expected inputs and outputs
   - Write test cases BEFORE any implementation code
   - Focus on behavior, not implementation details

2. **Run Tests and Confirm Failure**
   - Execute tests to verify they fail (Red phase)
   - Confirm the test correctly captures the requirement
   - Commit tests at this stage

3. **Implement to Pass Tests**
   - Write minimal code to make tests pass (Green phase)
   - Do NOT modify tests during implementation
   - Continue until all tests pass

4. **Refactor if Needed**
   - Improve code quality while keeping tests green
   - Tests remain unchanged during refactoring

## Prohibited Practices

**NEVER**:
- Write implementation code before tests
- Modify tests to make them pass (fix implementation instead)
- Skip the failing test verification step
- Commit untested code
- Add features without corresponding tests

## Test Commands

| Operation | Command |
|-----------|---------|
| **Flutter Tests (Unit + Widget)** | `make frontend-test` |
| **Backend Python Tests** | `make test-backend-py` |
| **Integration Tests** | `make frontend-integration-test` |
| **All Tests** | `make test-all` |
| **Widgetbook (UI Catalog)** | `make frontend-widgetbook` |
| **Patrol (E2E)** | `make frontend-patrol` |

## Commit Strategy

```
# ✅ Correct TDD commit sequence
1. feat(test): add tests for user authentication  # Red phase
2. feat: implement user authentication            # Green phase
3. refactor: clean up authentication code         # Refactor phase

# ❌ Wrong approach
1. feat: implement user authentication            # No tests first!
```

## Exceptions

TDD is NOT required for:
- Documentation files (README, CLAUDE.md, etc.)
- Configuration files (pubspec.yaml, .env, etc.)
- Static assets (images, fonts, etc.)
- Auto-generated files (`*.g.dart`, `*.freezed.dart`)
- **UI Widgets**（Widgetbook で品質担保）

## UI コンポーネントのテスト方針

**UI コンポーネントは単体テスト不要。代わりに Widgetbook を必須とする。**

Flutter では、UI コンポーネントは **Widgetbook** でビジュアルテストを行い、ロジックのみ TDD を適用します。

### 単体テスト不要（Widgetbook 対象）

| 対象 | 場所 |
|------|------|
| Shared UI Components | `frontend/packages/shared/ui/lib/` |
| Entity UI | `frontend/apps/web/lib/entities/*/ui/` |
| Feature UI | `frontend/apps/web/lib/features/*/ui/` |
| Page UI | `frontend/apps/web/lib/pages/*/` |

### 単体テスト必須（TDD 対象）

| 対象 | 場所 |
|------|------|
| ビジネスロジック | `*/model/` (Riverpod Providers) |
| API / データ取得 | `*/api/` |
| ユーティリティ | `core_utils/lib/` |
| 認証ロジック | `core_auth/lib/providers/` |
| データモデル | `*/models/` (Freezed) |

### Widget Tests が必要な場合

以下の場合のみ Widget Tests を作成：
- **状態によって表示が変わる Widget**（条件分岐、状態管理）
- **ユーザー入力を受け付ける Widget**（フォーム、ボタン）
- **複雑なレイアウトロジック**（スクロール、アニメーション）

単純な静的Widget（アイコン、テキスト表示のみ）は Widget Tests 不要。Widgetbook で十分。

### 例

```
features/auth/
├── ui/
│   ├── login_form.dart           # ❌ 単体テスト不要
│   └── login_form.widgetbook.dart # ✅ Widgetbook 必須
├── model/
│   ├── login_form_provider.dart  # ✅ 単体テスト必須（TDD）
│   └── login_form_provider_test.dart
└── api/
    ├── login_api.dart            # ✅ 単体テスト必須（TDD）
    └── login_api_test.dart
```

→ 詳細は `.claude/rules/ui-testing.md` および `.claude/skills/widgetbook/` を参照

## All Green Policy (MANDATORY)

**作業終了時は必ずすべてのテストが通過（All Green）していること。**

### 作業終了前チェックリスト

1. **全テスト実行**: `make test-all` を実行
2. **失敗テストの対応**:
   - 原因分析を実施
   - 実装の修正（テストは変更しない）
   - 再度テスト実行
3. **All Green確認**: すべてのテストがパスするまで繰り返す
4. **コード生成確認**: `make frontend-generate` 実行後もテスト通過を確認

### 失敗テストへの対応

| 状況 | 対応 |
|------|------|
| 実装バグ | 実装を修正 |
| テスト環境問題 | 環境を修正し再実行 |
| 既存テストの破壊 | リグレッションを修正 |
| フレーキーテスト | 根本原因を特定し安定化 |
| コード生成エラー | `make frontend-clean && make frontend-generate` で再生成 |

### 禁止事項

**NEVER**:
- 失敗テストを放置して作業を終了
- テストをスキップ（`skip`, `@Skip`）して回避
- 失敗テストを削除して対処
- 「後で直す」として先送り

## Flutter 特有の注意点

### Riverpod Providers のテスト

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('Counter provider increments value', () {
    final container = ProviderContainer();
    final counter = container.read(counterProvider.notifier);

    expect(container.read(counterProvider), 0);
    counter.increment();
    expect(container.read(counterProvider), 1);

    container.dispose();
  });
}
```

### Freezed Models のテスト

```dart
test('User model equality', () {
  final user1 = User(id: '1', name: 'Alice');
  final user2 = User(id: '1', name: 'Alice');

  expect(user1, equals(user2));
  expect(user1.copyWith(name: 'Bob'), isNot(equals(user1)));
});
```

### Supabase Mock のテスト

```dart
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';

void main() {
  late MockSupabaseHttpClient mockHttpClient;
  late SupabaseClient mockSupabase;

  setUp(() {
    mockHttpClient = MockSupabaseHttpClient();
    mockSupabase = SupabaseClient(
      'https://mock.supabase.co',
      'fakeAnonKey',
      httpClient: mockHttpClient,
    );
  });

  tearDown(() {
    mockHttpClient.reset();
  });

  test('fetch user from database', () async {
    await mockSupabase.from('users').insert({'id': 1, 'name': 'Alice'});
    final users = await mockSupabase.from('users').select();

    expect(users.length, 1);
    expect(users.first['name'], 'Alice');
  });
}
```

## Enforcement

This TDD policy is **NON-NEGOTIABLE**. Implementations without prior test cases are considered incomplete and must be revised to include tests first.
