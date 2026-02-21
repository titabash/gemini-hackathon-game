# Frontend Architecture Details

## State Management

- **Riverpod**: Primary state management solution with `riverpod_generator`
- **Flutter Hooks**: For component-level state and lifecycle
- **Providers**: Generated using `riverpod_generator` with annotations

## Data Modeling

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

## Server-Sent Events (SSE)

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

## Navigation Architecture

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

## Feature Structure (Feature Sliced Design)

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

## Internationalization (i18n) Architecture

The project implements a type-safe, extensible multilingual system using the **slang** package, structured as a core package (`packages/core/i18n/`).

### Core Components

- **Translation Files**: JSON-based translations in `frontend/packages/core/i18n/lib/translations/`
  - `en.i18n.json`: English (default/base language)
  - `ja.i18n.json`: Japanese translations
  - Additional languages: `[locale].i18n.json`

- **Generated Code**: Type-safe translation classes via `flutter pub run build_runner build`
  - Located in `frontend/packages/core/i18n/lib/generated/`
  - `strings.g.dart`: Main generated translation file
  - `strings_en.g.dart`, `strings_ja.g.dart`: Locale-specific implementations

### Key Features

- **Type Safety**: Compile-time checking prevents missing translations and typos
- **Performance**: Zero-parsing runtime with native Dart method calls
- **Extensibility**: Easy addition of new languages through configuration
- **Rich Content**: Support for pluralization, parameters, and rich text
- **State Management**: Riverpod integration for reactive language switching
- **Persistence**: SharedPreferences for language preference storage

### Usage Patterns

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

### Adding New Languages

1. **Create Translation File**: Add `[locale].i18n.json` in `frontend/packages/core/i18n/lib/translations/`
2. **Update Configuration**: Add locale info to `frontend/packages/core/i18n/lib/locale/supported_locales.dart`
3. **Regenerate Code**: Run `cd frontend && flutter pub run build_runner build` or `make frontend-generate`

### Translation Structure

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

### Best Practices

- **Consistent Keys**: Use consistent naming across all language files
- **Contextual Organization**: Group translations by feature/screen for maintainability
- **Pluralization**: Use slang's built-in pluralization for count-dependent text
- **Rich Text**: Leverage slang's rich text support for formatted content
- **Fallbacks**: Always provide fallback values for missing translations
- **Testing**: Test language switching and translation completeness
