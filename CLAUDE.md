# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## MCP (Model Context Protocol) Tool Usage Guidelines

### IMPORTANT: Actively Use MCP Tools for Specialized Tasks

Claude Code has access to specialized MCP tools that should be actively utilized for efficient and accurate development:

#### 1. Context7 MCP for Professional Research

- **ALWAYS use Context7 MCP** for researching technical topics, best practices, and implementation patterns
- Use for investigating new libraries, frameworks, or architectural patterns
- Leverage for understanding complex technical concepts before implementation
- Essential for staying current with latest development practices

#### 2. Dart/Flutter MCP for Implementation

- **ALWAYS use Dart MCP** when implementing Flutter/Dart code
- Use for:
  - Widget implementation patterns and best practices
  - State management with Riverpod
  - Flutter-specific optimizations and performance tips
  - Dart language features and idioms
  - Package recommendations and usage patterns
- Consult before writing any Flutter/Dart code to ensure idiomatic implementation

#### 3. Supabase MCP for Database Operations

- **ALWAYS use Supabase MCP** for:
  - Checking existing table structures before modifications
  - Understanding relationships and constraints
  - Verifying RLS (Row Level Security) policies
  - Reviewing indexes and performance considerations
  - Planning migrations and schema changes
- Never modify database schema without first checking current structure via Supabase MCP

#### 4. IDE MCP for Code Intelligence

- **Use IDE MCP** (`mcp__ide__`) for:
  - Getting diagnostics and error information
  - Executing code in Jupyter notebooks
  - Understanding current IDE state and issues

### MCP Usage Protocol

1. **Before Implementation**: Always check relevant MCP tools first
2. **During Development**: Continuously consult MCP tools for validation
3. **After Changes**: Use MCP tools to verify correctness
4. **Documentation**: Reference MCP tool findings in code comments when relevant

### Example Workflow

```
User Request → Analyze with Context7 → Check Supabase structure →
Consult Dart MCP for patterns → Implement → Verify with IDE MCP
```

## Architecture Overview

This is a full-stack application boilerplate with Flutter frontend, Python backend, and Supabase Edge Functions:

### Backend as a Service Strategy

- **Frontend-First Approach**: Frontend leverages Supabase client directly for authentication, authorization, and database operations to maximize BaaS characteristics
- **Edge Functions Priority**: Backend implementations should default to Edge Functions unless specifically requiring Python capabilities
- **Python Backend Scope**: Reserved for transaction-heavy operations and Python-specific implementations, using SQLModel for database interactions

### Frontend Architecture (Monorepo)

- **Monorepo Structure**: Managed with Melos for efficient multi-package development
  - `apps/web/`: Main web application (FSD structure maintained)
  - `packages/core/api/`: HTTP client with Dio + Retrofit for type-safe API integration
  - `packages/core/auth/`: Authentication state management and utilities
  - `packages/core/i18n/`: Internationalization system (slang)
  - `packages/core/utils/`: Core utilities (logger, constants)
  - `packages/shared/ui/`: Shared UI components across apps
- **Flutter Application**: Multi-platform support (iOS, Android, Web)
- **Feature Sliced Design**: Strict adherence to FSD methodology with ui/model/api segments in apps/
- **State Management**: Riverpod with hooks for reactive state management
- **Navigation**: GoRouter with authentication-aware declarative routing
- **Backend Integration**: Primary use of Supabase Flutter client for authentication, authorization, and database operations
- **Direct Database Access**: Frontend directly communicates with Supabase for CRUD operations, real-time subscriptions, and RLS policies
- **Internationalization (i18n)**: Type-safe multilingual support using slang package with extensible architecture (in core_i18n package)

### Edge Functions (Supabase)

- **Primary Backend**: Default choice for backend implementations unless Python-specific features are required
- **Deno Runtime**: TypeScript edge functions in `supabase/functions/`
- **Generated Types**: Database types from `domain/entity/__generated__/schema.ts`
- **Supabase Client**: Direct database access with type safety
- **Use Cases**: Business logic, webhooks, real-time processing, serverless APIs, external integrations
- **AI Integration**: Mastra, multiple LLM providers, vector search capabilities
- **Lightweight Operations**: Ideal for stateless operations and simple business logic

### Backend Architecture (Python)

- **Python FastAPI**: Located in `backend-py/app/` with layered architecture
- **Main Entry Point**: `app.py` with FastAPI configuration and middleware
- **Specific Use Cases**: Complex transactions, Python-specific libraries, heavy computational tasks, batch processing
- **Database Integration**: SQLModel for type-safe database operations with synchronous sessions
- **Layered Architecture**:
  - Controllers (`controller/`): HTTP endpoints and request/response handling
  - Use Cases (`usecase/`): Service layer (application services)
  - Services (`domain/service/`): Domain services (business logic)
  - Gateways (`gateway/`): Data access layer and repository interfaces with synchronous session management
  - Infrastructure (`infra/`): External service integrations
