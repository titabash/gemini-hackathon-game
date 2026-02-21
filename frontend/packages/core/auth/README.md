# core_auth

Core authentication package for Flutter Boilerplate.

## Features

- **OTP Authentication**: Passwordless authentication using email OTP
- **State Management**: Riverpod-based authentication state management
- **Real-time Sync**: Automatic synchronization with Supabase auth state
- **Type-safe**: Freezed models for immutable state
- **Result Pattern**: Error handling with AuthResult type

## Usage

### 1. Setup AuthListener

Wrap your app with `AuthListener` to monitor authentication state:

```dart
class App extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthListener(
      child: MaterialApp(
        home: HomePage(),
      ),
    );
  }
}
```

### 2. Access Authentication State

```dart
// Get current auth state
final authState = ref.watch(authProvider);
final isAuthenticated = authState.isAuthenticated;
final user = authState.user;

// Or use convenience providers
final isAuth = ref.watch(isAuthenticatedProvider);
final currentUser = ref.watch(currentUserProvider);
```

### 3. Perform Authentication

```dart
final authService = AuthService(ref.read(authClientProvider));

// Send OTP
final result = await authService.signInWithOtp(
  email: 'user@example.com',
);

result.when(
  success: (_) => print('OTP sent!'),
  failure: (error) => print('Error: ${error.message}'),
);

// Verify OTP
final verifyResult = await authService.verifyOtp(
  email: 'user@example.com',
  token: '123456',
);
```

### 4. Sign Out

```dart
await ref.read(authProvider.notifier).signOut();
```

## Architecture

This package follows the architecture from the reference Next.js project:

- **AuthState**: Similar to Zustand store state
- **AuthProvider**: Similar to Next.js AuthProvider
- **AuthListener**: Similar to useEffect auth state subscription
- **AuthService**: Similar to Server Actions for auth operations

## Dependencies

- `supabase_flutter`: Supabase client
- `riverpod_annotation`: State management
- `freezed`: Immutable models
