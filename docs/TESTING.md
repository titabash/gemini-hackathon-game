# Testing Strategy and TDD Workflow

This document describes the testing strategy and Test-Driven Development (TDD) workflow in flutter-boilerplate.

## Table of Contents

- [Testing Strategy Overview](#testing-strategy-overview)
- [Test-Driven Development (TDD)](#test-driven-development-tdd)
- [Frontend Testing (Flutter)](#frontend-testing-flutter)
- [Edge Functions Testing (Deno)](#edge-functions-testing-deno)
- [Backend Testing (Python)](#backend-testing-python)
- [Test Coverage](#test-coverage)
- [CI/CD Integration](#cicd-integration)

## Testing Strategy Overview

### Test Pyramid

```
        ┌─────────────┐
        │  E2E Tests  │  ← Few: Critical user flows
        └─────────────┘
       ┌───────────────┐
       │Integration    │  ← Moderate: API integration, DB operations
       │Tests          │
       └───────────────┘
      ┌─────────────────┐
      │  Unit Tests     │  ← Many: Business logic, functions
      └─────────────────┘
```

### Test Types and Target Coverage

| Test Type | Target | Target Coverage | Execution Frequency |
|----------|------|--------------|---------|
| Unit Tests | Individual functions/classes | 90%+ | Continuous (TDD) |
| Widget Tests | UI components | 80%+ | On commit |
| Integration Tests | API/DB integration | 70%+ | On commit |
| E2E Tests | User flows | Critical flows only | Pre-deployment |

## Test-Driven Development (TDD)

### TDD Cycle (Red-Green-Refactor)

```
1. Red    → Write test (fails)
   ↓
2. Green  → Minimal implementation (test passes)
   ↓
3. Refactor → Refactoring (improve quality)
   ↓
   Repeat
```

### TDD Practice Example

#### 1. Red: Write Test First

```dart
// test/features/counter/model/counter_state_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CounterState', () {
    test('initial value is 0', () {
      final counter = CounterState();
      expect(counter.count, 0);
    });

    test('increment increases value', () {
      final counter = CounterState();
      counter.increment();
      expect(counter.count, 1);
    });

    test('decrement decreases value', () {
      final counter = CounterState();
      counter.decrement();
      expect(counter.count, -1);
    });
  });
}
```

```bash
# Run test (verify it fails)
flutter test test/features/counter/model/counter_state_test.dart
# → FAILED
```

#### 2. Green: Minimal Implementation

```dart
// lib/features/counter/model/counter_state.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_state.g.dart';

@riverpod
class CounterState extends _$CounterState {
  @override
  int build() => 0;  // Initial value

  void increment() => state++;
  void decrement() => state--;
}
```

```bash
# Generate code
flutter pub run build_runner build

# Run test (verify it passes)
flutter test test/features/counter/model/counter_state_test.dart
# → PASSED
```

#### 3. Refactor: Refactoring

```dart
// Refactor to better implementation
@riverpod
class CounterState extends _$CounterState {
  @override
  int build() => 0;

  void increment() => state = state + 1;
  void decrement() => state = state - 1;
  void reset() => state = 0;  // Add new feature
}
```

```bash
# Verify tests still pass
flutter test
# → ALL TESTS PASSED
```

### TDD Best Practices

✅ **DO**:
- Write tests first
- One test for one feature
- Verify test fails before implementation
- Progress in small steps
- Always run tests after refactoring

❌ **DON'T**:
- Don't start implementation without tests
- Don't write tests that don't fail
- Don't test multiple features at once
- Don't skip tests

## Frontend Testing (Flutter)

### Unit Tests

#### Testing Riverpod Providers

```dart
// test/features/user/model/user_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('fetch user information', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Test AsyncValue
    expect(
      container.read(userStateProvider),
      const AsyncValue<User>.loading(),
    );

    // Wait for data fetch
    await container.read(userStateProvider.future);

    // Verify data is fetched
    final state = container.read(userStateProvider);
    expect(state.hasValue, true);
    expect(state.value?.name, 'Test User');
  });
}
```

#### Testing Business Logic

```dart
// test/features/cart/model/cart_service_test.dart
void main() {
  group('CartService', () {
    test('can add item', () {
      final service = CartService();
      final item = Item(id: '1', name: 'Product', price: 100);

      service.addItem(item);

      expect(service.items.length, 1);
      expect(service.items.first, item);
    });

    test('can calculate total price', () {
      final service = CartService();
      service.addItem(Item(id: '1', name: 'A', price: 100));
      service.addItem(Item(id: '2', name: 'B', price: 200));

      expect(service.totalPrice, 300);
    });
  });
}
```

### Widget Tests

```dart
// test/features/counter/ui/counter_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('counter UI displays correctly', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CounterPage(),
        ),
      ),
    );

    // Verify initial value is 0
    expect(find.text('0'), findsOneWidget);

    // Verify + button exists
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('tapping + button increases value', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CounterPage(),
        ),
      ),
    );

    // Tap + button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify value becomes 1
    expect(find.text('1'), findsOneWidget);
  });
}
```

### Integration Tests (Supabase Integration)

```dart
// integration_test/auth_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication flow', () {
    testWidgets('Login -> Dashboard navigation', (tester) async {
      await tester.pumpWidget(const MyApp());

      // Login page displays
      expect(find.text('Login'), findsOneWidget);

      // Enter email and password
      await tester.enterText(
        find.byKey(const Key('email')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password')),
        'password123',
      );

      // Tap login button
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Navigate to dashboard
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
```

### Using Mocks

```dart
// test/mocks/mock_supabase_client.dart
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
  });

  test('login succeeds', () async {
    // Configure mock
    when(() => mockAuth.signInWithPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => AuthResponse(
      user: User(...),
      session: Session(...),
    ));

    // Execute test
    final result = await authService.signIn('test@example.com', 'password');

    expect(result.user, isNotNull);
    verify(() => mockAuth.signInWithPassword(
      email: 'test@example.com',
      password: 'password',
    )).called(1);
  });
}
```

### Running Tests

```bash
# Run all tests
make frontend-test
# Or
cd frontend && melos run test

# Specific package only
cd frontend/apps/web
flutter test

# With coverage
melos run test_coverage

# Integration Tests
cd frontend/apps/web
flutter test integration_test/
```

## Edge Functions Testing (Deno)

### Unit Tests

```typescript
// supabase/functions/helloworld/index.test.ts
import { assertEquals } from 'https://deno.land/std@0.192.0/testing/asserts.ts'

Deno.test('Hello World function returns correct response', async () => {
  const req = new Request('http://localhost/functions/v1/helloworld', {
    method: 'POST',
    body: JSON.stringify({ name: 'Test' }),
  })

  // Execute function (call actual function logic)
  const response = await handleRequest(req)
  const data = await response.json()

  assertEquals(response.status, 200)
  assertEquals(data.message, 'Hello Test!')
})
```

### Database Integration Tests

```typescript
// supabase/functions/user-api/index.test.ts
import { createClient } from '@supabase/supabase-js'

Deno.test('can create user', async () => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const { data, error } = await supabase
    .from('users')
    .insert({ name: 'Test User' })
    .select()
    .single()

  assertEquals(error, null)
  assertEquals(data.name, 'Test User')

  // Cleanup
  await supabase.from('users').delete().eq('id', data.id)
})
```

### Running Tests

```bash
# Deno tests
cd supabase/functions
deno test --allow-net --allow-env
```

## Backend Testing (Python)

### Unit Tests (pytest)

```python
# backend-py/app/tests/test_user_usecase.py
import pytest
from src.usecase.user_usecase import UserUseCase

@pytest.fixture
def user_usecase():
    return UserUseCase()

def test_create_user(user_usecase):
    """Can create user"""
    user = user_usecase.create_user(
        email="test@example.com",
        name="Test User"
    )

    assert user.id is not None
    assert user.email == "test@example.com"
    assert user.name == "Test User"

def test_get_user(user_usecase):
    """Can get user by user ID"""
    # Prepare
    created = user_usecase.create_user(
        email="test@example.com",
        name="Test User"
    )

    # Execute
    user = user_usecase.get_user(created.id)

    # Verify
    assert user.id == created.id
    assert user.email == created.email
```

### Integration Tests

```python
# backend-py/app/tests/test_user_api.py
import pytest
from fastapi.testclient import TestClient
from src.app import app

client = TestClient(app)

def test_create_user_api():
    """User creation API works correctly"""
    response = client.post(
        "/api/users",
        json={"email": "test@example.com", "name": "Test User"}
    )

    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "test@example.com"
    assert data["name"] == "Test User"

def test_get_user_api():
    """User retrieval API works correctly"""
    # Prepare: Create user
    create_response = client.post(
        "/api/users",
        json={"email": "test@example.com", "name": "Test User"}
    )
    user_id = create_response.json()["id"]

    # Execute: Get user
    response = client.get(f"/api/users/{user_id}")

    # Verify
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == user_id
```

### Using Mocks

```python
# backend-py/app/tests/test_with_mock.py
from unittest.mock import Mock, patch
import pytest

@patch('src.infra.supabase_client.get_client')
def test_with_mock_supabase(mock_get_client):
    """Mock Supabase client"""
    # Configure mock
    mock_client = Mock()
    mock_get_client.return_value = mock_client
    mock_client.table().select().execute.return_value.data = [
        {"id": "1", "name": "Test"}
    ]

    # Execute test
    result = fetch_users()

    # Verify
    assert len(result) == 1
    assert result[0]["name"] == "Test"
    mock_get_client.assert_called_once()
```

### Running Tests

```bash
# All tests
cd backend-py/app
uv run pytest

# With coverage
uv run pytest --cov=src --cov-report=html

# Specific test only
uv run pytest tests/test_user_usecase.py

# Parallel execution (faster)
uv run pytest -n auto
```

## Test Coverage

### Coverage Goals

- **Unit Tests**: 90%+
- **Integration Tests**: 70%+
- **Critical Path**: 100%

### Coverage Reports

#### Frontend

```bash
cd frontend
melos run test_coverage

# View report
open coverage/html/index.html
```

#### Backend

```bash
cd backend-py/app
uv run pytest --cov=src --cov-report=html

# View report
open htmlcov/index.html
```

### Checking Coverage

```bash
# Coverage for all components
make test-all

# Identify areas lacking coverage
# Frontend
cd frontend && melos run test_coverage
grep -A 5 "TOTAL" coverage/lcov.info

# Backend
cd backend-py/app
uv run pytest --cov=src --cov-report=term-missing
```

## CI/CD Integration

### GitHub Actions Configuration

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.6'

      - name: Bootstrap Monorepo
        run: |
          cd frontend
          melos bootstrap

      - name: Run Tests
        run: |
          cd frontend
          melos run test_coverage

      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./frontend/coverage/lcov.info
          flags: frontend

  test-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.13'

      - name: Install uv
        run: pip install uv

      - name: Run Tests
        run: |
          cd backend-py/app
          uv sync
          uv run pytest --cov=src --cov-report=xml

      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./backend-py/app/coverage.xml
          flags: backend
```

### Pull Request Requirements

- ✅ All tests pass
- ✅ Maintain 90%+ coverage
- ✅ Always add tests for new features
- ✅ Include regression tests

## Summary

### Testing Best Practices

✅ **DO**:
- Follow TDD cycle (Red-Green-Refactor)
- Write tests first
- Write small, independent tests
- Use Arrange-Act-Assert pattern
- Use mocks appropriately
- Maintain 90%+ coverage
- Integrate with CI/CD pipeline

❌ **DON'T**:
- Don't skip tests
- Don't start implementation without tests
- Don't write overly complex tests
- Don't neglect test maintenance
- Don't pursue coverage alone (quality is also important)

### Test Commands List

```bash
# Frontend
make frontend-test              # Test all packages
cd frontend && melos run test_coverage  # With coverage

# Edge Functions
cd supabase/functions
deno test --allow-net --allow-env

# Backend
cd backend-py/app
uv run pytest --cov=src

# Overall
make test-all                   # Test all components
```

For more details, refer to the following documents:
- [DEVELOPMENT.md](./DEVELOPMENT.md) - Development workflow
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guide
