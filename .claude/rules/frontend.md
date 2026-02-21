---
paths: frontend/**/*.dart
---

# Frontend Code Standards (Flutter)

## Architecture

- **Pattern**: Feature Sliced Design (FSD)
- **State Management**: Riverpod (riverpod_generator) + Flutter Hooks
- **Navigation**: GoRouter (authentication-aware routing)
- **Data Models**: Freezed (immutable models)
- **HTTP Client**: Dio + Retrofit (type-safe API)
- **i18n**: slang (type-safe translations)
- **Logging**: logger package (colorful, structured)

## Platform Support

| Platform | Support | Notes |
|----------|---------|-------|
| **Web** | ✅ | Primary development target |
| **iOS** | ✅ | Supported |
| **Android** | ✅ | Supported |

## Monorepo Structure (Melos)

このプロジェクトは **Melos** によるモノレポ構成：

```
frontend/
├── apps/
│   └── web/              # Main Flutter application
│       ├── lib/
│       │   ├── app/      # Application layer (router, app widget)
│       │   ├── pages/    # Pages layer (route-level pages)
│       │   ├── features/ # Features layer (business features)
│       │   ├── entities/ # Entities layer (business entities)
│       │   └── shared/   # Shared layer (utilities, config)
│       ├── test/         # Unit & Widget tests
│       └── integration_test/  # Integration tests
│
└── packages/
    ├── core/
    │   ├── api/          # HTTP client (Dio + Retrofit, SSE)
    │   ├── auth/         # Authentication (Supabase)
    │   ├── i18n/         # Internationalization (slang)
    │   ├── polar/        # Polar.sh payment integration
    │   ├── notification/ # OneSignal push notifications
    │   └── utils/        # Core utilities (Logger, constants)
    └── shared/
        └── ui/           # Shared UI components
```

## DRY Principle (MANDATORY)

**重複実装は徹底的に排除し、コードをクリーンに保つ。**

### 共通化の原則

| 対象 | 配置場所 | 例 |
|------|---------|-----|
| **共有UIコンポーネント** | `packages/shared/ui/` | CustomButton, CustomCard |
| **HTTP クライアント** | `packages/core/api/` | Dio, Retrofit, SSE |
| **認証ロジック** | `packages/core/auth/` | Supabase Client, Auth Provider |
| **国際化** | `packages/core/i18n/` | slang translations |
| **決済統合** | `packages/core/polar/` | Polar.sh client, providers |
| **通知統合** | `packages/core/notification/` | OneSignal integration |
| **ユーティリティ** | `packages/core/utils/` | Logger, constants |
| **型定義（Freezed）** | 各feature/entityの`model/` | User, Product |

### 禁止事項

```dart
// ❌ Bad: 各feature で同じロジックを実装
// features/auth/model/login_provider.dart
// features/profile/model/profile_provider.dart (同じSupabase呼び出し)

// ✅ Good: core packages で共通化
// packages/core/auth/lib/providers/auth_provider.dart
import 'package:core_auth/providers/auth_provider.dart';
```

```dart
// ❌ Bad: HTTP クライアントを各featureで個別定義
class AuthApi {
  final dio = Dio();  // 個別インスタンス
}

// ✅ Good: core packages で共通化
import 'package:core_api/clients/backend_api_client.dart';

@riverpod
BackendApiClient backendApiClient(BackendApiClientRef ref) {
  return ref.watch(backendApiClientProvider);
}
```

### チェックリスト

新しいコードを書く前に確認：

1. **既存の packages に同様の機能があるか？** → あれば再利用
2. **他の feature でも使う可能性があるか？** → あれば packages に実装
3. **ビジネスロジックが重複していないか？** → 共通化を検討
4. **Riverpod Provider が重複していないか？** → 共通 Provider を使用

## Code Style

- **Linting**: Dart analyzer with `analysis_options.yaml`
- **Formatting**: `dart format` (Dart 標準フォーマッター)
- **Indentation**: 2 spaces
- **Line Width**: 80 characters (Dart 標準)
- **Trailing Commas**: 必須（フォーマット向上）

## Import Organization

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:convert';

// 2. Flutter framework
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. External packages (pub.dev)
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:go_router/go_router.dart';

// 4. Core packages
import 'package:core_api/core_api.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_i18n/core_i18n.dart';

// 5. Shared packages
import 'package:shared_ui/shared_ui.dart';