- **AI Integration**: LangChain, OpenAI, Anthropic, Perplexity, Google AI providers
- **WebRTC Support**: aiortc, LiveKit for real-time communication
- **Transaction Support**: Complex database transactions and data consistency requirements

### Database Design

- **Supabase PostgreSQL**: Primary database with real-time subscriptions
- **SQLModel (Python Backend)**: Type-safe ORM with synchronous database operations for Python backend
- **Drizzle ORM**: TypeScript-first ORM for schema management, migrations, and Edge Functions:
  - Schema files in `drizzle/schema/`: TypeScript-based declarative schema definition
  - Migrations in `supabase/migrations/`: Auto-generated SQL migration files
  - Type-safe database operations with full TypeScript inference
  - Drizzle Studio for visual database management
  - Custom SQL support via `drizzle/config/` for functions, triggers, and extensions

## Development Commands

### Initial Setup

```bash
make init                    # Full project initialization (installs dependencies, sets up DB)
```

### Running Services

```bash
make run                     # Start backend services with Docker + Supabase
make frontend                # Start Flutter web development (port 8080) - includes bootstrap
make frontend-ios            # Start iOS development
make frontend-android        # Start Android development
make stop                   # Stop all services
```

### Frontend Monorepo Commands (Melos)

```bash
make frontend-bootstrap                # Setup workspace and link packages
make frontend-generate                 # Run code generation (Riverpod, Drift)
make frontend-clean                    # Clean all packages
make frontend-test                     # Run unit and widget tests for all packages
make frontend-integration-test         # Run integration tests (デバイス/シミュレータ必要)
make frontend-integration-test-web     # Run web integration tests (デバイス必要)
make frontend-integration-test-web-drive # Run web integration tests with flutter drive (ChromeDriver必要)
make frontend-test-all                 # Run all tests (unit, widget, integration)
make frontend-quality-check            # Run all quality checks
```

### Database Operations (Drizzle)

```bash
# Migration commands
make migrate-dev            # Generate migrations, push schema, execute custom SQL, generate types (local only)
make migrate-deploy         # Apply existing migrations (all environments)
make migrate-status         # Show migration history
make drizzle-studio        # Open Drizzle Studio (visual DB management)

# Legacy commands (deprecated, use migrate-dev instead)
make migration             # Alias for migrate-dev
make init-migration        # Alias for migrate-dev

# Database management
make seed                  # Manual seed implementation required
make db-reset              # Reset database to clean state (local only)
```

**Drizzle Workflow:**

1. **Development (`make migrate-dev`)**:
   - Sets up PostgreSQL extensions (vector, etc.) before migrations
   - Generates migration files from schema changes
   - Applies migrations to local Supabase database
   - Executes custom SQL (functions, triggers)
   - Generates type definitions for Edge Functions
2. **Production (`make migrate-deploy`)**:
   - Sets up PostgreSQL extensions first
   - Applies existing migrations
   - Executes custom SQL (functions, triggers)
   - Suitable for staging/production environments
3. **Drizzle Studio (`make drizzle-studio`)**:
   - Visual database browser at http://localhost:4983
   - Query data, inspect schema, manage records

### Model Generation

```bash
make build-model                        # Generate Edge Functions models only
make build-model-functions              # Generate types for edge functions
```

**Frontend Model Strategy:**
- Frontend models are **manually created using Freezed** for type-safe immutable data classes
- No automatic type generation from database schema
- Use `build_runner` to generate Freezed code along with Riverpod and i18n

### Code Generation (Flutter)

```bash
# Generate Freezed models, Riverpod providers, and i18n translations
make frontend-generate                              # Generate all code (Freezed, Riverpod, Drift)
cd frontend/apps/web && flutter pub run build_runner build --delete-conflicting-outputs  # Force regeneration
cd frontend/apps/web && flutter pub run build_runner watch  # Watch mode for development
```

**Generated Code Types:**
- **Freezed**: Immutable data classes with copyWith, equality, serialization
- **Riverpod**: State management providers and notifiers
- **i18n**: Type-safe translations with slang
- **Drift**: SQLite database models (if used)

**IMPORTANT**: Always use `make frontend` for development server startup instead of direct `flutter run` commands. The make command ensures:

- Proper Melos bootstrap
- Correct environment variable loading
- Consistent port configuration (8080)
- Proper working directory setup

### Testing Commands

