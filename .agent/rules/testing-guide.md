# Testing Architecture

The project follows a Test-Driven Development (TDD) approach with comprehensive testing across the monorepo structure.

## Test Structure and Organization

### Monorepo Test Structure

```
frontend/
├── apps/web/test/           # Application-level tests
│   ├── widget_test.dart     # Widget and integration tests
│   └── ...
├── packages/core/api/test/  # Core API package tests
├── packages/core/auth/test/ # Authentication tests
└── ...
```

### Test File Conventions

- **Test Files**: Must end with `_test.dart` suffix
- **Location**: Place test files in `test/` directory at the same level as `lib/`
- **Naming**: Mirror the structure of `lib/` in `test/` directory
  - Example: `lib/features/counter/model/counter_provider.dart` → `test/features/counter/model/counter_provider_test.dart`

## Test Directory Management

**IMPORTANT: Do NOT create empty test directories**

- Only create `test/` directories when you have actual test files
- Empty `test/` directories will cause `melos run test` to fail with:
  ```
  ERROR: Test directory "test" does not appear to contain any test files.
  ```
- Melos uses `--dir-exists=test` filter, so packages without tests should not have `test/` directories

**When to create test directories**:

- ✅ When adding first test file to a package
- ✅ When test files actually exist
- ❌ During package initialization "just in case"
- ❌ As placeholder for future tests

## Test Types

### Widget Tests (Most Common)

```dart
testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  // Build widget
  await tester.pumpWidget(const MyApp());

  // Verify initial state
  expect(find.text('0'), findsOneWidget);

  // Interact
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();

  // Verify result
  expect(find.text('1'), findsOneWidget);
});
```

### Unit Tests (For Business Logic)

```dart
test('Counter provider increments value', () {
  final container = ProviderContainer();
  final counter = container.read(counterProvider.notifier);

  expect(container.read(counterProvider), 0);
  counter.increment();
  expect(container.read(counterProvider), 1);
});
```

### Integration Tests (For User Flows)

- Located in `integration_test/` directory at app level
- Test complete user journeys end-to-end
- Run actual app code with real dependencies (or mocked external services)
- Verify full feature workflows including navigation, state management, and UI interactions

## Running Integration Tests

### Desktop/Mobile Devices (macOS, iOS, Android)

```bash
# Run all integration tests (specify device)
flutter test integration_test/ -d macos
flutter test integration_test/ -d ios
flutter test integration_test/ -d android

# Run specific test file
cd frontend/apps/web && flutter test integration_test/app_test.dart -d macos

# Make command (runs on available device)
make frontend-integration-test
```

### Web Environment (Chrome)

⚠️ **IMPORTANT**: `flutter test` command cannot be used for web environment. Use `flutter drive` instead.

```bash
# Prerequisites: Start ChromeDriver
npx @puppeteer/browsers install chromedriver@stable
chromedriver --port=4444  # Run in separate terminal

# Run web integration tests
cd frontend/apps/web && flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d chrome
```

### Run All Tests

```bash
# All unit, widget, and integration tests
make frontend-test-all
cd frontend && melos run test_all

# All components (Flutter + Edge Functions + Backend)
make test-all
```

## Integration Test Best Practices

1. **Use IntegrationTestWidgetsFlutterBinding**: Required for integration tests
   ```dart
   void main() {
     IntegrationTestWidgetsFlutterBinding.ensureInitialized();
     // tests...
   }
   ```

2. **Test Real User Scenarios**: Focus on complete workflows
   - User registration → email verification → dashboard access
   - Login → navigate to feature → perform action → logout
   - Multi-step forms with validation and submission

3. **Mock External Services**: Use ProviderScope overrides for external dependencies
   ```dart
   await tester.pumpWidget(
     ProviderScope(
       overrides: [
         supabaseProvider.overrideWithValue(FakeSupabaseClient()),
       ],
       child: const App(),
     ),
   );
   ```

4. **Wait for Async Operations**: Use `pumpAndSettle()` for animations and async state
   ```dart
   await tester.tap(loginButton);
   await tester.pumpAndSettle(); // Wait for navigation/animations
   ```

5. **Test Navigation Flows**: Verify GoRouter-based navigation
   ```dart
   // Verify redirect from protected route when unauthenticated
   // Verify navigation after successful login
   // Verify deep links and route parameters
   ```

6. **Handle Edge Cases**:
   - Network errors during API calls
   - Invalid user input
   - Authentication failures
   - Timeout scenarios

7. **Keep Tests Isolated**: Each test should be independent
   - Reset state between tests
   - Use separate ProviderScope for each test
   - Avoid shared mutable state

## Testing with Riverpod

**Override providers for testing**:

```dart
testWidgets('Test with mocked provider', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(mockApiClient),
      ],
      child: const MyApp(),
    ),
  );
  // Test with mocked dependencies
});
```

## Test Coverage Requirements

