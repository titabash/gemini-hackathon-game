# Conventions and Best Practices

## Code Style

### Flutter/Dart

- Follow Dart conventions
- Use trailing commas for better formatting
- Consult Dart MCP for idiomatic patterns
- Use `@freezed` annotation for immutable models
- Add `@JsonSerializable()` for API/database integration
- Define models in the `model/` segment of FSD structure

### Python

- Follow PEP 8 with Black formatting
- Type hints required for all functions
- 88 character line limit
- Maximum McCabe complexity of 3

### TypeScript (Edge Functions)

- Standard JS/TS conventions
- Proper CORS headers configuration
- Comprehensive error handling with proper status codes

### SQL

- Lowercase keywords
- snake_case naming convention

## Git Workflow

- Feature branches from `main`
- Conventional commits (feat:, fix:, docs:, etc.)
- PR required for main branch
- All CI checks must pass

## Security

- **Never commit secrets or API keys**
- Use environment variables for configuration
- Follow principle of least privilege for database access
- Implement proper input validation and sanitization
- Always verify RLS policies via Supabase MCP before deployment

## Feature Sliced Design (FSD) Rules

### Layer Structure

```
lib/
├── app/           # App-level configuration
├── entities/      # Shared business entities
├── features/      # Feature modules
├── pages/         # Route-level pages
└── shared/        # Shared utilities and components
```

### Segment Rules

- **api/**: External API integrations, data fetching
- **model/**: State management, business logic, domain services
- **ui/**: UI components, widgets, presentation layer

**Note**: The `entities/` layer typically contains only the `model/` segment, as entities represent pure domain models without direct API or UI concerns. The `api/` and `ui/` segments are more commonly found in `features/` layer where complete feature implementations reside.

## Development Principles

### Avoid Over-Engineering

- Only make changes that are directly requested or clearly necessary
- Keep solutions simple and focused
- Don't add features, refactor code, or make "improvements" beyond what was asked
- Don't add docstrings, comments, or type annotations to code you didn't change
- Only add comments where the logic isn't self-evident

### Error Handling

- Don't add error handling, fallbacks, or validation for scenarios that can't happen
- Trust internal code and framework guarantees
- Only validate at system boundaries (user input, external APIs)

### Abstractions

- Don't create helpers, utilities, or abstractions for one-time operations
- Don't design for hypothetical future requirements
- Three similar lines of code is better than a premature abstraction

### Backwards Compatibility

- Avoid backwards-compatibility hacks like renaming unused `_vars`
- Don't re-export types
- Don't add `// removed` comments for removed code
- If something is unused, delete it completely

## Best Practices Summary

### MUST: No Speculative Implementation

- Always use MCP tools to understand package, framework, and API specifications before implementation
- Research using Web search or Context7 MCP
- Never implement based on guesses

### MUST: Test-Driven Development

- Follow TDD principles
- Write tests based on expected inputs and outputs
- Commit tests first, then implement
- Never modify tests during implementation

### MUST: Use MCP Tools

- **Supabase MCP** > General database assumptions
- **Dart MCP** > Generic Flutter patterns
- **Context7** > Outdated documentation or practices
- **IDE MCP** > Manual error checking

### MUST: Quality Checks

- Run component-specific quality checks after every modification
- Fix all issues before proceeding
- Maintain 90%+ test coverage for new features
- Never commit failing code

## Important Notes

- This is a production-ready boilerplate
- Always use MCP tools for accurate, up-to-date information
- Maintain high code quality
- Ensure comprehensive testing
- Provide proper documentation for all changes