```bash
# Comprehensive testing
make test-all                      # Run all tests (unit, widget, integration) across all components

# Frontend testing
make frontend-test                 # Run unit and widget tests only
make frontend-integration-test     # Run integration tests for all apps
make frontend-integration-test-web # Run integration tests for web app
make frontend-test-all             # Run all frontend tests (unit, widget, integration)
```

**Test Types**:
- **Unit Tests**: Test individual functions and classes in isolation
- **Widget Tests**: Test Flutter widgets and UI components
- **Integration Tests**: Test complete user flows end-to-end with navigation and state

Note: `make test-all` includes unit, widget, and integration tests for Flutter, plus tests for Edge Functions and Backend when available.

### Quality Checks & Formatting

```bash
# Quality check commands
make check-quality          # Run all quality checks
make check-flutter         # Flutter-specific checks (analyze, test)
make check-edge-functions   # Edge Functions-specific checks
make check-backend         # Backend-specific checks (ruff)

# Code formatting commands
make fix-format            # Auto-fix all code formatting
make fix-format-flutter    # Auto-fix Flutter formatting only
make fix-format-edge-functions # Auto-fix Edge Functions formatting only
make fix-format-backend    # Auto-fix Backend formatting only

# Hook commands for file-specific checks
make hook-dart-check FILE_PATH=<path>    # Run Dart checks for specific file
make hook-python-check FILE_PATH=<path>  # Run Python checks for specific file
```

**IMPORTANT: Generated Files Handling**

Auto-generated files are automatically excluded from formatting checks:

- `*.g.dart` - build_runner, Riverpod, json_serializable
- `*.freezed.dart` - freezed
- `*.gr.dart` - auto_route
- `*/generated/*` - all files in generated directories
- `*/.dart_tool/*` - Dart tool cache
- `*/build/*` - build artifacts

The formatting commands automatically filter out these patterns, so generated files will not cause CI failures or require manual formatting.

### Deployment Commands

```bash
make deploy-functions  # Deploy all edge functions to Supabase
```

## Environment Configuration

Environment files in `env/` directory:

- `env/secrets.env` - Copy from `env/secrets.env.example` and configure
- `env/frontend/local.json` - Flutter environment configuration
- `env/migration/local.env` - Database migration settings

### Required Environment Variables

Key services requiring API keys:

- OpenAI, Anthropic, Perplexity, Google AI (LLM providers)
- Replicate, FAL (Image generation)
- Cartesia (Voice services)
- Supabase URL and keys

## Frontend Architecture Details

### State Management

- **Riverpod**: Primary state management solution with `riverpod_generator`
- **Flutter Hooks**: For component-level state and lifecycle
- **Providers**: Generated using `riverpod_generator` with annotations

### Data Modeling

- **Freezed**: Primary solution for immutable data classes
  - Type-safe model classes with built-in equality and copyWith
  - JSON serialization/deserialization support
  - Union types and sealed classes for state modeling
  - Generated code via `build_runner`
- **Manual Creation**: All domain models are manually defined, not auto-generated from database schema
- **Best Practices**:
  - Use `@freezed` annotation for immutable models
  - Add `@JsonSerializable()` for API/database integration
  - Define models in the `model/` segment of FSD structure
  - Run `flutter pub run build_runner build` after model changes

### Server-Sent Events (SSE)

- **Library**: Always use `flutter_client_sse` through the wrapper in `frontend/packages/core/api/lib/realtime/sse_client_factory.dart`
- **Access Pattern**:
  - Import `package:core_api/core_api.dart`
  - Obtain `SseClientFactory` via `ref.read(sseClientFactoryProvider)`
  - Call `factory.connect(...)` to receive an `SseConnection` with `messages` and `rawEvents` streams
- **Configuration**:
  - `SSE_SERVER_URL` and `SSE_DEBUG_KEY` are provided via `--dart-define` / `String.fromEnvironment`
  - Default headers are merged automatically; pass feature-specific headers through `connect(headers: ...)`
- **Restrictions**:
  - Do **not** instantiate `SSEClient` directly; the wrapper ensures consistent headers, logging, and lifecycle control
  - Use `SseConnection.close()` (which delegates to `SSEClient.unsubscribeFromSSE()`) when the stream is no longer needed

### Navigation Architecture

- **Implementation**: GoRouter with authentication-aware routing
  - Declarative routing with type-safe navigation
  - Deep linking support
  - Authentication guards and automatic redirects
  - Route-level access control based on auth state
  - Enhanced navigation methods (`context.go()`, `context.push()`, `context.pop()`)
- **Router Configuration**: Located in `app/router/app_router.dart` using Riverpod for state integration
- **Authentication Flow**:
  - Unauthenticated users → redirect to `/auth/login`
  - Authenticated users → redirect from auth routes to `/dashboard`
  - Real-time route protection based on auth state changes

