# Database Operations

## Database Design

- **Supabase PostgreSQL**: Primary database with real-time subscriptions
- **SQLModel (Python Backend)**: Type-safe ORM with synchronous database operations for Python backend
- **Drizzle ORM**: TypeScript-first ORM for schema management, migrations, and Edge Functions:
  - Schema files in `drizzle/schema/`: TypeScript-based declarative schema definition
  - Migrations in `supabase/migrations/`: Auto-generated SQL migration files
  - Type-safe database operations with full TypeScript inference
  - Drizzle Studio for visual database management
  - Custom SQL support via `drizzle/config/` for functions, triggers, and extensions

## Database Operations Commands (Drizzle)

### Migration Commands

```bash
# Primary commands
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

## Drizzle Workflow

### 1. Development (`make migrate-dev`)

- Sets up PostgreSQL extensions (vector, etc.) before migrations
- Generates migration files from schema changes
- Applies migrations to local Supabase database
- Executes custom SQL (functions, triggers)
- Generates type definitions for Edge Functions

### 2. Production (`make migrate-deploy`)

- Sets up PostgreSQL extensions first
- Applies existing migrations
- Executes custom SQL (functions, triggers)
- Suitable for staging/production environments

### 3. Drizzle Studio (`make drizzle-studio`)

- Visual database browser at http://localhost:4983
- Query data, inspect schema, manage records

## MCP-Enhanced Database Workflow

```
1. Supabase MCP → Analyze current local database schema
2. Context7 → Research migration best practices with Drizzle
3. Update drizzle/schema/*.ts files (TypeScript schema definition)
4. make migrate-dev → Generate migrations, push to local DB, execute custom SQL, generate types
5. Supabase MCP → Verify changes in local database
6. make drizzle-studio → Visually inspect changes (optional)
```

## Database Best Practices

- **Always Check Schema First**: Use Supabase MCP to verify current local database schema before modifications
- **Never Modify Without Checking**: Never modify database schema without first checking current structure via Supabase MCP
- **Verify RLS Policies**: Always verify RLS policies via Supabase MCP before deployment
- **Research Best Practices**: Use Context7 for PostgreSQL best practices before implementing changes
- **Test Locally First**: Always test migrations on local database before deploying to staging/production

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
