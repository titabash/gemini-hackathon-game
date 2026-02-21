# Backend Architecture

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

### Type Safety

- **Dual Type System**: For flexibility
  - Drizzle ORM types: For direct database operations and transactions
  - Supabase-generated types: For supabase-js client operations (Auth, Storage, Realtime)

### Database Access

- **Drizzle ORM**: Type-safe direct database queries with `getDb()` from `@infra/database`
- **Supabase Client**: For Auth, Storage, Realtime, and RPC operations

### Function Structure

- Each function in separate directory under `supabase/functions/`
- **Shared Code**:
  - Drizzle schema from `drizzle/schema/` (imported with extensions)
  - Supabase types in `domain/entity/__generated__/schema.ts`

### Best Practices

- **CORS Headers**: Must be properly configured for all functions
- **Error Handling**: Comprehensive error scenarios with proper status codes

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