// 6. FSD layers (top to bottom) - relative imports
import '../../features/auth/auth.dart';
import '../../entities/user/user.dart';
import '../../shared/config/config.dart';

// 7. Generated files
part 'login_provider.g.dart';
part 'login_state.freezed.dart';
```

## Feature Sliced Design (FSD) Rules

### Layers

```
app → pages → features → entities → shared
(上位 → 下位へのみインポート可能)
```

### Segments

各レイヤー内は以下のセグメントで構成：

- `ui/` - Flutter Widgets (presentation)
- `model/` - Riverpod Providers, business logic
- `api/` - External API integrations, data fetching

### Public API Pattern

各 feature/entity は Public API (`index.dart`) を定義：

```dart
// features/auth/index.dart
export 'model/auth_provider.dart';
export 'model/auth_state.dart';
export 'ui/login_form.dart';

// ❌ 内部実装を公開しない
// export 'model/auth_provider.g.dart';  // 自動生成
// export 'ui/widgets/login_button.dart';  // 内部Widget
```

## Riverpod Best Practices

### Provider定義

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_provider.g.dart';

// StateProvider相当（シンプルな状態）
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
}

// AsyncNotifierProvider相当（非同期状態）
@riverpod
class User extends _$User {
  @override
  Future<UserModel?> build() async {
    final supabase = ref.read(supabaseClientProvider);
    final currentUser = await supabase.auth.currentUser;

    if (currentUser == null) return null;

    final data = await supabase
        .from('users')
        .select()
        .eq('id', currentUser.id)
        .single();

    return UserModel.fromJson(data);
  }

  Future<void> updateName(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('users').update({'name': name});
      return build();  // 再取得
    });
  }
}
```

### Provider使用

```dart
class CounterWidget extends ConsumerWidget {
  const CounterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 値の読み取り
    final count = ref.watch(counterProvider);

    // Notifierの取得（メソッド呼び出し用）
    final counterNotifier = ref.read(counterProvider.notifier);

    return Column(
      children: [
        Text('Count: $count'),
        ElevatedButton(
          onPressed: () => counterNotifier.increment(),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

## Freezed Models

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    String? email,
    @Default(false) bool isActive,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// 使用例
final user = User(id: '1', name: 'Alice');
final updated = user.copyWith(name: 'Bob');  // イミュータブル
```

## GoRouter Navigation

```dart
import 'package:go_router/go_router.dart';

// ルート定義（app/router/app_router.dart）
@riverpod
GoRouter goRouter(GoRouterRef ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
        redirect: (context, state) {
          if (authState.value == null) return '/auth/login';
          return null;
        },
      ),
    ],
    redirect: (context, state) {
      final isAuth = authState.value != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuth && !isAuthRoute) return '/auth/login';
      if (isAuth && isAuthRoute) return '/dashboard';
      return null;
    },
  );
}

// ナビゲーション
context.go('/dashboard');
context.push('/settings');
context.pop();
```

## Widget Composition

```dart
// ✅ Good: Small, focused widgets
class UserAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null ? Text(name[0]) : null,
    );
  }
}

// ❌ Bad: Monolithic widget
class UserPage extends StatelessWidget {
  // 200+ lines of build method
}
```

## Testing Guidelines

### Unit Tests (Riverpod Providers)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('Counter increments', () {
    final container = ProviderContainer();
    final counter = container.read(counterProvider.notifier);

    expect(container.read(counterProvider), 0);
    counter.increment();
    expect(container.read(counterProvider), 1);

    container.dispose();
  });
}
```

### Widget Tests

```dart
testWidgets('Login form validates email', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: LoginForm(),
      ),
    ),
  );

  await tester.enterText(find.byType(TextField).first, 'invalid-email');
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();

  expect(find.text('Invalid email'), findsOneWidget);
});
```

## Logging

アプリケーションログは `Logger` クラスを使用する。詳細は `.claude/rules/logging.md` を参照。

```dart
import 'package:core_utils/core_utils.dart';

// ✅ Good: Logger を使用
Logger.info('User logged in');
Logger.debug('Fetching data: $id');
Logger.error('Failed to fetch data', error, stackTrace);

// ❌ Bad: print/debugPrint を直接使用
print('Debug message');
debugPrint('[ERROR] $message');
```

## Enforcement

このフロントエンド規約は **NON-NEGOTIABLE**。規約に違反するコードは却下される。