- **New Features**: Minimum 90% test coverage required
- **Modified Code**: Include regression tests for existing functionality
- **Critical Paths**: 100% coverage for authentication, payments, data integrity

## Best Practices

1. **Test First (TDD)**:
   - Write failing test
   - Implement minimal code to pass
   - Refactor while keeping tests green

2. **Test Organization**:
   - Group related tests with `group()`
   - Use descriptive test names
   - Follow Arrange-Act-Assert pattern

3. **Mock External Dependencies**:
   - Use `mockito` for mocking
   - Mock API clients, databases, external services
   - Avoid testing external systems

4. **Test Data Builders**:
   - Create test data factories
   - Use consistent test fixtures
   - Avoid magic values in tests

5. **Async Testing**:
   - Use `async`/`await` properly
   - Call `tester.pump()` or `tester.pumpAndSettle()` for widget updates
   - Handle Future/Stream testing correctly

6. **Test Maintenance**:
   - Keep tests fast (< 100ms per test)
   - Remove or update obsolete tests
   - Refactor tests alongside production code
   - Use `setUp()` and `tearDown()` for common setup

## Troubleshooting

### Test not found errors

```bash
# Regenerate code if providers are missing
cd frontend && flutter pub run build_runner build --delete-conflicting-outputs

# Clean and rebuild
cd frontend && melos clean && melos bootstrap
```

### Async test timeouts

- Increase timeout: `test('...', timeout: Timeout(Duration(seconds: 30)))`
- Use `tester.pumpAndSettle()` for animations
- Check for infinite loops or missing completers

### Widget not found

- Verify widget is built: `await tester.pumpWidget()`
- Check visibility: widget might be scrolled out of view
- Use `find.byType()` instead of `find.text()` for dynamic content

## Supabase Testing

### Package Installation

**Package**: `mock_supabase_http_client` (v0.0.3+2)

**Installation Status**: ✅ Installed in `frontend/pubspec.yaml` dev_dependencies. Available to all workspace packages.

### Purpose

Provides an in-memory HTTP client that intercepts Supabase requests and returns mock data, enabling unit and widget tests without actual network calls.

### Basic Usage

**Setup Pattern**:

```dart
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:supabase/supabase.dart';
import 'package:flutter_test/flutter_test.dart';

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
    // Clear data between tests to ensure isolation
    mockHttpClient.reset();
  });

  tearDownAll(() {
    mockHttpClient.close();
  });

  // Tests...
}
```

### CRUD Operations Testing

**Insert and Select**:

```dart
test('insert and select posts', () async {
  await mockSupabase.from('posts').insert({
    'id': 1,
    'title': 'Test Post',
    'content': 'Hello, World!',
    'published': true,
  });

  final posts = await mockSupabase.from('posts').select();

  expect(posts.length, 1);
  expect(posts.first['title'], 'Test Post');
});
```

**Update**:

```dart
test('update post title', () async {
  await mockSupabase.from('posts').insert({
    'id': 1,
    'title': 'Old Title',
  });

  await mockSupabase
      .from('posts')
      .update({'title': 'New Title'})
      .eq('id', 1);

  final posts = await mockSupabase.from('posts').select();
  expect(posts.first['title'], 'New Title');
});
```

**Delete**:

```dart
test('delete post', () async {
  await mockSupabase.from('posts').insert({'id': 1, 'title': 'To Delete'});

  await mockSupabase.from('posts').delete().eq('id', 1);

  final posts = await mockSupabase.from('posts').select();
  expect(posts.isEmpty, true);
});
```

**Filtering and Ordering**:

```dart
test('filter and order posts', () async {
  await mockSupabase.from('posts').insert([
    {'id': 1, 'title': 'Post 1', 'views': 100, 'published': true},
    {'id': 2, 'title': 'Post 2', 'views': 50, 'published': true},
    {'id': 3, 'title': 'Post 3', 'views': 200, 'published': false},
  ]);

  // Filter by published
  final published = await mockSupabase
      .from('posts')
      .select()
      .eq('published', true);
  expect(published.length, 2);

  // Order by views descending
  final ordered = await mockSupabase
      .from('posts')
      .select()
      .order('views', ascending: false)
      .limit(2);
  expect(ordered.first['views'], 200);
  expect(ordered.last['views'], 100);
});
```

### Provider Override Testing

**Testing Riverpod Providers**:

```dart
// Define provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final postsProvider = FutureProvider<List<Post>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final data = await supabase.from('posts').select();
  return data.map((json) => Post.fromJson(json)).toList();
});

// Test with mock
test('posts provider fetches posts', () async {
  final mockHttpClient = MockSupabaseHttpClient();
  final mockSupabase = SupabaseClient(
    'https://mock.supabase.co',
    'fakeAnonKey',
    httpClient: mockHttpClient,
  );

  // Setup test data
  await mockSupabase.from('posts').insert([
    {'id': 1, 'title': 'Post 1'},
    {'id': 2, 'title': 'Post 2'},
  ]);

  final container = ProviderContainer(
    overrides: [
      supabaseProvider.overrideWithValue(mockSupabase),
    ],
  );

  final posts = await container.read(postsProvider.future);
  expect(posts.length, 2);
});
```

