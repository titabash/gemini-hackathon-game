---
name: supabase-migration
description: Create database schema migrations using Drizzle ORM. Use when adding tables, modifying columns, creating indexes, or setting up RLS policies.
---

# Supabase Migration Creation Skill

Create database schema migrations using Drizzle ORM for Supabase PostgreSQL.

## Task

You will create database migrations by:
1. Defining schema in TypeScript using Drizzle
2. Generating migration files automatically
3. Applying migrations to local/remote databases
4. Generating TypeScript types for Edge Functions

## Migration Workflow

### Overview

This project uses **Drizzle ORM** for declarative schema management:

```
1. Define Schema (TypeScript) → 2. Generate Migration → 3. Apply to DB → 4. Generate Types
   drizzle/schema/*.ts       supabase/migrations/*.sql   Local/Remote     domain/entity/__generated__/
```

### Key Commands

```bash
# Development: Generate migration, apply to local DB, generate types
make migrate-dev

# Production: Apply existing migrations
make migrate-deploy

# Check migration status
make migrate-status

# Open Drizzle Studio (visual DB management)
make drizzle-studio
```

## Implementation Steps

### 1. Define Schema in TypeScript

Create or modify schema files in `drizzle/schema/`:

```bash
# Example: Create users table schema
vim drizzle/schema/users.ts
```

### 2. Generate Migration

```bash
make migrate-dev
```

This command:
- Compares schema with current database
- Generates SQL migration in `supabase/migrations/`
- Applies migration to local Supabase
- Executes custom SQL (functions, triggers)
- Generates types for Edge Functions

### 3. Verify Migration

```bash
# Check migration was applied
make migrate-status

# Open Drizzle Studio to inspect
make drizzle-studio
```

## Schema Definition Examples

### Basic Table (users.ts):

```typescript
import { pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const users = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  email: text("email").notNull().unique(),
  displayName: text("display_name"),
  avatarUrl: text("avatar_url"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});
```

### Table with Foreign Keys (posts.ts):

```typescript
import { pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";
import { users } from "./users.ts";

export const posts = pgTable("posts", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  title: text("title").notNull(),
  content: text("content"),
  publishedAt: timestamp("published_at"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});
```

### Table with Enums (subscriptions.ts):

```typescript
import { pgTable, text, timestamp, uuid, pgEnum } from "drizzle-orm/pg-core";
import { users } from "./users.ts";

export const subscriptionStatus = pgEnum("subscription_status", [
  "active",
  "canceled",
  "past_due",
  "trialing",
]);

export const subscriptions = pgTable("subscriptions", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  status: subscriptionStatus("status").notNull().default("trialing"),
  currentPeriodStart: timestamp("current_period_start").notNull(),
  currentPeriodEnd: timestamp("current_period_end").notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});
```

### Table with JSONB (settings.ts):

```typescript
import { pgTable, uuid, jsonb, timestamp } from "drizzle-orm/pg-core";
import { users } from "./users.ts";

export const userSettings = pgTable("user_settings", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" })
    .unique(),
  preferences: jsonb("preferences").$type<{
    theme: "light" | "dark";
    language: string;
    notifications: boolean;
  }>(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});
```

### Table with Indexes:

```typescript
import { pgTable, text, timestamp, uuid, index } from "drizzle-orm/pg-core";
import { users } from "./users.ts";

export const posts = pgTable(
  "posts",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    userId: uuid("user_id")
      .notNull()
      .references(() => users.id),
    title: text("title").notNull(),
    slug: text("slug").notNull().unique(),
    content: text("content"),
    publishedAt: timestamp("published_at"),
    createdAt: timestamp("created_at").defaultNow().notNull(),
  },
  (table) => [
    // Indexes for performance
    index("posts_user_id_idx").on(table.userId),
    index("posts_slug_idx").on(table.slug),
    index("posts_published_at_idx").on(table.publishedAt),
  ],
);
```

## Custom SQL (Functions, Triggers, Extensions)

Place custom SQL files in `drizzle/config/`:

### Example: PostgreSQL Extension (vector.sql):

```sql
-- Enable pgvector extension for embeddings
CREATE EXTENSION IF NOT EXISTS vector;
```

