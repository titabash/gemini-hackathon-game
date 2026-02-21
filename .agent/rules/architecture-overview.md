# Architecture Overview

This is a full-stack application boilerplate with Flutter frontend, Python backend, and Supabase Edge Functions.

## Backend as a Service Strategy

- **Frontend-First Approach**: Frontend leverages Supabase client directly for authentication, authorization, and database operations to maximize BaaS characteristics
- **Edge Functions Priority**: Backend implementations should default to Edge Functions unless specifically requiring Python capabilities
- **Python Backend Scope**: Reserved for transaction-heavy operations and Python-specific implementations, using SQLModel for database interactions

## Frontend Architecture (Monorepo)

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

## Edge Functions (Supabase)

- **Primary Backend**: Default choice for backend implementations unless Python-specific features are required
- **Deno Runtime**: TypeScript edge functions in `supabase/functions/`
- **Generated Types**: Database types from `domain/entity/__generated__/schema.ts`
- **Supabase Client**: Direct database access with type safety
- **Use Cases**: Business logic, webhooks, real-time processing, serverless APIs, external integrations
- **AI Integration**: Mastra, multiple LLM providers, vector search capabilities
- **Lightweight Operations**: Ideal for stateless operations and simple business logic

## Backend Architecture (Python)

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

## Database Design

- **Supabase PostgreSQL**: Primary database with real-time subscriptions
- **SQLModel (Python Backend)**: Type-safe ORM with synchronous database operations for Python backend
- **Drizzle ORM**: TypeScript-first ORM for schema management, migrations, and Edge Functions:
  - Schema files in `drizzle/schema/`: TypeScript-based declarative schema definition
  - Migrations in `supabase/migrations/`: Auto-generated SQL migration files
  - Type-safe database operations with full TypeScript inference
  - Drizzle Studio for visual database management
  - Custom SQL support via `drizzle/config/` for functions, triggers, and extensions