**Widget Tests with Mock Supabase**:

```dart
testWidgets('displays posts from Supabase', (WidgetTester tester) async {
  final mockHttpClient = MockSupabaseHttpClient();
  final mockSupabase = SupabaseClient(
    'https://mock.supabase.co',
    'fakeAnonKey',
    httpClient: mockHttpClient,
  );

  await mockSupabase.from('posts').insert([
    {'id': 1, 'title': 'First Post'},
    {'id': 2, 'title': 'Second Post'},
  ]);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supabaseProvider.overrideWithValue(mockSupabase),
      ],
      child: const MyApp(),
    ),
  );

  await tester.pumpAndSettle();

  expect(find.text('First Post'), findsOneWidget);
  expect(find.text('Second Post'), findsOneWidget);
});
```

### Supported Features and Limitations

**✅ Supported**:

- CRUD operations (Select, Insert, Update, Delete)
- Filtering with `.eq()`, `.gt()`, `.lt()`, etc.
- Ordering with `.order()`
- Limiting with `.limit()`
- Basic related tables
- Edge Functions (via `registerEdgeFunction`)
- RPC Functions (via `registerRpcFunction`)
- Error simulation (via `postgrestExceptionTrigger`)

**❌ Not Supported**:

- Authentication (use Fake classes)
- Realtime subscriptions (use Mockito)
- Storage operations (use Fake classes)
- Nested `!inner` joins
- Complex relationship queries

### Workarounds for Unsupported Features

**Authentication Testing**:

```dart
class FakeGoTrueClient extends Fake implements GoTrueClient {
  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return AuthResponse(
      user: User(id: 'test-user', email: email),
      session: Session(accessToken: 'test-token', tokenType: 'Bearer'),
    );
  }

  @override
  Future<UserResponse> getUser() async {
    return UserResponse(
      user: User(id: 'test-user', email: 'test@example.com'),
    );
  }
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  @override
  late final GoTrueClient auth = FakeGoTrueClient();

  // For database operations, compose with MockSupabaseHttpClient
}
```

## Test Data Management

### Test Data Factories

Create reusable factory classes for consistent test data:

```dart
class PostFactory {
  static Map<String, dynamic> createPost({
    int id = 1,
    String title = 'Test Post',
    String content = 'Test content',
    int userId = 1,
    bool published = true,
  }) {
    return {
      'id': id,
      'title': title,
      'content': content,
      'user_id': userId,
      'published': published,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static List<Map<String, dynamic>> createPostList(int count) {
    return List.generate(
      count,
      (i) => createPost(id: i + 1, title: 'Post ${i + 1}'),
    );
  }

  static Map<String, dynamic> createDraftPost({int id = 1}) {
    return createPost(id: id, published: false);
  }
}

// Usage in tests
test('displays published posts only', () async {
  await mockSupabase.from('posts').insert([
    ...PostFactory.createPostList(3),
    PostFactory.createDraftPost(id: 4),
  ]);

  final published = await mockSupabase
      .from('posts')
      .select()
      .eq('published', true);

  expect(published.length, 3);
});
```

### Fixture Management Best Practices

**1. Organize by Domain**:

```
test/
├── fixtures/
│   ├── post_fixtures.dart       # Post-related factories
│   ├── user_fixtures.dart       # User-related factories
│   └── comment_fixtures.dart    # Comment-related factories
├── features/
│   └── posts/
│       └── post_provider_test.dart
```

**2. Use Meaningful Defaults**:

```dart
class UserFactory {
  static Map<String, dynamic> createUser({
    int id = 1,
    String email = 'user@example.com',
    String name = 'Test User',
    String role = 'user',
  }) {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
    };
  }

  // Specialized variants
  static Map<String, dynamic> createAdmin({int id = 100}) {
    return createUser(
      id: id,
      email: 'admin@example.com',
      role: 'admin',
    );
  }
}
```

**3. Avoid Magic Values**:

```dart
// ❌ Bad: Magic values scattered in tests
test('filter posts', () async {
  await mockSupabase.from('posts').insert({
    'id': 42,
    'title': 'xyz123',
    'user_id': 999,
  });
  // ...
});

// ✅ Good: Named constants and factories
test('filter posts', () async {
  const testUserId = 1;
  await mockSupabase.from('posts').insert(
    PostFactory.createPost(userId: testUserId),
  );
  // ...
});
```

### Additional Resources

- **Comprehensive Guide**: See `.agent/rules/supabase-testing.md` for detailed examples
- **CLAUDE.md**: "Supabase Mocking" section for integration with project architecture
- **AGENTS.md**: "Supabase テスト要件" for TDD workflow