### Example: Database Function (updated_at_trigger.sql):

```sql
-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at
  BEFORE UPDATE ON posts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### Example: RLS Policies (rls_policies.sql):

```sql
-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "Users can read own profile"
  ON users
  FOR SELECT
  USING (auth.uid()::uuid = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON users
  FOR UPDATE
  USING (auth.uid()::uuid = id);
```

## Migration Best Practices

1. **Schema Organization**:
   - One table per file in `drizzle/schema/`
   - Group related tables
   - Export all schemas from `drizzle/schema/index.ts`

2. **Naming Conventions**:
   - Tables: plural, snake_case (e.g., `user_profiles`)
   - Columns: snake_case (e.g., `created_at`)
   - Foreign keys: `{table}_id` (e.g., `user_id`)
   - Indexes: `{table}_{column}_idx`

3. **Data Types**:
   - Use `uuid` for IDs (not serial/bigserial)
   - Use `timestamp` for dates (not date)
   - Use `text` for strings (not varchar)
   - Use `jsonb` for structured data

4. **Constraints**:
   - Always define primary keys
   - Add foreign keys with `onDelete` behavior
   - Add unique constraints where needed
   - Add check constraints for validation

5. **Indexes**:
   - Index foreign keys
   - Index frequently queried columns
   - Index columns used in WHERE/ORDER BY
   - Don't over-index (impacts write performance)

6. **Migrations**:
   - Review generated SQL before applying
   - Test migrations locally first
   - Write reversible migrations when possible
   - Document breaking changes

## Workflow Examples

### Adding a New Table:

```bash
# 1. Create schema file
cat > drizzle/schema/products.ts << 'EOF'
import { pgTable, text, numeric, uuid, timestamp } from "drizzle-orm/pg-core";

export const products = pgTable("products", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  description: text("description"),
  price: numeric("price", { precision: 10, scale: 2 }).notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});
EOF

# 2. Export from index
echo "export * from './products.ts';" >> drizzle/schema/index.ts

# 3. Generate and apply migration
make migrate-dev

# 4. Verify in Drizzle Studio
make drizzle-studio
```

### Modifying an Existing Table:

```bash
# 1. Edit schema file
vim drizzle/schema/users.ts

# Add new column:
# phoneNumber: text("phone_number"),

# 2. Generate and apply migration
make migrate-dev

# 3. Check migration status
make migrate-status
```

### Adding RLS Policies:

```bash
# 1. Create SQL file
cat > drizzle/config/products_rls.sql << 'EOF'
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read products"
  ON products
  FOR SELECT
  USING (true);

CREATE POLICY "Admins can manage products"
  ON products
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');
EOF

# 2. Run migration
make migrate-dev
```

## Troubleshooting

### Migration Conflicts

**Problem**: Schema changes conflict with existing data

```bash
# Solution 1: Reset local database
make db-reset

# Solution 2: Write data migration
# Create SQL file in drizzle/config/
```

### Type Generation Issues

**Problem**: Types not updating in Edge Functions

```bash
# Solution: Regenerate types
make build-model-functions
```

### Drizzle Studio Not Loading

**Problem**: Cannot connect to database

```bash
# Solution: Check Supabase is running
supabase status

# Restart Supabase
supabase stop
supabase start
```

## Common Column Types Reference

```typescript
// Strings
text("column_name")
varchar("column_name", { length: 255 })

// Numbers
integer("column_name")
bigint("column_name", { mode: "number" })
numeric("column_name", { precision: 10, scale: 2 })
real("column_name")
doublePrecision("column_name")

// Boolean
boolean("column_name")

// Dates
date("column_name")
timestamp("column_name")
timestamp("column_name", { withTimezone: true })

// JSON
json("column_name")
jsonb("column_name")

// UUID
uuid("column_name")

// Arrays
text("tags").array()

// Enums
pgEnum("status", ["active", "inactive"])
```

## Notes

- Drizzle ORM is the standard for database schema management
- Always test migrations locally before deploying
- Generated SQL migrations are version-controlled
- See CLAUDE.md for complete database architecture
- Check Supabase MCP tool for querying current database schema
