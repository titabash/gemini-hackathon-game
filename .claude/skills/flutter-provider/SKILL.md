---
name: flutter-provider
description: Create type-safe Riverpod providers with code generation. Use when implementing state management with AsyncNotifier, FutureProvider, or StreamProvider patterns.
---

# Flutter Provider Creation Skill

Create type-safe Riverpod providers with code generation for state management.

## Task

You will create Riverpod providers using `riverpod_annotation` for:
- Synchronous state (simple values)
- Asynchronous state (Future/Stream)
- Stateful notifiers (mutable state with actions)
- Family providers (parameterized providers)

## Implementation Steps

1. **Gather Requirements**:
   - Ask what kind of provider is needed (simple, async, notifier, family)
   - Ask what data/state it should manage
   - Ask if it depends on other providers
   - Ask where it should be located (feature, entity, or core package)

2. **Create Provider File**:
   - Location: `{package}/lib/{layer}/{name}_provider.dart`
   - Use `riverpod_annotation` package
   - Add appropriate part directive

3. **Implement Provider**:
   - Use `@riverpod` annotation
   - Define provider function or class
   - Add dependencies using `ref.watch()` or `ref.read()`

4. **Run Code Generation**:
   ```bash
   cd frontend
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Verify Generated Files**:
   - Check for `.g.dart` file with provider definitions

6. **Quality Checks**:
   ```bash
   make check-flutter
   ```

## Provider Types & Examples

### 1. Simple Provider (Synchronous)

For simple values or synchronous computations:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'config_provider.g.dart';

/// App configuration provider
@riverpod
AppConfig appConfig(Ref ref) {
  return const AppConfig(
    apiBaseUrl: 'https://api.example.com',
    timeout: Duration(seconds: 30),
  );
}
```

### 2. Async Provider (Future)

For asynchronous data fetching:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core_api/core_api.dart';

part 'user_provider.g.dart';

/// Fetch user profile by ID
@riverpod
Future<UserProfile> userProfile(Ref ref, String userId) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getUserProfile(userId);
}

/// Fetch all users
@riverpod
Future<List<User>> users(Ref ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getUsers();
}
```

### 3. Stream Provider

For real-time data streams:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'notification_stream_provider.g.dart';

/// Stream of real-time notifications
@riverpod
Stream<List<Notification>> notificationStream(Ref ref, String userId) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => Notification.fromJson(json)).toList());
}
```

### 4. Notifier Provider (Stateful with Actions)

For mutable state with business logic:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_provider.g.dart';

/// Counter state notifier
@riverpod
class Counter extends _$Counter {
  @override
  int build() {
    // Initial state
    return 0;
  }

  void increment() {
    state = state + 1;
  }

  void decrement() {
    state = state - 1;
  }

  void reset() {
    state = 0;
  }
}
```

### 5. Async Notifier Provider

For async operations with mutable state:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:core_api/core_api.dart';

part 'checkout_provider.g.dart';

/// Checkout creation notifier
@riverpod
class CheckoutCreator extends _$CheckoutCreator {
  @override
  FutureOr<Checkout?> build() {
    // Initial state (no checkout)
    return null;
  }

  Future<void> createCheckout({
    required String productId,
    required String productPriceId,
  }) async {
    // Set loading state
    state = const AsyncValue.loading();

    // Execute async operation
    state = await AsyncValue.guard(() async {
      final apiClient = ref.read(polarApiClientProvider);
      return await apiClient.createCheckout(
        productId: productId,
        productPriceId: productPriceId,
      );
    });
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}
```

### 6. Family Provider (Parameterized)

For providers that take parameters:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'product_provider.g.dart';

/// Fetch product by ID
@riverpod
Future<Product> product(Ref ref, String productId) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getProduct(productId);
}

/// Usage:
/// ref.watch(productProvider('product-123'))
```

### 7. KeepAlive Provider

For caching data that should not be disposed:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// Auth state provider (kept alive)
@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  @override
  Future<User?> build() async {
    final supabase = Supabase.instance.client;
    return supabase.auth.currentUser;
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    });
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    state = const AsyncValue.data(null);
  }
}
```

## Usage Examples

### Watching Providers in Widgets:

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch async provider
    final profileAsync = ref.watch(userProfileProvider('user-123'));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        data: (profile) => ProfileContent(profile: profile),
        loading: () => const CircularProgressIndicator(),
        error: (error, stack) => Text('Error: $error'),
      ),
    );
  }
}
```

### Using Notifier Actions:

```dart
class CounterScreen extends ConsumerWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch counter state
    final count = ref.watch(counterProvider);

    return Column(
      children: [
        Text('Count: $count'),
        ElevatedButton(
          // Call notifier action
          onPressed: () => ref.read(counterProvider.notifier).increment(),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

### Listening to State Changes:

```dart
class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to state changes
    ref.listen<AsyncValue<Checkout?>>(
      checkoutCreatorProvider,
      (previous, next) {
        next.when(
          data: (checkout) {
            if (checkout != null) {
              // Navigate to checkout page
              context.go('/checkout/${checkout.id}');
            }
          },
          loading: () {},
          error: (error, _) {
            // Show error snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $error')),
            );
          },
        );
      },
    );

    // ...rest of widget
  }
}
```

## Best Practices

1. **Provider Location**:
   - Feature providers: `apps/web/lib/features/{feature}/model/`
   - Entity providers: `apps/web/lib/entities/{entity}/model/`
   - Core providers: `packages/core/{package}/lib/providers/`

2. **Naming Conventions**:
   - Provider file: `{name}_provider.dart`
   - Provider function: `{name}` (e.g., `userProfile`)
   - Notifier class: `{Name}` (e.g., `CheckoutCreator`)
   - Generated provider: `{name}Provider` (e.g., `userProfileProvider`)

3. **Dependencies**:
   - Use `ref.watch()` for reactive dependencies
   - Use `ref.read()` for one-time reads (in methods)
   - Use `ref.listen()` for side effects

4. **State Management**:
   - Use simple provider for immutable state
   - Use notifier for mutable state with actions
   - Use `AsyncValue` for async operations
   - Use `.when()` for pattern matching async states

5. **Error Handling**:
   - Always use `AsyncValue.guard()` for async operations
   - Handle errors in UI with `.when(error: ...)`
   - Log errors for debugging

6. **Performance**:
   - Use `keepAlive: true` for expensive computations
   - Use family providers for parameterized data
   - Avoid watching providers in loops

## Common Pitfalls

- ❌ Don't forget `part` directive
- ❌ Don't forget to run code generation
- ❌ Don't use `ref.read()` in build methods (use `ref.watch()`)
- ❌ Don't mutate state directly (use notifier methods)
- ❌ Don't create circular dependencies between providers
- ❌ Don't forget to handle loading and error states

## Code Generation Issues

If generation fails:

1. **Check analysis_options.yaml**:
   ```yaml
   errors:
     undefined_class: ignore  # For Riverpod Ref types
   ```

2. **Regenerate**:
   ```bash
   cd frontend
   dart run build_runner clean
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **Check for errors**:
   ```bash
   make check-flutter
   ```

## Notes

- Riverpod with code generation is the standard for this project
- Always use `riverpod_annotation` instead of manual provider creation
- See existing providers in `packages/core/polar/lib/providers/` for reference
- Check CLAUDE.md for state management architecture guidelines
