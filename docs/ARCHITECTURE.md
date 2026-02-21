# Architecture Overview

This document describes the detailed architecture of flutter-boilerplate.

## Table of Contents

- [System Overview](#system-overview)
- [Monorepo Structure](#monorepo-structure)
- [Frontend Architecture](#frontend-architecture)
- [Backend Architecture](#backend-architecture)
- [Edge Functions Architecture](#edge-functions-architecture)
- [Database Architecture](#database-architecture)
- [Authentication & Authorization](#authentication--authorization)
- [Data Flow](#data-flow)

## System Overview

flutter-boilerplate is a full-stack application composed of three main components:

```
┌─────────────────┐
│  Flutter Web    │  ← Frontend (Monorepo)
│  (apps/web)     │
└────────┬────────┘
         │
    ┌────▼─────────────────────┐
    │   Supabase (BaaS)        │
    │  - Auth                  │
    │  - PostgreSQL + RLS      │
    │  - Edge Functions (Deno) │
    │  - Real-time             │
    └────┬─────────────────────┘
         │
    ┌────▼────────┐
    │ Python      │  ← Backend (Optional, for complex operations)
    │ FastAPI     │
    └─────────────┘
```

### Backend as a Service (BaaS) Strategy

- **Frontend-First**: Frontend uses Supabase client directly (Auth, DB operations, Real-time)
- **Edge Functions Priority**: Edge Functions are the default choice for backend implementations
- **Python Backend**: Only used when transaction processing or Python-specific implementations are required

## Monorepo Structure

### Overall Structure

```
flutter-boilerplate/
├── frontend/              # Flutter Monorepo (Melos)
│   ├── melos.yaml         # Monorepo configuration
│   ├── apps/
│   │   └── web/           # Main web application
│   └── packages/
│       ├── core/          # Core functionality
│       │   ├── api/       # HTTP client (Dio + Retrofit)
│       │   ├── auth/      # Authentication
│       │   ├── i18n/      # Internationalization (slang)
│       │   └── utils/     # Common utilities
│       └── shared/
│           └── ui/        # Shared UI components
│
├── drizzle/               # Database schema (TypeScript)
│   ├── schema/            # Schema definitions
│   ├── config/            # Custom SQL (functions, triggers)
│   └── migrate.ts         # Migration script
│
├── supabase/
│   ├── functions/         # Edge Functions (Deno)
│   │   ├── domain/        # Shared types
│   │   ├── infra/         # Infrastructure (DB client)
│   │   └── [function]/    # Individual functions
│   └── migrations/        # Generated SQL migrations
│
└── backend-py/            # Python FastAPI (Optional)
    └── app/
        └── src/
            ├── controller/  # HTTP endpoints
            ├── usecase/     # Business logic
            ├── domain/      # Domain models
            ├── gateway/     # Data access
            └── infra/       # External services
```

### Melos Workspace

Melos provides:

- **Unified Command Execution**: Batch execution across all packages
- **Inter-package Dependency Management**: Local package linking
- **Efficient CI/CD**: Test only changed packages
- **Consistent Versioning**: Version management across the monorepo

## Frontend Architecture

### Monorepo Structure

#### apps/web/ - Main Application

Structure adhering to Feature Sliced Design (FSD):

```
apps/web/lib/
├── app/                   # Application layer
│   ├── router/            # GoRouter configuration
│   │   └── app_router.dart
│   ├── theme/             # Theme configuration
│   └── providers/         # Global providers
│
├── pages/                 # Pages layer (Routes)
│   ├── home/
│   ├── auth/
│   └── dashboard/
│
├── features/              # Features layer (Business logic)
│   ├── counter/
│   │   ├── api/           # API integration
│   │   ├── model/         # State management (Riverpod)
│   │   └── ui/            # UI components
│   └── auth/
│       ├── api/
│       ├── model/
│       └── ui/
│
├── entities/              # Entities layer (Domain models)
│   └── user/
│       ├── model/         # User entity
│       └── ui/            # Reusable user UI
│
└── shared/                # Shared layer (Utilities)
    ├── config/
    ├── ui/                # Common widgets
    └── utils/
```

**Layer Dependency Rules**:

```
app → pages → features → entities → shared
```

- Can only import from lower layers
- Cross-imports within the same layer are forbidden
- Imports from upper layers are strictly prohibited

#### packages/core/ - Core Functionality

**core/api**: HTTP Client with Type Safety

```dart
// Type-safe API integration with Dio + Retrofit
@RestApi(baseUrl: "https://api.example.com")
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  @GET("/users/{id}")
  Future<User> getUser(@Path() String id);
}
```

Features:

- Interceptors (authentication tokens, logging, error handling)
- Automatic token refresh
- Unified error handling

**core/auth**: Authentication Management

```dart
// Integration with Supabase Auth
@riverpod
class AuthState extends _$AuthState {
  @override
  Future<User?> build() async {
    final response = await supabase.auth.getUser();
    return response.user;
  }

  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    ref.invalidateSelf();
  }
}
```

**core/i18n**: Internationalization (slang)

- JSON-based translation files
- Type safety through code generation
- Runtime language switching

**core/utils**: Common Utilities

- Structured logging
- Constant definitions
- Helper functions

#### packages/shared/ui - Shared UI

Reusable UI components:

- Custom buttons, cards
- Theme support
- Accessibility support

### State Management (Riverpod)

Type-safe state management using **Riverpod Generator**:

```dart
// Provider definition
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
}

// Consumer
class CounterView extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);

    return Column(
      children: [
        Text('$counter'),
        ElevatedButton(
          onPressed: () => ref.read(counterProvider.notifier).increment(),
          child: Text('Increment'),
        ),
      ],
    );
  }
}
```

### Navigation (GoRouter)

**Authentication-aware declarative routing**:

```dart
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      // Authentication guards
      if (!isAuthenticated && !isAuthRoute) {
        return '/auth/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
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
      ),
    ],
  );
}
```

Features:

- Automatic redirects based on auth state
- Declarative route definitions
- Type-safe parameters
- Deep linking support

### Internationalization (i18n)

Type-safe multilingual support with **slang**:

```json
// en.i18n.json
{
  "home": {
    "title": "Welcome",
    "message": "Hello, @name!"
  }
}
```

```dart
// Usage example
Text(t.home.title)                    // "Welcome"
Text(t.home.message(name: 'John'))    // "Hello, John!"

// Language switching
localeNotifier.changeLocale(AppLocale.ja);
```

## Backend Architecture

### Edge Functions (Supabase) - Recommended

Lightweight serverless functions with **Deno Runtime**:

```typescript
import { createClient } from "npm:@supabase/supabase-js@^2";
import { getDb } from "../infra/database.ts";

Deno.serve(async (req) => {
  try {
    // Authentication
    const authHeader = req.headers.get("Authorization")!;
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    // Get authenticated user
    const {
      data: { user },
      error,
    } = await supabase.auth.getUser();
    if (error) throw error;

    // Database access via Drizzle
    const db = getDb();
    const result = await db.query.users.findMany();

    return new Response(JSON.stringify({ data: result }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
```

**Use Cases**:

- Lightweight business logic
- Webhook processing
- Real-time processing
- External API integrations

### Python Backend (FastAPI) - Optional

Layered architecture with **Clean Architecture**:

```
src/
├── controller/       # HTTP layer
│   └── user_controller.py
├── usecase/          # Business logic
│   └── user_usecase.py
├── gateway/          # Data access interface
│   └── user_gateway.py
├── domain/
│   ├── entity/       # SQLModel entities
│   │   └── user.py
│   └── service/      # Domain services
│       └── user_service.py
└── infra/            # External dependencies
    └── supabase_gateway.py
```

**Dependency Flow**:

```
Controller → UseCase → Gateway → Domain
     ↓
Infrastructure (Implementation)
```

**Use Cases**:

- Complex transaction processing
- Python-specific library requirements
- Heavy computational tasks
- Batch processing

## Edge Functions Architecture

### Directory Structure

```
supabase/functions/
├── domain/
│   └── entity/
│       └── __generated__/
│           └── schema.ts      # Supabase-generated types
├── infra/
│   └── database.ts            # Drizzle client
└── [function-name]/
    └── index.ts               # Function entry point
```

### Type System

**Two type definitions for different purposes**:

1. **Drizzle ORM types**: For direct DB operations

```typescript
import { getDb } from "../infra/database.ts";
import { users } from "drizzle/schema";

const db = getDb();
const result = await db.select().from(users);
```

2. **Supabase-generated types**: For supabase-js client

```typescript
import { createClient } from "@supabase/supabase-js";
import { Database } from "../domain/entity/__generated__/schema.ts";

const supabase = createClient<Database>(url, key);
const { data } = await supabase.from("users").select();
```

## Database Architecture

### Declarative Schema Management with Drizzle ORM

```typescript
// drizzle/schema/schema.ts
import { pgTable, uuid, text, timestamp } from "drizzle-orm/pg-core";
import { pgPolicy } from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";

// Table definition
export const generalUsers = pgTable("general_users", {
  id: uuid("id").primaryKey().defaultRandom(),
  accountName: text("account_name").notNull().unique(),
  displayName: text("display_name"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
}).enableRLS();

// RLS Policy (declarative)
export const selectOwnUser = pgPolicy("select_own_user", {
  for: "select",
  to: ["anon", "authenticated"],
  using: sql`auth.uid() = id`,
}).link(generalUsers);

export const updateOwnUser = pgPolicy("update_own_user", {
  for: "update",
  to: ["authenticated"],
  using: sql`auth.uid() = id`,
  withCheck: sql`auth.uid() = id`,
}).link(generalUsers);
```

### Migration Workflow

```bash
# 1. Edit schema (drizzle/schema/schema.ts)
# 2. Generate and apply migrations
make migrate-dev

# This command:
# - Sets up PostgreSQL extensions
# - Generates migration files (supabase/migrations/)
# - Applies migrations to local Supabase database
# - Executes custom SQL (functions, triggers)
# - Generates type definitions (Frontend, Edge Functions)
```

### Database Clients

**Frontend**:

```dart
final supabase = Supabase.instance.client;
final users = await supabase.from('general_users').select();
```

**Edge Functions (Drizzle)**:

```typescript
const db = getDb();
const users = await db.select().from(generalUsers);
```

**Python Backend (SQLModel)**:

```python
from src.domain.entity.models import GeneralUser

async with get_session() as session:
    users = session.exec(select(GeneralUser)).all()
```

## Authentication & Authorization

### Authentication Flow

```
1. User Login
   ↓
2. Supabase Auth (JWT issuance)
   ↓
3. Frontend: Token storage
   ↓
4. GoRouter: Authentication guard check
   ↓
5. API Request: Authorization header attached
   ↓
6. Backend/Edge Functions: Token verification
   ↓
7. Database: RLS policy enforcement
```

### Security Best Practices

**Frontend**:

```dart
// ✅ Good: Verify with getUser()
final response = await supabase.auth.getUser();
final user = response.user;

// ❌ Bad: Session can be spoofed
final session = supabase.auth.currentSession;
```

**Edge Functions**:

```typescript
// ✅ Good: Token verification
const {
  data: { user },
  error,
} = await supabase.auth.getUser();
if (error) throw new Error("Unauthorized");

// ❌ Bad: Don't trust Session
```

**Database (RLS)**:

```sql
-- Enable RLS on all tables
ALTER TABLE general_users ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY "Users can view own data"
  ON general_users FOR SELECT
  USING (auth.uid() = id);
```

## Data Flow

### Typical CRUD Operation

```
┌─────────────┐
│  Frontend   │
│  (Flutter)  │
└──────┬──────┘
       │ 1. User Action
       ▼
┌─────────────────┐
│  Riverpod       │  2. State Update
│  Provider       │
└──────┬──────────┘
       │ 3. API Call
       ▼
┌──────────────────┐
│  Supabase Client │  4. HTTP Request (with JWT)
└──────┬───────────┘
       │
       ▼
┌───────────────────────┐
│  Supabase (BaaS)      │
│  - Auth Check         │  5. Authentication
│  - RLS Policy Check   │  6. Authorization
│  - Execute Query      │  7. Database Operation
└───────┬───────────────┘
        │ 8. Response
        ▼
┌─────────────────┐
│  Frontend       │  9. UI Update
│  (Widget Tree)  │
└─────────────────┘
```

### Real-time Updates

```
┌─────────────┐
│  Frontend   │
│  (Listener) │  ← WebSocket Connection
└──────┬──────┘
       │
       ↕ Real-time Events
       │
┌──────▼──────────────┐
│  Supabase Realtime  │
└─────────────────────┘
       ↕
┌─────────────────────┐
│  PostgreSQL         │
│  (Change Data       │
│   Capture)          │
└─────────────────────┘
```

## Code Generation Flow

### Frontend (Riverpod, i18n, Drift)

```
Source Files                Code Generation              Generated Files
─────────────              ───────────────              ────────────────
*.dart with
@riverpod          ──────→  build_runner   ──────→     *.g.dart
                                                        *.freezed.dart

*.i18n.json       ──────→  slang build     ──────→     strings.g.dart

*.drift           ──────→  drift build     ──────→     *.drift.dart
```

### Database (Drizzle)

```
TypeScript Schema          Migration                   Generated Files
─────────────────         ──────────                  ────────────────
drizzle/schema/    ──────→  drizzle-kit   ──────→     supabase/migrations/*.sql
schema.ts                   generate                   (SQL migrations)

                           drizzle-kit    ──────→     Frontend: *.dart
                           push + custom              Edge Functions: schema.ts
```

## Summary

### Architecture Characteristics

✅ **Monorepo**: Efficient package management with Melos
✅ **Type Safety**: Ensured across all layers
✅ **Code Generation**: Auto-generate boilerplate
✅ **BaaS-First**: Maximize Supabase utilization
✅ **Security**: Multi-layered defense with RLS + JWT
✅ **Scalability**: Auto-scaling with Edge Functions
✅ **Developer Experience**: Unified commands and workflows

### Development Flow

1. **Design**: Structure design based on Feature Sliced Design
2. **Implementation**: Frontend implementation with Riverpod + GoRouter
3. **DB Changes**: Update Drizzle schema → Generate migrations
4. **Code Generation**: Execute build_runner, slang
5. **Testing**: Test-driven development based on TDD
6. **Quality Checks**: Unified checks with `make check-quality`
7. **Deployment**: Deploy Edge Functions

For more details, refer to the following documents:

- [DEVELOPMENT.md](./DEVELOPMENT.md) - Development workflow
- [TESTING.md](./TESTING.md) - Testing strategy
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Deployment procedures
