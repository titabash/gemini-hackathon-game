# MCP (Model Context Protocol) Tool Usage Guidelines

## IMPORTANT: Actively Use MCP Tools for Specialized Tasks

Claude Code has access to specialized MCP tools that should be actively utilized for efficient and accurate development.

## Available MCP Tools

### 1. Context7 MCP for Professional Research

- **ALWAYS use Context7 MCP** for researching technical topics, best practices, and implementation patterns
- Use for investigating new libraries, frameworks, or architectural patterns
- Leverage for understanding complex technical concepts before implementation
- Essential for staying current with latest development practices

### 2. Dart/Flutter MCP for Implementation

- **ALWAYS use Dart MCP** when implementing Flutter/Dart code
- Use for:
  - Widget implementation patterns and best practices
  - State management with Riverpod
  - Flutter-specific optimizations and performance tips
  - Dart language features and idioms
  - Package recommendations and usage patterns
- Consult before writing any Flutter/Dart code to ensure idiomatic implementation

### 3. Supabase MCP for Database Operations

- **ALWAYS use Supabase MCP** for:
  - Checking existing table structures before modifications
  - Understanding relationships and constraints
  - Verifying RLS (Row Level Security) policies
  - Reviewing indexes and performance considerations
  - Planning migrations and schema changes
- Never modify database schema without first checking current structure via Supabase MCP

### 4. IDE MCP for Code Intelligence

- **Use IDE MCP** (`mcp__ide__`) for:
  - Getting diagnostics and error information
  - Executing code in Jupyter notebooks
  - Understanding current IDE state and issues

## MCP Usage Protocol

1. **Before Implementation**: Always check relevant MCP tools first
2. **During Development**: Continuously consult MCP tools for validation
3. **After Changes**: Use MCP tools to verify correctness
4. **Documentation**: Reference MCP tool findings in code comments when relevant

## Example Workflow

```
User Request → Analyze with Context7 → Check Supabase structure →
Consult Dart MCP for patterns → Implement → Verify with IDE MCP
```

## MCP Tool Priority

**ALWAYS prioritize MCP tools over general knowledge:**

1. **Supabase MCP** > General database assumptions
2. **Dart MCP** > Generic Flutter patterns
3. **Context7** > Outdated documentation or practices
4. **IDE MCP** > Manual error checking

## MCP Tool Usage Examples

### When Adding a New Feature

```
1. Context7: "Flutter best practices for implementing infinite scroll with Riverpod"
2. Supabase MCP: Check 'posts' table structure and indexes in local database
3. Dart MCP: "How to implement infinite scroll with Riverpod and pagination"
4. Implement following the guidance
5. IDE MCP: Check for any diagnostics
```

### When Modifying Database

```
1. Supabase MCP: "Show me the current local schema for user_profiles table"
2. Context7: "PostgreSQL best practices for adding JSON columns"
3. Create migration with proper rollback strategy
4. Supabase MCP: "Verify the migration will not break existing queries in local database"
```

### When Creating Edge Functions

```
1. Supabase MCP: "List all tables accessible from edge functions in local database"
2. Context7: "Deno best practices for handling CORS in Supabase functions"
3. Implement with proper error handling
4. Test with curl commands
```
