# Development Workflow

This document describes the daily development workflow and best practices in flutter-boilerplate.

## Table of Contents

- [Development Environment Setup](#development-environment-setup)
- [Daily Development Flow](#daily-development-flow)
- [Monorepo Development](#monorepo-development)
- [Feature Development Workflow](#feature-development-workflow)
- [Database Development](#database-development)
- [Troubleshooting](#troubleshooting)
- [Performance Optimization](#performance-optimization)

## Development Environment Setup

### Initial Setup

```bash
# 1. Clone repository
git clone https://github.com/[your-org]/flutter-boilerplate.git
cd flutter-boilerplate

# 2. Initialize (install all dependencies)
make init

# 3. Configure environment variables
cp env/secrets.env.example env/secrets.env
vi env/secrets.env  # Set required environment variables

# 4. Bootstrap monorepo
make frontend-bootstrap
```

### Starting Development Servers

```bash
# Terminal 1: Backend services
make run

# Terminal 2: Frontend watch mode (code generation)
cd frontend
melos run generate:watch

# Terminal 3: Frontend development server
make frontend
```

### VSCode Settings (Recommended)

`.vscode/settings.json`:

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  },
  "dart.lineLength": 80,
  "[dart]": {
    "editor.rulers": [80],
    "editor.selectionHighlight": false,
    "editor.suggest.snippetsPreventQuickSuggestions": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": false
  }
}
```

## Daily Development Flow

### 1. Morning Development Start

```bash
# Fetch latest code
git pull origin main

# Update dependencies
make frontend-bootstrap

# Start services
make run
make frontend
```

### 2. During Feature Development

```bash
# Code generation (watch mode recommended)
cd frontend && melos run generate:watch

# Or manual execution
make frontend-generate
```

### 3. Before Commit

```bash
# Quality checks (required)
make check-quality

# Run tests
make test-all

# Fix formatting
make fix-format
```

### 4. Daily Commands

```bash
# Frequently used commands
make frontend-generate      # Code generation
make check-quality          # Quality checks
make migrate-dev            # DB migration
make drizzle-studio        # DB GUI
```

## Monorepo Development

### Melos Commands Overview

```bash
# Package management
melos bootstrap             # Link packages and resolve dependencies
melos clean                 # Clean build artifacts

# Code generation
melos run generate          # Generate code for all packages
melos run generate:watch    # Watch mode (recommended during development)

# Testing
melos run test              # Test all packages
melos run test_coverage     # With coverage

# Quality management
melos run quality_check     # Analyze + Format Check + Test
melos run format            # Code formatting

# Execution
melos run web_run           # Start web app
```

### Managing Inter-package Dependencies

#### Creating Core Package

```bash
cd frontend/packages/core
mkdir new_package
cd new_package

# Create pubspec.yaml
cat > pubspec.yaml << EOF
name: core_new_package
description: Description of the package
version: 0.1.0

environment:
  sdk: ^3.6.0

dependencies:
  flutter:
    sdk: flutter
  riverpod: ^2.6.1

dev_dependencies:
  flutter_test:
    sdk: flutter
EOF

# Bootstrap to link packages
cd ../../../
melos bootstrap
```

#### Adding Package Dependencies

```yaml
# apps/web/pubspec.yaml
dependencies:
  core_api:
    path: ../../packages/core/api
  core_auth:
    path: ../../packages/core/auth
  core_i18n:
    path: ../../packages/core/i18n
```

### Customizing Melos Scripts

`frontend/melos.yaml`:

```yaml
scripts:
  # Example custom script addition
  custom_script:
    run: echo "Running custom script"
    description: Custom script description

  # Execute only in specific package
  generate:web:
    run: flutter pub run build_runner build --delete-conflicting-outputs
    exec:
      scope: web
    description: Generate code for web app only
```

## Feature Development Workflow

### Adding New Feature

#### 1. Create Feature Structure

```bash
cd frontend/apps/web/lib/features
mkdir -p new_feature/{api,model,ui}
```

#### 2. Implement Following FSD Structure

```
features/new_feature/
├── api/
│   └── new_feature_api.dart        # API integration
├── model/
│   ├── new_feature_state.dart      # Riverpod state
│   └── new_feature_state.g.dart    # Generated
└── ui/
    ├── new_feature_page.dart       # Page widget
    └── widgets/
        └── new_feature_widget.dart # UI components
```

#### 3. Implement Riverpod State

```dart
// model/new_feature_state.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'new_feature_state.g.dart';

@riverpod
class NewFeatureState extends _$NewFeatureState {
  @override
  Future<List<Item>> build() async {
    return await _fetchItems();
  }

  Future<void> addItem(Item item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _addItem(item);
      return await _fetchItems();
    });
  }
}
```

#### 4. Code Generation

```bash
# Automatically generated if watch mode is running
# Or manual execution
make frontend-generate
```

#### 5. Implement UI

```dart
// ui/new_feature_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewFeaturePage extends HookConsumerWidget {
  const NewFeaturePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(newFeatureStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Feature')),
      body: state.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => ListTile(
            title: Text(items[index].name),
          ),
        ),
        loading: () => const CircularProgressIndicator(),
        error: (error, stack) => Text('Error: $error'),
      ),
    );
  }
}
```

#### 6. Add Route

```dart
// app/router/app_router.dart
GoRoute(
  path: '/new-feature',
  builder: (context, state) => const NewFeaturePage(),
),
```

### API Integration

#### Using Core API Package

```dart
// features/new_feature/api/new_feature_api.dart
import 'package:core_api/core_api.dart';
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';

