# Supabase Testing Guide

Comprehensive guide for testing Supabase integrations in the Flutter frontend using `mock_supabase_http_client`.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Basic Setup](#basic-setup)
- [CRUD Operations](#crud-operations)
- [Advanced Querying](#advanced-querying)
- [Provider Testing](#provider-testing)
- [Widget Testing](#widget-testing)
- [Integration Testing](#integration-testing)
- [Edge Functions and RPC](#edge-functions-and-rpc)
- [Error Simulation](#error-simulation)
- [Test Data Patterns](#test-data-patterns)
- [Best Practices](#best-practices)
- [Limitations and Workarounds](#limitations-and-workarounds)
- [Troubleshooting](#troubleshooting)

## Overview

### What is `mock_supabase_http_client`?

A testing package that provides an in-memory HTTP client for Supabase, allowing you to:

- Test Supabase integrations without network calls
- Create deterministic, fast-running tests
- Isolate business logic from external dependencies
- Follow Test-Driven Development (TDD) practices

### Key Features

- ✅ **CRUD Operations**: Full support for Select, Insert, Update, Delete
- ✅ **Filtering & Ordering**: Query modifiers like `.eq()`, `.order()`, `.limit()`
- ✅ **Basic Relations**: Simple related table queries
- ✅ **Edge Functions**: Mock custom serverless functions
- ✅ **RPC Functions**: Mock database procedures
- ✅ **Error Simulation**: Test error handling scenarios

### Limitations

- ❌ **Authentication**: Not supported (use Fake classes)
- ❌ **Realtime**: Not supported (use Mockito)
- ❌ **Storage**: Not supported (use Fake classes)
- ❌ **Complex Joins**: Nested `!inner` joins not supported

## Installation

### Package Information

- **Package**: `mock_supabase_http_client`
- **Version**: `^0.0.3+2`
- **Location**: `frontend/pubspec.yaml` (workspace root)
- **Availability**: All workspace packages

### Installation Status

✅ **Already installed** in this project. No additional setup required.

To verify:

```bash
cd frontend
flutter pub get
```

## Basic Setup

### Standard Test Setup Pattern

```dart
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';
import 'package:supabase/supabase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockSupabaseHttpClient mockHttpClient;
  late SupabaseClient mockSupabase;

  setUpAll(() {
    // Initialize once per test file
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
    // Cleanup resources after all tests
    mockHttpClient.close();
  });

  group('My Feature Tests', () {
    // Your tests here
  });
}
```

### Why This Pattern?

- **`setUpAll`**: Creates mock client once for performance
- **`tearDown`**: Resets state between tests for isolation
- **`tearDownAll`**: Cleans up resources to prevent memory leaks
- **`group`**: Organizes related tests

## CRUD Operations

### Insert Operations

**Basic Insert**:

```dart
test('insert single record', () async {
  await mockSupabase.from('posts').insert({
    'id': 1,
    'title': 'Hello World',
    'content': 'My first post',
    'published': true,
  });

  final posts = await mockSupabase.from('posts').select();
  expect(posts.length, 1);
  expect(posts.first['title'], 'Hello World');
});
```

**Bulk Insert**:

```dart
test('insert multiple records', () async {
  await mockSupabase.from('posts').insert([
    {'id': 1, 'title': 'Post 1'},
    {'id': 2, 'title': 'Post 2'},
    {'id': 3, 'title': 'Post 3'},
  ]);

  final posts = await mockSupabase.from('posts').select();
  expect(posts.length, 3);
});
```

### Select Operations

**Select All**:

```dart
test('select all records', () async {
  await mockSupabase.from('posts').insert([
    {'id': 1, 'title': 'Post 1'},
    {'id': 2, 'title': 'Post 2'},
  ]);

  final posts = await mockSupabase.from('posts').select();
  expect(posts.length, 2);
});
```

**Select Specific Columns**:

```dart
test('select specific columns', () async {
  await mockSupabase.from('posts').insert({
    'id': 1,
    'title': 'Test',
    'content': 'Content',
    'published': true,
  });

  final posts = await mockSupabase.from('posts').select('id, title');
  // Note: mock_supabase_http_client returns all columns
  // Column filtering is not enforced in mock
  expect(posts.first.containsKey('id'), true);
  expect(posts.first.containsKey('title'), true);
});
```

### Update Operations

**Update with Filter**:

```dart
test('update records with condition', () async {
  await mockSupabase.from('posts').insert([
    {'id': 1, 'title': 'Old Title 1', 'published': false},
    {'id': 2, 'title': 'Old Title 2', 'published': false},
  ]);

  await mockSupabase
      .from('posts')
      .update({'published': true})
      .eq('id', 1);

  final posts = await mockSupabase.from('posts').select();
  expect(posts[0]['published'], true);
  expect(posts[1]['published'], false);
});
```

**Update Multiple Records**:

```dart
test('update all records', () async {
  await mockSupabase.from('posts').insert([
    {'id': 1, 'views': 0},
    {'id': 2, 'views': 0},
  ]);

  await mockSupabase
      .from('posts')
      .update({'views': 10});

  final posts = await mockSupabase.from('posts').select();
  expect(posts.every((p) => p['views'] == 10), true);
});
```

### Delete Operations

**Delete with Filter**:

```dart
test('delete specific record', () async {
  await mockSupabase.from('posts').insert([
    {'id': 1, 'title': 'Keep'},
    {'id': 2, 'title': 'Delete'},
    {'id': 3, 'title': 'Keep'},
  ]);

  await mockSupabase.from('posts').delete().eq('id', 2);

  final posts = await mockSupabase.from('posts').select();
  expect(posts.length, 2);
  expect(posts.every((p) => p['id'] != 2), true);
});
```

**Delete All Records**:

```dart
test('delete all records', () async {
  await mockSupabase.from('posts').insert([
    {'id': 1, 'title': 'Post 1'},
    {'id': 2, 'title': 'Post 2'},
  ]);

  await mockSupabase.from('posts').delete();

  final posts = await mockSupabase.from('posts').select();
  expect(posts.isEmpty, true);
});
```

## Advanced Querying

### Filtering

**Equality Filter (`.eq()`)**:

```dart
test('filter with eq', () async {
  await mockSupabase.from('posts').insert([
    {'id': 1, 'status': 'draft'},
    {'id': 2, 'status': 'published'},
    {'id': 3, 'status': 'draft'},
  ]);

  final drafts = await mockSupabase
      .from('posts')
      .select()
      .eq('status', 'draft');

  expect(drafts.length, 2);
});
```

**Greater Than (`.gt()`)**:

```dart
test('filter with gt', () async {
  await mockSupabase.from('posts').insert([
    {'id': 1, 'views': 10},
    {'id': 2, 'views': 50},
    {'id': 3, 'views': 100},
  ]);

  final popular = await mockSupabase
      .from('posts')
      .select()
      .gt('views', 25);

  expect(popular.length, 2);
  expect(popular.every((p) => p['views'] > 25), true);
});
```

**Less Than (`.lt()`)**:

```dart
test('filter with lt', () async {
  await mockSupabase.from('posts').insert([
    {'id': 1, 'views': 10},
    {'id': 2, 'views': 50},
    {'id': 3, 'views': 100},
  ]);

  final lowViews = await mockSupabase
      .from('posts')
      .select()
      .lt('views', 75);

  expect(lowViews.length, 2);
});
```

**Multiple Filters**:

```dart
test('combine multiple filters', () async {
  await mockSupabase.from('posts').insert([
    {'id': 1, 'status': 'published', 'views': 100},
    {'id': 2, 'status': 'published', 'views': 50},
    {'id': 3, 'status': 'draft', 'views': 150},
  ]);

  final filtered = await mockSupabase
      .from('posts')
      .select()
      .eq('status', 'published')
      .gt('views', 75);

  expect(filtered.length, 1);
  expect(filtered.first['id'], 1);
});
```

### Ordering

**Order Ascending**:

```dart
test('order by ascending', () async {
  await mockSupabase.from('posts').insert([
    {'id': 3, 'title': 'C'},
    {'id': 1, 'title': 'A'},
    {'id': 2, 'title': 'B'},
  ]);

  final ordered = await mockSupabase
      .from('posts')
      .select()
      .order('id', ascending: true);

  expect(ordered[0]['id'], 1);
  expect(ordered[1]['id'], 2);
  expect(ordered[2]['id'], 3);
});
```

**Order Descending**:

```dart
test('order by descending', () async {
  await mockSupabase.from('posts').insert([
    {'id': 1, 'views': 50},
    {'id': 2, 'views': 200},
    {'id': 3, 'views': 100},
  ]);

  final ordered = await mockSupabase
      .from('posts')
      .select()
      .order('views', ascending: false);

  expect(ordered[0]['views'], 200);
  expect(ordered[1]['views'], 100);
  expect(ordered[2]['views'], 50);
});
```

### Limiting Results

```dart
test('limit results', () async {
  await mockSupabase.from('posts').insert([
    {'id': 1, 'title': 'Post 1'},
    {'id': 2, 'title': 'Post 2'},
    {'id': 3, 'title': 'Post 3'},
    {'id': 4, 'title': 'Post 4'},
    {'id': 5, 'title': 'Post 5'},
  ]);

  final limited = await mockSupabase
      .from('posts')
      .select()
      .limit(3);

  expect(limited.length, 3);
});
```

### Combining Operations

```dart
test('filter, order, and limit', () async {
  await mockSupabase.from('posts').insert([
    {'id': 1, 'category': 'tech', 'views': 100},
    {'id': 2, 'category': 'tech', 'views': 200},
    {'id': 3, 'category': 'news', 'views': 300},
    {'id': 4, 'category': 'tech', 'views': 50},
    {'id': 5, 'category': 'tech', 'views': 150},
  ]);

  final topTechPosts = await mockSupabase
      .from('posts')
      .select()
      .eq('category', 'tech')
      .order('views', ascending: false)
      .limit(2);

  expect(topTechPosts.length, 2);
  expect(topTechPosts[0]['views'], 200);
  expect(topTechPosts[1]['views'], 150);
});
```

## Provider Testing

### Testing Riverpod Providers

**Simple Provider Test**:

```dart
// Provider definition
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final postsCountProvider = FutureProvider<int>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final posts = await supabase.from('posts').select();
  return posts.length;
});

// Test
test('posts count provider returns correct count', () async {
  final mockHttpClient = MockSupabaseHttpClient();
  final mockSupabase = SupabaseClient(
    'https://mock.supabase.co',
    'fakeAnonKey',
    httpClient: mockHttpClient,
  );

  await mockSupabase.from('posts').insert([
    {'id': 1, 'title': 'Post 1'},
    {'id': 2, 'title': 'Post 2'},
    {'id': 3, 'title': 'Post 3'},
  ]);

  final container = ProviderContainer(
    overrides: [
      supabaseProvider.overrideWithValue(mockSupabase),
    ],
  );

  final count = await container.read(postsCountProvider.future);
  expect(count, 3);
});
```

**Notifier Provider Test**:

```dart
// Notifier definition
@riverpod
class PostsNotifier extends _$PostsNotifier {
  @override
  Future<List<Post>> build() async {
    final supabase = ref.watch(supabaseProvider);
    final data = await supabase.from('posts').select();
    return data.map((json) => Post.fromJson(json)).toList();
  }

  Future<void> addPost(Post post) async {
    final supabase = ref.watch(supabaseProvider);
    await supabase.from('posts').insert(post.toJson());
    ref.invalidateSelf();
  }
}

// Test
test('posts notifier adds post', () async {
  final mockHttpClient = MockSupabaseHttpClient();
  final mockSupabase = SupabaseClient(
    'https://mock.supabase.co',
    'fakeAnonKey',
    httpClient: mockHttpClient,
  );

  final container = ProviderContainer(
    overrides: [
      supabaseProvider.overrideWithValue(mockSupabase),
    ],
  );

  final notifier = container.read(postsNotifierProvider.notifier);

  // Add post
  await notifier.addPost(Post(id: 1, title: 'New Post'));

  // Verify
  final posts = await container.read(postsNotifierProvider.future);
  expect(posts.length, 1);
  expect(posts.first.title, 'New Post');
});
```

## Widget Testing

### Basic Widget Test with Mock Supabase

```dart
testWidgets('displays posts from Supabase', (WidgetTester tester) async {
  final mockHttpClient = MockSupabaseHttpClient();
  final mockSupabase = SupabaseClient(
    'https://mock.supabase.co',
    'fakeAnonKey',
    httpClient: mockHttpClient,
  );

  // Setup test data
  await mockSupabase.from('posts').insert([
    {'id': 1, 'title': 'First Post'},
    {'id': 2, 'title': 'Second Post'},
  ]);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supabaseProvider.overrideWithValue(mockSupabase),
      ],
      child: const MaterialApp(
        home: PostsListScreen(),
      ),
    ),
  );

  // Wait for async operations
  await tester.pumpAndSettle();

  // Verify UI
  expect(find.text('First Post'), findsOneWidget);
  expect(find.text('Second Post'), findsOneWidget);
});
```

### Testing User Interactions

```dart
testWidgets('user can add new post', (WidgetTester tester) async {
  final mockHttpClient = MockSupabaseHttpClient();
  final mockSupabase = SupabaseClient(
    'https://mock.supabase.co',
    'fakeAnonKey',
    httpClient: mockHttpClient,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supabaseProvider.overrideWithValue(mockSupabase),
      ],
      child: const MaterialApp(
        home: CreatePostScreen(),
      ),
    ),
  );

  // Enter post title
  await tester.enterText(
    find.byType(TextField),
    'My New Post',
  );

  // Tap submit button
  await tester.tap(find.text('Submit'));
  await tester.pumpAndSettle();

  // Verify post was added to mock database
  final posts = await mockSupabase.from('posts').select();
  expect(posts.length, 1);
  expect(posts.first['title'], 'My New Post');
});
```

## Integration Testing

### Integration Test Setup

```dart
// integration_test/supabase_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mock_supabase_http_client/mock_supabase_http_client.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Post Management Flow', () {
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

    testWidgets('complete post creation and display flow', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseProvider.overrideWithValue(mockSupabase),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to create post screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(find.byKey(Key('title_field')), 'Test Post');
      await tester.enterText(find.byKey(Key('content_field')), 'Content');

      // Submit
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Verify navigation back to list
      expect(find.text('Test Post'), findsOneWidget);

      // Verify in database
      final posts = await mockSupabase.from('posts').select();
      expect(posts.length, 1);
    });
  });
}
```

## Edge Functions and RPC

### Mocking Edge Functions

```dart
test('mock edge function', () async {
  mockHttpClient.registerEdgeFunction(
    'send_notification',
    (body, queryParams, method, tables) {
      return FunctionResponse(
        data: {
          'success': true,
          'message': 'Notification sent to ${body['email']}',
          'id': 'notif_123',
        },
        status: 200,
      );
    },
  );

  final response = await mockSupabase.functions.invoke(
    'send_notification',
    body: {
      'email': 'user@example.com',
      'message': 'Hello!',
    },
  );

  expect(response.status, 200);
  expect(response.data['success'], true);
  expect(response.data['id'], 'notif_123');
});
```

### Mocking RPC Functions

```dart
test('mock RPC function', () async {
  mockHttpClient.registerRpcFunction(
    'calculate_stats',
    (params, tables) {
      final userId = params['user_id'] as int;
      // Access mock data via tables parameter
      final userPosts = tables['posts']
          ?.where((p) => p['user_id'] == userId)
          .toList() ?? [];

      return {
        'total_posts': userPosts.length,
        'total_views': userPosts.fold<int>(
          0,
          (sum, post) => sum + (post['views'] as int? ?? 0),
        ),
      };
    },
  );

  // Insert test data
  await mockSupabase.from('posts').insert([
    {'id': 1, 'user_id': 1, 'views': 100},
    {'id': 2, 'user_id': 1, 'views': 200},
    {'id': 3, 'user_id': 2, 'views': 50},
  ]);

  final stats = await mockSupabase.rpc(
    'calculate_stats',
    params: {'user_id': 1},
  );

  expect(stats['total_posts'], 2);
  expect(stats['total_views'], 300);
});
```

## Error Simulation

### Simulating Database Errors

```dart
test('handle duplicate key error', () async {
  final mockHttpClient = MockSupabaseHttpClient(
    postgrestExceptionTrigger: (schema, table, data, type) {
      if (table == 'posts' && type == RequestType.insert) {
        final id = data is Map ? data['id'] : null;
        if (id == 1) {
          throw PostgrestException(
            message: 'duplicate key value violates unique constraint',
            code: '23505',
          );
        }
      }
    },
  );

  final mockSupabase = SupabaseClient(
    'https://mock.supabase.co',
    'fakeAnonKey',
    httpClient: mockHttpClient,
  );

  // First insert succeeds
  await mockSupabase.from('posts').insert({'id': 2, 'title': 'Post 2'});

  // Second insert with id=1 throws error
  expect(
    () => mockSupabase.from('posts').insert({'id': 1, 'title': 'Post 1'}),
    throwsA(isA<PostgrestException>()),
  );
});
```

### Testing Error Handling in Providers

```dart
test('provider handles database errors', () async {
  final mockHttpClient = MockSupabaseHttpClient(
    postgrestExceptionTrigger: (schema, table, data, type) {
      throw PostgrestException(
        message: 'Connection timeout',
        code: '08000',
      );
    },
  );

  final mockSupabase = SupabaseClient(
    'https://mock.supabase.co',
    'fakeAnonKey',
    httpClient: mockHttpClient,
  );

  final container = ProviderContainer(
    overrides: [
      supabaseProvider.overrideWithValue(mockSupabase),
    ],
  );

  final asyncValue = container.read(postsProvider);

  expect(asyncValue, isA<AsyncError>());
  expect(asyncValue.error, isA<PostgrestException>());
});
```

## Test Data Patterns

### Factory Pattern

```dart
class PostFactory {
  static Map<String, dynamic> createPost({
    int id = 1,
    String title = 'Test Post',
    String content = 'Test content',
    int userId = 1,
    bool published = true,
    DateTime? createdAt,
  }) {
    return {
      'id': id,
      'title': title,
      'content': content,
      'user_id': userId,
      'published': published,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
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

  static Map<String, dynamic> createPopularPost({int id = 1}) {
    return createPost(id: id)..['views'] = 1000;
  }
}
```

### Builder Pattern

```dart
class PostBuilder {
  int _id = 1;
  String _title = 'Test Post';
  String? _content;
  int _userId = 1;
  bool _published = true;
  int _views = 0;

  PostBuilder withId(int id) {
    _id = id;
    return this;
  }

  PostBuilder withTitle(String title) {
    _title = title;
    return this;
  }

  PostBuilder withContent(String content) {
    _content = content;
    return this;
  }

  PostBuilder withUserId(int userId) {
    _userId = userId;
    return this;
  }

  PostBuilder published() {
    _published = true;
    return this;
  }

  PostBuilder draft() {
    _published = false;
    return this;
  }

  PostBuilder withViews(int views) {
    _views = views;
    return this;
  }

  Map<String, dynamic> build() {
    return {
      'id': _id,
      'title': _title,
      if (_content != null) 'content': _content,
      'user_id': _userId,
      'published': _published,
      'views': _views,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}

// Usage
test('builder pattern example', () async {
  await mockSupabase.from('posts').insert(
    PostBuilder()
        .withId(1)
        .withTitle('My Post')
        .draft()
        .withViews(50)
        .build(),
  );

  final posts = await mockSupabase.from('posts').select();
  expect(posts.first['published'], false);
  expect(posts.first['views'], 50);
});
```

## Best Practices

### 1. Isolate Tests

```dart
// ✅ Good: Each test is independent
test('test A', () async {
  await mockSupabase.from('posts').insert({'id': 1, 'title': 'A'});
  final posts = await mockSupabase.from('posts').select();
  expect(posts.length, 1);
});

test('test B', () async {
  // tearDown() was called, data is cleared
  await mockSupabase.from('posts').insert({'id': 1, 'title': 'B'});
  final posts = await mockSupabase.from('posts').select();
  expect(posts.length, 1); // Still passes
});
```

### 2. Use Test Fixtures

```dart
// Create fixtures directory
// test/fixtures/post_fixtures.dart

class PostFixtures {
  static const Map<String, dynamic> samplePost = {
    'id': 1,
    'title': 'Sample Post',
    'content': 'Sample content',
    'user_id': 1,
  };

  static const List<Map<String, dynamic>> samplePosts = [
    {'id': 1, 'title': 'Post 1', 'user_id': 1},
    {'id': 2, 'title': 'Post 2', 'user_id': 1},
    {'id': 3, 'title': 'Post 3', 'user_id': 2},
  ];
}

// Use in tests
test('with fixtures', () async {
  await mockSupabase.from('posts').insert(PostFixtures.samplePosts);
  final posts = await mockSupabase.from('posts').select();
  expect(posts.length, 3);
});
```

### 3. Group Related Tests

```dart
group('Post CRUD Operations', () {
  group('Create', () {
    test('creates single post', () async { /* ... */ });
    test('creates multiple posts', () async { /* ... */ });
    test('handles duplicate IDs', () async { /* ... */ });
  });

  group('Read', () {
    test('reads all posts', () async { /* ... */ });
    test('filters by user', () async { /* ... */ });
    test('orders by date', () async { /* ... */ });
  });

  group('Update', () {
    test('updates single post', () async { /* ... */ });
    test('updates with filter', () async { /* ... */ });
  });

  group('Delete', () {
    test('deletes single post', () async { /* ... */ });
    test('deletes with filter', () async { /* ... */ });
  });
});
```

### 4. Descriptive Test Names

```dart
// ❌ Bad: Vague test name
test('test posts', () async { /* ... */ });

// ✅ Good: Clear test name
test('fetches published posts ordered by creation date descending', () async {
  /* ... */
});
```

### 5. Arrange-Act-Assert Pattern

```dart
test('deletes post when user is author', () async {
  // Arrange: Setup test data
  await mockSupabase.from('posts').insert({
    'id': 1,
    'title': 'My Post',
    'author_id': 123,
  });

  // Act: Perform the operation
  await mockSupabase
      .from('posts')
      .delete()
      .eq('id', 1)
      .eq('author_id', 123);

  // Assert: Verify the result
  final posts = await mockSupabase.from('posts').select();
  expect(posts.isEmpty, true);
});
```

## Limitations and Workarounds

### Authentication Not Supported

**Workaround**: Use Fake classes

```dart
import 'package:flutter_test/flutter_test.dart';

class FakeGoTrueClient extends Fake implements GoTrueClient {
  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = User(
      id: 'test-user-id',
      email: email,
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

    return AuthResponse(
      user: _currentUser,
      session: Session(
        accessToken: 'fake-access-token',
        tokenType: 'Bearer',
        expiresIn: 3600,
      ),
    );
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<UserResponse> getUser() async {
    if (_currentUser == null) {
      throw AuthException('User not authenticated');
    }
    return UserResponse(user: _currentUser);
  }
}

// Compose with MockSupabaseHttpClient
class TestSupabaseClient implements SupabaseClient {
  final SupabaseClient _dbClient;
  final GoTrueClient _authClient;

  TestSupabaseClient(this._dbClient, this._authClient);

  @override
  GoTrueClient get auth => _authClient;

  @override
  PostgrestClient from(String table) => _dbClient.from(table);

  // Implement other methods as needed...
}

// Usage in tests
test('authenticated user can create post', () async {
  final mockHttpClient = MockSupabaseHttpClient();
  final mockDbClient = SupabaseClient(
    'https://mock.supabase.co',
    'fakeAnonKey',
    httpClient: mockHttpClient,
  );
  final fakeAuth = FakeGoTrueClient();
  final testClient = TestSupabaseClient(mockDbClient, fakeAuth);

  // Sign in
  await testClient.auth.signInWithPassword(
    email: 'test@example.com',
    password: 'password',
  );

  // Create post
  final user = testClient.auth.currentUser!;
  await mockDbClient.from('posts').insert({
    'id': 1,
    'title': 'My Post',
    'user_id': user.id,
  });

  final posts = await mockDbClient.from('posts').select();
  expect(posts.first['user_id'], user.id);
});
```

### Realtime Not Supported

**Workaround**: Use Mockito or manual stream

```dart
import 'package:mockito/mockito.dart';

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

test('listens to post changes', () async {
  final mockChannel = MockRealtimeChannel();
  final postStream = Stream.fromIterable([
    RealtimeMessage(
      event: 'INSERT',
      payload: {'id': 1, 'title': 'New Post'},
    ),
  ]);

  when(mockChannel.stream()).thenAnswer((_) => postStream);

  // Test your realtime handling logic
  await for (final message in mockChannel.stream()) {
    expect(message.payload['title'], 'New Post');
  }
});
```

### Storage Not Supported

**Workaround**: Use Fake storage client

```dart
class FakeStorageFileApi extends Fake implements StorageFileApi {
  final Map<String, Uint8List> _files = {};

  @override
  Future<String> upload(
    String path,
    File file, {
    FileOptions? fileOptions,
  }) async {
    _files[path] = await file.readAsBytes();
    return 'public/$path';
  }

  @override
  Future<Uint8List> download(String path) async {
    if (!_files.containsKey(path)) {
      throw StorageException('File not found');
    }
    return _files[path]!;
  }

  @override
  Future<List<FileObject>> list({String? path}) async {
    return _files.keys
        .where((key) => path == null || key.startsWith(path))
        .map((key) => FileObject(
              name: key,
              id: key,
              updatedAt: DateTime.now().toIso8601String(),
              createdAt: DateTime.now().toIso8601String(),
              lastAccessedAt: DateTime.now().toIso8601String(),
              bucketId: 'test-bucket',
            ))
        .toList();
  }
}
```

## Troubleshooting

### Tests Fail Due to Shared State

**Problem**: Tests pass individually but fail when run together.

**Solution**: Ensure `tearDown()` calls `mockHttpClient.reset()`:

```dart
tearDown(() {
  mockHttpClient.reset();
});
```

### Provider Tests Show Stale Data

**Problem**: Provider caches data from previous tests.

**Solution**: Dispose container after each test:

```dart
test('provider test', () async {
  final container = ProviderContainer(/* ... */);
  addTearDown(container.dispose);

  // Your test...
});
```

### Widget Tests Don't Update UI

**Problem**: UI doesn't reflect database changes.

**Solution**: Call `pumpAndSettle()` after async operations:

```dart
await tester.tap(find.text('Refresh'));
await tester.pumpAndSettle(); // Wait for async operations
expect(find.text('Updated Data'), findsOneWidget);
```

### Mock Data Persists Between Test Files

**Problem**: Data from one test file appears in another.

**Solution**: Each test file should create its own `MockSupabaseHttpClient`:

```dart
// Don't share mockHttpClient across files
void main() {
  late MockSupabaseHttpClient mockHttpClient; // Scoped to this file

  setUpAll(() {
    mockHttpClient = MockSupabaseHttpClient();
  });
}
```

### Complex Queries Not Working

**Problem**: Advanced filters or joins don't work as expected.

**Solution**: Check package limitations. For complex queries, insert the exact expected result:

```dart
// Instead of complex join query
test('get posts with author names', () async {
  // Insert denormalized data directly
  await mockSupabase.from('posts').insert({
    'id': 1,
    'title': 'Post',
    'author': {'id': 1, 'name': 'John'}, // Nested data
  });

  final posts = await mockSupabase.from('posts').select('*, author:author_id(*)');
  expect(posts.first['author']['name'], 'John');
});
```

## Related Documentation

- **CLAUDE.md**: "Supabase Mocking" section for project integration
- **AGENTS.md**: "Supabase テスト要件" for TDD workflow
- **testing-guide.md**: General testing architecture and patterns
- [mock_supabase_http_client on pub.dev](https://pub.dev/packages/mock_supabase_http_client)
- [Supabase Flutter Documentation](https://supabase.com/docs/reference/dart/introduction)

## Summary

The `mock_supabase_http_client` package enables comprehensive testing of Supabase integrations in Flutter applications:

- ✅ **Fast**: No network calls, tests run in milliseconds
- ✅ **Deterministic**: Full control over test data and scenarios
- ✅ **Isolated**: Each test is independent with clean state
- ✅ **Comprehensive**: Supports CRUD, filtering, Edge Functions, RPC, and error scenarios

For unsupported features (Auth, Realtime, Storage), use Fake classes or Mockito to complement the mock client.

**Remember**: Always follow TDD principles—write tests first, then implement functionality. This ensures your code is testable and meets requirements from the start.