### Feature Structure (Feature Sliced Design)

```
lib/
├── app/           # App-level configuration
├── entities/      # Shared business entities
│   └── counter/
│       ├── api/   # Entity API layer
│       ├── model/ # Entity models and domain logic
│       └── ui/    # Reusable entity UI components
├── features/      # Feature modules
│   └── counter/
│       ├── api/   # Feature-specific API integrations
│       ├── model/ # Feature state management and business logic
│       └── ui/    # Feature UI components
├── pages/         # Route-level pages
└── shared/        # Shared utilities and components
```

**FSD Segment Rules**:

- **api/**: External API integrations, data fetching
- **model/**: State management, business logic, domain services
- **ui/**: UI components, widgets, presentation layer

**Note**: The `entities/` layer typically contains only the `model/` segment, as entities represent pure domain models without direct API or UI concerns. The `api/` and `ui/` segments are more commonly found in `features/` layer where complete feature implementations reside.

### Internationalization (i18n) Architecture

The project implements a type-safe, extensible multilingual system using the **slang** package, structured as a core package (`packages/core/i18n/`):

#### Core Components

- **Translation Files**: JSON-based translations in `frontend/packages/core/i18n/lib/translations/`

  - `en.i18n.json`: English (default/base language)
  - `ja.i18n.json`: Japanese translations
  - Additional languages: `[locale].i18n.json`

- **Generated Code**: Type-safe translation classes via `flutter pub run build_runner build`
  - Located in `frontend/packages/core/i18n/lib/generated/`
  - `strings.g.dart`: Main generated translation file
  - `strings_en.g.dart`, `strings_ja.g.dart`: Locale-specific implementations

#### Key Features

- **Type Safety**: Compile-time checking prevents missing translations and typos
- **Performance**: Zero-parsing runtime with native Dart method calls
- **Extensibility**: Easy addition of new languages through configuration
- **Rich Content**: Support for pluralization, parameters, and rich text
- **State Management**: Riverpod integration for reactive language switching
- **Persistence**: SharedPreferences for language preference storage

#### Architecture Components

```
frontend/packages/core/i18n/lib/
├── translations/                # Translation source files
│   ├── en.i18n.json            # English translations (base)
│   └── ja.i18n.json            # Japanese translations
├── generated/                   # Auto-generated by build_runner
│   ├── strings.g.dart          # Main generated file
│   ├── strings_en.g.dart       # Generated English
│   └── strings_ja.g.dart       # Generated Japanese
├── locale/                      # Locale configuration
│   └── supported_locales.dart  # Locale metadata (flags, names)
├── providers/                   # State management
│   ├── locale_provider.dart    # Riverpod locale provider
│   └── locale_provider.g.dart  # Generated provider
└── widgets/                     # UI components
    └── language_selector_widget.dart  # Language selector UI
```

#### Usage Patterns

**Basic Translation Access**:

```dart
// Import from the core_i18n package
import 'package:core_i18n/generated/strings.g.dart';

// Type-safe access to translations
Text(t.home.title)              // "Flutter Demo Home Page" / "Flutter デモホームページ"
Text(t.counter.increment)       // "Increment" / "増やす"
```

**Parameterized Translations**:

```dart
// With parameters
Text(t.welcome.message(name: userName))  // "Hello John!" / "こんにちは、Johnさん！"
```

**Language Management**:

```dart
// Import the locale provider
import 'package:core_i18n/providers/locale_provider.dart';

// Access locale state
final localeNotifier = ref.read(localeNotifierProvider.notifier);
final currentLocale = ref.watch(localeNotifierProvider);

// Change language
localeNotifier.changeLocale(AppLocale.ja);
localeNotifier.toggleLocale();  // Cycle through available languages
```

#### Adding New Languages

1. **Create Translation File**: Add `[locale].i18n.json` in `frontend/packages/core/i18n/lib/translations/`
2. **Update Configuration**: Add locale info to `frontend/packages/core/i18n/lib/locale/supported_locales.dart`
3. **Regenerate Code**: Run `cd frontend && flutter pub run build_runner build` or `make frontend-generate`

Example for French:

```dart
// In frontend/packages/core/i18n/lib/locale/supported_locales.dart
LocaleInfo(
  locale: AppLocale.fr,
  displayName: 'French',
  nativeName: 'Français',
  flag: '🇫🇷',
),
```

#### Translation Structure

Organize translations hierarchically by feature/domain:

```json
{
  "app": { "title": "...", "name": "..." },
  "home": { "title": "...", "message": "..." },
  "counter": {
    "increment": "...",
    "tooltip": { "increment": "...", "decrement": "..." },
    "value": { "zero": "...", "other": "..." }
  },
  "common": { "save": "...", "cancel": "...", "loading": "..." },
  "settings": { "language": "...", "changeLanguage": "..." }
}
```

#### Best Practices

- **Consistent Keys**: Use consistent naming across all language files
- **Contextual Organization**: Group translations by feature/screen for maintainability
- **Pluralization**: Use slang's built-in pluralization for count-dependent text
- **Rich Text**: Leverage slang's rich text support for formatted content
- **Fallbacks**: Always provide fallback values for missing translations
- **Testing**: Test language switching and translation completeness

#### Development Workflow

1. **Add/Modify Translations**: Update JSON files in `packages/core/i18n/lib/translations/`
2. **Regenerate Types**: `cd frontend && flutter pub run build_runner build --delete-conflicting-outputs` or `make frontend-generate`
3. **Use Type-Safe Access**: Import from `package:core_i18n/generated/strings.g.dart` and access via `t.` prefix with IDE autocomplete
4. **Test Languages**: Use `LanguageSelectorWidget` from `package:core_i18n/widgets/language_selector_widget.dart` for runtime testing

### Testing Architecture

The project follows a Test-Driven Development (TDD) approach with comprehensive testing across the monorepo structure.

#### Test Structure and Organization

**Monorepo Test Structure**:

```
frontend/
├── apps/web/test/           # Application-level tests
│   ├── widget_test.dart     # Widget and integration tests
│   └── ...
├── packages/core/api/test/  # Core API package tests
├── packages/core/auth/test/ # Authentication tests
└── ...
```

#### Test File Conventions

- **Test Files**: Must end with `_test.dart` suffix
- **Location**: Place test files in `test/` directory at the same level as `lib/`
- **Naming**: Mirror the structure of `lib/` in `test/` directory
  - Example: `lib/features/counter/model/counter_provider.dart` → `test/features/counter/model/counter_provider_test.dart`

#### Running Tests

**Melos Commands** (recommended for monorepo):

```bash
# Run all tests across packages
cd frontend && melos run test

# Run tests with coverage
cd frontend && melos run test_coverage

# Run tests for specific package
cd frontend/apps/web && flutter test

# Watch mode for TDD
cd frontend/apps/web && flutter test --watch
```

**Make Commands**:

```bash
make frontend-test           # Run tests for all frontend packages
make test-all               # Run tests for all components (Flutter, Edge Functions, Backend)
make check-flutter          # Run Flutter checks including tests
```

#### Test Directory Management

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

#### Test Coverage Requirements

- **New Features**: Minimum 90% test coverage required
- **Modified Code**: Include regression tests for existing functionality
- **Critical Paths**: 100% coverage for authentication, payments, data integrity

#### Test Types

**Widget Tests** (most common):

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

**Unit Tests** (for business logic):

```dart
test('Counter provider increments value', () {
  final container = ProviderContainer();
  final counter = container.read(counterProvider.notifier);

  expect(container.read(counterProvider), 0);
  counter.increment();
  expect(container.read(counterProvider), 1);
});
```

**Integration Tests** (for user flows):

- Located in `integration_test/` directory at app level
- Test complete user journeys end-to-end
- Run actual app code with real dependencies (or mocked external services)
- Verify full feature workflows including navigation, state management, and UI interactions

**Integration Test Directory Structure**:

```
frontend/apps/web/
├── lib/
├── test/                    # Unit and widget tests
├── test_driver/             # Web環境用ドライバー（flutter drive用）
│   └── integration_test.dart
└── integration_test/        # Integration tests
    ├── README.md            # テスト実行ガイド
    ├── app_test.dart        # Basic app launch and initialization
    ├── navigation_test.dart # GoRouter navigation flows
    └── auth_flow_test.dart  # Authentication workflows
```

**Running Integration Tests**:

統合テストの実行方法はプラットフォームによって異なります：

**デスクトップ/モバイルデバイス（macOS, iOS, Android）**:

```bash
# すべての統合テストを実行（デバイスを指定）
flutter test integration_test/ -d macos
flutter test integration_test/ -d ios
flutter test integration_test/ -d android

# 特定のテストファイルを実行
cd frontend/apps/web && flutter test integration_test/app_test.dart -d macos

# Makeコマンド（利用可能なデバイスで実行）
make frontend-integration-test
```

**Web環境（Chrome）**:

⚠️ **重要**: Web環境では`flutter test`コマンドは使用できません。代わりに`flutter drive`を使用します。

```bash
# 前提条件: ChromeDriverを起動
npx @puppeteer/browsers install chromedriver@stable
chromedriver --port=4444  # 別のターミナルで実行

# Web統合テストを実行
cd frontend/apps/web && flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d chrome
```

**すべてのテストを実行**:

```bash
# ユニット、ウィジェット、統合テストすべて
make frontend-test-all
cd frontend && melos run test_all

# 全コンポーネントのテスト（Flutter + Edge Functions + Backend）
make test-all
```

**Integration Test Best Practices**:

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

**Example Integration Test**:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:web_app/app/app.dart';
import 'package:core_i18n/core_i18n.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Flow Integration Test', () {
    testWidgets('Complete login workflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: const App(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to login
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');

      // Submit login
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify navigation to dashboard
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
```

**Supabase Authentication Testing**:

For testing Supabase authentication flows, create a `FakeSupabaseClient`:

```dart
class FakeSupabaseClient extends Fake implements SupabaseClient {
  @override
  late final GoTrueClient auth = FakeGoTrueClient();
}

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
}
```

**Platform-Specific Considerations**:

| Platform | Command | Requirements |
|----------|---------|--------------|
| **macOS** | `flutter test integration_test/ -d macos` | macOS環境、CocoaPods最新版 |
| **iOS** | `flutter test integration_test/ -d ios` | Xcode、iOSシミュレータまたはデバイス |
| **Android** | `flutter test integration_test/ -d android` | Android SDK、エミュレータまたはデバイス |
| **Web** | `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d chrome` | ChromeDriver起動が必須 |

**CI/CD Integration Test Execution**:

Add integration tests to GitHub Actions workflow:

```yaml
# デスクトップ/モバイル環境
- name: Run integration tests
  working-directory: frontend
  run: melos run integration_test

# Web環境（ChromeDriverが必要）
- name: Setup ChromeDriver
  run: |
    npx @puppeteer/browsers install chromedriver@stable
    chromedriver --port=4444 &

- name: Run Web integration tests
  working-directory: frontend/apps/web
  run: |
    flutter drive \
      --driver=test_driver/integration_test.dart \
      --target=integration_test/app_test.dart \
      -d web-server
```

#### Supabase Mocking

**Package**: `mock_supabase_http_client`

This project uses the `mock_supabase_http_client` package to test Supabase integrations without making actual network calls. The package provides an in-memory HTTP client that intercepts Supabase requests and returns mock data.

**Installation**: Already included in `frontend/pubspec.yaml` dev_dependencies. All workspace packages can use it.

**Basic Setup**:

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
    mockHttpClient.reset(); // Clear data between tests
  });

  tearDownAll(() {
    mockHttpClient.close();
  });

  // Tests...
}
```

**CRUD Operations**:

```dart
test('insert and select data', () async {
  // Insert test data
  await mockSupabase.from('posts').insert({
    'id': 1,
    'title': 'Test Post',
    'content': 'Hello, World!',
  });

  // Query data
  final posts = await mockSupabase.from('posts').select();

  expect(posts.length, 1);
  expect(posts.first['title'], 'Test Post');
});

test('update and delete operations', () async {
  await mockSupabase.from('posts').insert({'id': 1, 'title': 'Old'});

  await mockSupabase
      .from('posts')
      .update({'title': 'New'})
      .eq('id', 1);

  final updated = await mockSupabase.from('posts').select();
  expect(updated.first['title'], 'New');

  await mockSupabase.from('posts').delete().eq('id', 1);
  final deleted = await mockSupabase.from('posts').select();
  expect(deleted.isEmpty, true);
});
```

**Using with Riverpod Providers**:

```dart
// Define Supabase provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Test with mocked Supabase
test('provider test with mock supabase', () async {
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

  // Test your provider logic
  final posts = await container.read(postsProvider.future);
  expect(posts.length, 2);
});
```

**Test Data Factories** (Best Practice):

```dart
class PostFactory {
  static Map<String, dynamic> createPost({
    int id = 1,
    String title = 'Test Post',
    int userId = 1,
  }) {
    return {
      'id': id,
      'title': title,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static List<Map<String, dynamic>> createPostList(int count) {
    return List.generate(
      count,
      (i) => createPost(id: i + 1, title: 'Post ${i + 1}'),
    );
  }
}

// Usage
test('display multiple posts', () async {
  await mockSupabase.from('posts').insert(
    PostFactory.createPostList(5),
  );

  final posts = await mockSupabase.from('posts').select();
  expect(posts.length, 5);
});
```

**Limitations and Workarounds**:

- ✅ **Supported**: CRUD operations, filtering, ordering, basic relations, Edge Functions, RPC
- ❌ **Not Supported**: Authentication, Realtime subscriptions, Storage operations

For unsupported features, use Fake classes:

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
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  @override
  late final GoTrueClient auth = FakeGoTrueClient();

  // Use MockSupabaseHttpClient for database operations
  // Use Fake for auth/realtime/storage
}
```

**See also**: `.agent/rules/supabase-testing.md` for comprehensive testing guide.

#### Testing with Riverpod

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

#### CI/CD Integration

Tests run automatically in GitHub Actions:

- **Lint & Format Check**: `make check-flutter` includes analysis
- **Type Check**: Runs after code generation
- **Test Flutter**: Dedicated job for running all tests

**CI Test Execution**:

```yaml
- name: Bootstrap Flutter workspace
  working-directory: frontend
  run: melos bootstrap

- name: Generate Flutter code
  working-directory: frontend/apps/web
  run: dart run build_runner build --delete-conflicting-outputs

- name: Run Flutter tests
  working-directory: frontend
  run: melos run test
```

#### Best Practices

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

#### Troubleshooting

**Test not found errors**:

```bash
# Regenerate code if providers are missing
cd frontend && flutter pub run build_runner build --delete-conflicting-outputs

# Clean and rebuild
cd frontend && melos clean && melos bootstrap
```

**Async test timeouts**:

- Increase timeout: `test('...', timeout: Timeout(Duration(seconds: 30)))`
- Use `tester.pumpAndSettle()` for animations
- Check for infinite loops or missing completers

**Widget not found**:

- Verify widget is built: `await tester.pumpWidget()`
- Check visibility: widget might be scrolled out of view
- Use `find.byType()` instead of `find.text()` for dynamic content

## Backend Python Architecture

### Application Structure

- **Main Entry**: `app.py` configures FastAPI with CORS middleware and router aggregation
- **Router Organization**: All routers aggregated in `controller/__init__.py`
- **Environment**: UTC timezone, environment variable loading at startup

### Layered Architecture with Separation of Concerns

- **Controller Layer**: HTTP endpoints and request/response handling
  - Each domain has its own controller module with dedicated router
  - Endpoints use kebab-case paths with RESTful conventions
  - Authentication via `Depends(verify_token)` middleware
- **Use Case Layer**: Application services (service layer)
  - Business logic orchestration
  - Transaction management
- **Service Layer**: Domain services with business logic
  - Pure business rules
  - Domain-specific operations
- **Gateway Layer**: Data access interfaces and repository pattern
  - Repository implementations using SQLModel with synchronous sessions
  - Database transaction handling with synchronous context managers
- **Infrastructure Layer**: External service implementations
  - Client wrappers for external services (Supabase, LLMs)
  - Factory patterns for service selection
  - Environment configuration management
- **Middleware**: Authentication and request processing
  - JWT token verification via Supabase

### Coding Standards (Python)

- **Type Safety**: Strict type annotations with type hints required
- **Database Operations**: Synchronous database operations with SQLModel
- **Error Handling**: Domain exceptions translated to HTTP responses
- **Code Quality**: Ruff linting with formatting (88 char limit)
- **Function Complexity**: Maximum McCabe complexity of 3

## Edge Functions Architecture

Serverless functions with Deno runtime:

- **Type Safety**: Dual type system for flexibility
  - Drizzle ORM types: For direct database operations and transactions
  - Supabase-generated types: For supabase-js client operations (Auth, Storage, Realtime)
- **Database Access**:
  - **Drizzle ORM**: Type-safe direct database queries with `getDb()` from `@infra/database`
  - **Supabase Client**: For Auth, Storage, Realtime, and RPC operations
- **Function Structure**: Each function in separate directory under `supabase/functions/`
- **Shared Code**:
  - Drizzle schema from `drizzle/schema/` (imported with extensions)
  - Supabase types in `domain/entity/__generated__/schema.ts`
- **CORS Headers**: Must be properly configured for all functions
- **Error Handling**: Comprehensive error scenarios with proper status codes

## Development Workflow

### Standard Development Process with MCP Tools

1. **Research Phase**: Use Context7 MCP to research best practices and patterns
2. **Database Check**: Use Supabase MCP to verify current local database schema before modifications
3. **Implementation**:
   - Flutter/Dart: Consult Dart MCP for idiomatic patterns
   - Edge Functions: Reference TypeScript best practices via Context7
   - Python Backend: Use Context7 for FastAPI patterns
4. **Code Generation**: Use `make` commands for type safety (Riverpod, Drift)
5. **Schema Migration**: Use Atlas for declarative schema management and migrations
6. **Verification**: Use IDE MCP to check for diagnostics and errors
7. **Quality Checks**: Run component-specific checks before commits

### MCP-Enhanced Development Flow

#### For Flutter/Dart Development:

```
1. Supabase MCP → Check local database schema
2. Dart MCP → Get widget/state management patterns
3. Implement code following FSD structure (create Freezed models manually)
4. flutter pub run build_runner build → Generate code (Freezed/Riverpod/i18n)
5. IDE MCP → Verify no errors
6. make check-flutter → Quality assurance
```

#### For Database Changes (Drizzle):

```
1. Supabase MCP → Analyze current local database schema
2. Context7 → Research migration best practices with Drizzle
3. Update drizzle/schema/*.ts files (TypeScript schema definition)
4. make migrate-dev → Generate migrations, push to local DB, execute custom SQL, generate types
5. Supabase MCP → Verify changes in local database
6. make drizzle-studio → Visually inspect changes (optional)
```

#### For Edge Functions:

```
1. Supabase MCP → Check available tables/views in local database
2. Context7 → Research Deno/TypeScript patterns
3. Implement function
4. IDE MCP → Check for type errors
5. make check-edge-functions → Validate
```

### Testing Workflow

1. Write tests first (TDD approach)
2. Use Context7 MCP to research testing patterns
3. Run tests with appropriate make commands
4. Ensure 90%+ test coverage for new features
5. Include regression tests for existing functionality

## AI Development & Quality Assurance

### Mandatory Post-Modification Workflow

When Claude Code makes any changes:

1. **Identify Modified Component**: Determine which component was changed
2. **Run Component-Specific Checks**:
   - Frontend: `flutter pub run build_runner build && make fix-format-flutter && make check-flutter`
   - Edge Functions: `make fix-format-edge-functions && make check-edge-functions`
   - Backend: `make fix-format-backend && make check-backend`
   - Multiple: `flutter pub run build_runner build && make fix-format && make check-quality`
3. **Fix Any Issues**: Never proceed with failing checks
4. **Manual Review**: Human verification before commit

### Test-Driven Development (TDD) Requirements

**Mandatory TDD Workflow** for all development:

1. Write comprehensive test cases first
2. Follow Red-Green-Refactor cycle
3. Include regression tests when modifying existing code
4. Verify with quality checks after implementation

### Quality Gates

**Pre-commit Requirements**:

- All quality checks must pass
- Test coverage ≥ 90% for modified components
- No formatting issues
- No type errors or linting warnings

**If Quality Checks Fail**:

- Fix issues immediately
- Focus on the specific component that was modified
- Re-run checks until all pass
- Never commit failing code

### High-Risk Operations

For changes to:

- Database schema or migrations
- Authentication/authorization
- API contracts
- Payment processing

**Additional Requirements**:

- Comprehensive testing including edge cases
- Load testing for performance-critical paths
- Documented rollback plan
- Staged rollout strategy

## Emergency Procedures

### Database Rollback

```bash
make rollback              # Rollback last migration
make db-reset             # Reset to clean state (development only)
```

### Service Recovery

- Check Docker container status: `docker ps`
- Restart services: `make stop && make run`
- Check logs: `docker logs <container_name>`

## Important Conventions

### MCP Tool Usage Examples

#### When Adding a New Feature:

```
1. Context7: "Flutter best practices for implementing infinite scroll with Riverpod"
2. Supabase MCP: Check 'posts' table structure and indexes in local database
3. Dart MCP: "How to implement infinite scroll with Riverpod and pagination"
4. Implement following the guidance
5. IDE MCP: Check for any diagnostics
```

#### When Modifying Database:

```
1. Supabase MCP: "Show me the current local schema for user_profiles table"
2. Context7: "PostgreSQL best practices for adding JSON columns"
3. Create migration with proper rollback strategy
4. Supabase MCP: "Verify the migration will not break existing queries in local database"
```

#### When Creating Edge Functions:

```
1. Supabase MCP: "List all tables accessible from edge functions in local database"
2. Context7: "Deno best practices for handling CORS in Supabase functions"
3. Implement with proper error handling
4. Test with curl commands
```

### Code Style

- **Flutter**: Follow Dart conventions, use trailing commas, consult Dart MCP for idioms
- **Python**: PEP 8 with Black formatting, type hints required
- **TypeScript**: Standard JS/TS conventions for Edge Functions
- **SQL**: Lowercase keywords, snake_case naming

### Git Workflow

- Feature branches from `main`
- Conventional commits (feat:, fix:, docs:, etc.)
- PR required for main branch
- All CI checks must pass

### Security

- Never commit secrets or API keys
- Use environment variables for configuration
- Follow principle of least privilege for database access
- Implement proper input validation and sanitization
- Always verify RLS policies via Supabase MCP before deployment

### MCP Tool Priority

**ALWAYS prioritize MCP tools over general knowledge:**

1. **Supabase MCP** > General database assumptions
2. **Dart MCP** > Generic Flutter patterns
3. **Context7** > Outdated documentation or practices
4. **IDE MCP** > Manual error checking

**Remember**: This is a production-ready boilerplate. Always use MCP tools for accurate, up-to-date information. Maintain high code quality, comprehensive testing, and proper documentation for all changes.