part 'new_feature_api.g.dart';

@RestApi()
abstract class NewFeatureApi {
  factory NewFeatureApi(Dio dio, {String baseUrl}) = _NewFeatureApi;

  @GET('/items')
  Future<List<Item>> getItems();

  @POST('/items')
  Future<Item> createItem(@Body() Item item);
}
```

#### Define API Provider

```dart
@riverpod
NewFeatureApi newFeatureApi(NewFeatureApiRef ref) {
  final dio = ref.watch(dioProvider);
  return NewFeatureApi(dio);
}
```

### Internationalization

#### Add Translations

```json
// packages/core/i18n/lib/i18n/en.i18n.json
{
  "newFeature": {
    "title": "New Feature",
    "addButton": "Add Item",
    "emptyState": "No items yet"
  }
}
```

```json
// packages/core/i18n/lib/i18n/ja.i18n.json
{
  "newFeature": {
    "title": "新機能",
    "addButton": "アイテムを追加",
    "emptyState": "まだアイテムがありません"
  }
}
```

#### Code Generation and Usage

```bash
make frontend-generate
```

```dart
// Usage example
import 'package:core_i18n/core_i18n.dart';

Text(t.newFeature.title)
ElevatedButton(
  onPressed: () {},
  child: Text(t.newFeature.addButton),
)
```

## Database Development

### Schema Change Workflow

#### 1. Edit Drizzle Schema

```typescript
// drizzle/schema/schema.ts
export const newTable = pgTable("new_table", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  description: text("description"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
}).enableRLS();

// RLS Policy
export const selectNewTable = pgPolicy("select_new_table", {
  for: "select",
  to: ["authenticated"],
  using: sql`true`,
}).link(newTable);
```

#### 2. Generate and Apply Migration

```bash
# Development environment (local Supabase)
make migrate-dev

# This command executes:
# 1. Setup PostgreSQL extensions
# 2. Generate migration files
# 3. Apply migrations to local DB
# 4. Execute custom SQL
# 5. Generate type definitions
```

#### 3. Verify Generated Files

```bash
# Migration files
ls supabase/migrations/


# Edge Functions type definitions
cat shared/drizzle/
```

#### 4. Verify with Drizzle Studio

```bash
make drizzle-studio
# Opens http://localhost:4983 in browser
```

### Adding Custom SQL Functions

```sql
-- drizzle/config/functions.sql
CREATE OR REPLACE FUNCTION get_user_stats(user_id UUID)
RETURNS TABLE (
  total_items BIGINT,
  active_items BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*) as total_items,
    COUNT(*) FILTER (WHERE status = 'active') as active_items
  FROM items
  WHERE items.user_id = get_user_stats.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

Custom SQL is applied by running migration again:

```bash
make migrate-dev
```

### Migration Rollback

Since Drizzle doesn't have built-in rollback feature, create manual rollback migration:

```bash
# Check latest migration file
ls -lt supabase/migrations/

# Create new migration file (describe reverse operation)
cat > supabase/migrations/$(date +%Y%m%d%H%M%S)_rollback_new_table.sql << EOF
-- Rollback migration
DROP TABLE IF EXISTS new_table CASCADE;
EOF

# Apply locally
make migrate-dev
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Code Generation Errors

**Problem**: `build_runner` throws errors

```bash
# Solution 1: Clear cache and regenerate
cd frontend
melos clean
melos bootstrap
melos run generate
```

```bash
# Solution 2: Delete conflicting files and regenerate
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 2. Melos Commands Not Working

**Problem**: `melos: command not found`

```bash
# Solution: Install Melos globally
dart pub global activate melos

# Add to PATH (~/.zshrc or ~/.bashrc)
export PATH="$PATH:$HOME/.pub-cache/bin"
```

#### 3. Supabase Connection Error

**Problem**: `Connection refused`

```bash
# Solution 1: Check if Supabase is running
docker ps | grep supabase

# Solution 2: Restart Supabase
make stop
make run
```

#### 4. Migration Errors

**Problem**: `Migration failed`

```bash
# Solution 1: Check migration history
make migrate-status

# Solution 2: Reset database (development only)
make db-reset
make migrate-dev
```

