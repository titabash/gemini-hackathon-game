---
name: flutter-test
description: Create comprehensive tests following TDD practices. Use when writing unit tests for providers, widget tests for UI components, or integration tests for user flows.
---

# Flutter Test Creation Skill

Create comprehensive tests following Test-Driven Development (TDD) practices for Flutter applications.

## Task

You will create tests for:
- **Unit Tests**: Business logic, models, services
- **Widget Tests**: UI components and interactions
- **Integration Tests**: Complete user flows

## TDD Workflow (MANDATORY)

This project follows **Test-Driven Development**. Always follow this workflow:

1. **Write Test First**: Create failing test based on requirements
2. **Run Test**: Verify test fails for the right reason
3. **Implement Code**: Write minimal code to pass test
4. **Run Test**: Verify test passes
5. **Refactor**: Improve code while keeping tests green
6. **Commit**: Commit only when tests pass

## Test Types

### 1. Unit Tests

Test individual functions, classes, and business logic in isolation.

**Location**: `test/{layer}/{filename}_test.dart`

**Example: Testing a Provider** (`test/features/counter/model/counter_provider_test.dart`):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:web_app/features/counter/model/counter_provider.dart';

void main() {
  group('Counter Provider', () {
    test('initial value is 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(counterProvider), 0);
    });

    test('increment increases value by 1', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(counterProvider.notifier).increment();

      expect(container.read(counterProvider), 1);
    });

    test('decrement decreases value by 1', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(counterProvider.notifier).increment();
      container.read(counterProvider.notifier).decrement();

      expect(container.read(counterProvider), 0);
    });

    test('reset returns to 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(counterProvider.notifier).increment();
      container.read(counterProvider.notifier).increment();
      container.read(counterProvider.notifier).reset();

      expect(container.read(counterProvider), 0);
    });
  });
}
```

### 2. Widget Tests

Test UI components and user interactions.

**Location**: `test/{layer}/ui/{widget_name}_test.dart`

**Example: Testing a Widget** (`test/features/counter/ui/counter_screen_test.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:web_app/features/counter/ui/counter_screen.dart';
import 'package:web_app/features/counter/model/counter_provider.dart';

void main() {
  testWidgets('Counter displays initial value', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CounterScreen(),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Counter increments when button is tapped', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CounterScreen(),
        ),
      ),
    );

    // Find and tap increment button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });
}
```

### 3. Integration Tests

Test complete user flows end-to-end.

**Location**: `integration_test/{flow_name}_test.dart`

**Example: Auth Flow Test**:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:web_app/app/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow', () {
    testWidgets('Complete login workflow', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: App(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(
        find.byType(TextField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'password123',
      );

      // Submit
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify navigation to dashboard
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
```

## Running Tests

### Run All Tests:

```bash
# All packages (unit + widget)
make frontend-test

# Specific package
cd frontend/apps/web && flutter test

# With coverage
flutter test --coverage
```

### Run Integration Tests:

```bash
# Desktop/Mobile (requires device/simulator)
cd frontend/apps/web
flutter test integration_test/ -d macos

# Web (requires ChromeDriver)
chromedriver --port=4444 &
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d chrome
```

## Supabase Mocking

Use `mock_supabase_http_client` for database operations:

```dart
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';

void main() {
  late MockSupabaseHttpClient mockHttpClient;
  late SupabaseClient mockSupabase;

  setUpAll(() {
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

  test('fetch user data', () async {
    // Insert test data
    await mockSupabase.from('users').insert({
      'id': 'user-123',
      'email': 'test@example.com',
    });

    // Test code that queries database
    final users = await mockSupabase.from('users').select();
    expect(users.length, 1);
  });
}
```

## Test Best Practices

### 1. Test Structure (Arrange-Act-Assert):

```dart
test('description', () {
  // Arrange: Setup test data and environment
  final container = ProviderContainer();
  final counter = container.read(counterProvider.notifier);

  // Act: Perform the action being tested
  counter.increment();

  // Assert: Verify the result
  expect(container.read(counterProvider), 1);

  // Cleanup
  container.dispose();
});
```

### 2. Use `group()` for Organization:

```dart
void main() {
  group('Counter Feature', () {
    group('increment', () {
      test('increases value by 1', () { /* ... */ });
      test('works multiple times', () { /* ... */ });
    });

    group('decrement', () {
      test('decreases value by 1', () { /* ... */ });
      test('does not go below 0', () { /* ... */ });
    });
  });
}
```

### 3. Use `setUp()` and `tearDown()`:

```dart
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('test 1', () {
    // container is available
  });

  test('test 2', () {
    // fresh container for each test
  });
}
```

### 4. Test Data Factories:

```dart
class UserFactory {
  static UserProfile createUser({
    String id = 'user-123',
    String email = 'test@example.com',
    String? displayName,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );
  }

  static List<UserProfile> createUserList(int count) {
    return List.generate(
      count,
      (i) => createUser(id: 'user-$i', email: 'user$i@example.com'),
    );
  }
}

// Usage in tests
test('display user list', () {
  final users = UserFactory.createUserList(5);
  // ...
});
```

## Common Test Patterns

### Testing Async Operations:

```dart
test('async operation completes', () async {
  final result = await someAsyncFunction();
  expect(result, expectedValue);
});
```

### Testing Streams:

```dart
test('stream emits values', () {
  final stream = someStreamFunction();

  expectLater(
    stream,
    emitsInOrder([value1, value2, value3]),
  );
});
```

### Testing Errors:

```dart
test('throws error on invalid input', () {
  expect(
    () => functionThatThrows(),
    throwsException,
  );
});

test('throws specific error', () {
  expect(
    () => functionThatThrows(),
    throwsA(isA<SpecificException>()),
  );
});
```

### Finding Widgets:

```dart
// By text
find.text('Hello')

// By widget type
find.byType(ElevatedButton)

// By key
find.byKey(const Key('submit-button'))

// By icon
find.byIcon(Icons.add)

// Combining finders
find.descendant(
  of: find.byType(AppBar),
  matching: find.text('Title'),
)
```

## Common Pitfalls

- ❌ Don't forget to dispose containers in tearDown
- ❌ Don't use `ref.read()` in build methods being tested
- ❌ Don't forget `await tester.pump()` after interactions
- ❌ Don't test implementation details, test behavior
- ❌ Don't create one giant test, break into smaller tests
- ❌ Don't forget to test error cases
- ❌ Don't skip async operations with `pumpAndSettle()`

## Test Coverage

### Generate Coverage Report:

```bash
cd frontend/apps/web
flutter test --coverage

# View coverage (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Coverage Requirements:
- New features: ≥ 90% coverage
- Modified code: Include regression tests
- Critical paths (auth, payments): 100% coverage

## Notes

- This project follows TDD methodology
- Always write tests before implementation
- See `frontend/apps/web/test/widget_test.dart` for examples
- Use `make frontend-test` to run all tests
- Integration tests require device/simulator