#### 5. Hot Reload Not Working

**Problem**: Code changes not reflected in app

```bash
# Solution 1: Flutter Clean and build
cd frontend/apps/web
flutter clean
flutter pub get
flutter run -d chrome

# Solution 2: Riverpod code generation
cd frontend
melos run generate
```

#### 6. Package Dependency Errors

**Problem**: `Version solving failed`

```bash
# Solution: Rebuild links with bootstrap
cd frontend
melos clean
melos bootstrap
```

### Debug Tools

#### 1. Flutter DevTools

```bash
# Start DevTools
cd frontend/apps/web
flutter run -d chrome
# Open URL displayed in terminal in browser
```

#### 2. Riverpod Inspector

```dart
// Add ProviderObserver in main.dart
void main() {
  runApp(
    ProviderScope(
      observers: [
        if (kDebugMode) RiverpodLogger(),
      ],
      child: const MyApp(),
    ),
  );
}

class RiverpodLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    print('[${provider.name ?? provider.runtimeType}] $newValue');
  }
}
```

#### 3. Log Settings

```dart
// Set log level with core/utils
import 'package:core_utils/logger.dart';

logger.d('Debug message');
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message');
```

## Performance Optimization

### Frontend Optimization

#### 1. Widget Optimization

```dart
// ❌ Bad: Entire widget rebuilds
class BadExample extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);
    return Column(
      children: [
        ExpensiveWidget(),  // Rebuilds every time counter changes
        Text('$counter'),
      ],
    );
  }
}

// ✅ Good: Only necessary parts rebuild
class GoodExample extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const ExpensiveWidget(),  // Optimized with const
        Consumer(
          builder: (context, ref, child) {
            final counter = ref.watch(counterProvider);
            return Text('$counter');
          },
        ),
      ],
    );
  }
}
```

#### 2. Provider Optimization

```dart
// ❌ Bad: Watch entire object
final userProvider = FutureProvider<User>((ref) async {
  return await fetchUser();
});

// ✅ Good: Extract only necessary parts
final userNameProvider = Provider<String>((ref) {
  return ref.watch(userProvider).value?.name ?? '';
});
```

#### 3. Build Size Optimization

```bash
# Check web build size
cd frontend/apps/web
flutter build web --release --analyze-size

# Remove unused imports
dart fix --apply
```

### Database Optimization

#### 1. Add Indexes

```typescript
// drizzle/schema/schema.ts
export const items = pgTable(
  "items",
  {
    id: uuid("id").primaryKey(),
    userId: uuid("user_id").notNull(),
    name: text("name").notNull(),
    createdAt: timestamp("created_at").defaultNow(),
  },
  (table) => ({
    // Add indexes
    userIdIdx: index("items_user_id_idx").on(table.userId),
    nameIdx: index("items_name_idx").on(table.name),
    createdAtIdx: index("items_created_at_idx").on(table.createdAt),
  })
);
```

#### 2. Query Optimization

```typescript
// ❌ Bad: N+1 problem
for (const user of users) {
  const items = await db.select().from(items).where(eq(items.userId, user.id));
}

// ✅ Good: Use joins
const usersWithItems = await db
  .select()
  .from(users)
  .leftJoin(items, eq(users.id, items.userId));
```

### Edge Functions Optimization

#### 1. Cold Start Mitigation

```typescript
// Initialize globally (Cold Start mitigation)
const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

Deno.serve(async (req) => {
  // Don't initialize per request
  // ...
});
```

#### 2. Response Caching

```typescript
const cache = new Map<string, { data: any; expiry: number }>();

function getCached(key: string) {
  const item = cache.get(key);
  if (item && item.expiry > Date.now()) {
    return item.data;
  }
  return null;
}

function setCache(key: string, data: any, ttlMs: number) {
  cache.set(key, { data, expiry: Date.now() + ttlMs });
}
```

## Summary

### Development Checklist

Items to verify in daily development:

- [ ] `make frontend-bootstrap` for package linking
- [ ] `melos run generate:watch` for code generation (watch mode)
- [ ] Implementation adhering to FSD architecture
- [ ] State management with Riverpod
- [ ] Type-safe translations (slang)
- [ ] `make check-quality` before commit
- [ ] Add tests (TDD)
- [ ] Configure RLS policy (when changing DB)

### Useful Commands List

```bash
# Frequently used commands
make frontend-bootstrap      # Monorepo setup
make frontend-generate       # Code generation
make check-quality           # Quality checks
make test-all                # Run all tests
make migrate-dev             # Migration
make drizzle-studio         # DB GUI

# Melos commands
melos run generate:watch     # Code generation (watch)
melos run quality_check      # Quality checks
melos run test               # Run tests
```

For more details, refer to the following documents:

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Architecture details
- [TESTING.md](./TESTING.md) - Testing strategy
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Deployment procedures
