# Quality Assurance & Development Workflow

## Mandatory Post-Modification Workflow

When Claude Code makes any changes:

1. **Identify Modified Component**: Determine which component was changed
2. **Run Component-Specific Checks**:
   - Frontend: `flutter pub run build_runner build && make fix-format-flutter && make check-flutter`
   - Edge Functions: `make fix-format-edge-functions && make check-edge-functions`
   - Backend: `make fix-format-backend && make check-backend`
   - Multiple: `flutter pub run build_runner build && make fix-format && make check-quality`
3. **Fix Any Issues**: Never proceed with failing checks
4. **Manual Review**: Human verification before commit

## Test-Driven Development (TDD) Requirements

**Mandatory TDD Workflow** for all development:

1. Write comprehensive test cases first
2. Follow Red-Green-Refactor cycle
3. Include regression tests when modifying existing code
4. Verify with quality checks after implementation

## Quality Gates

### Pre-commit Requirements

- All quality checks must pass
- Test coverage ≥ 90% for modified components
- No formatting issues
- No type errors or linting warnings

### If Quality Checks Fail

- Fix issues immediately
- Focus on the specific component that was modified
- Re-run checks until all pass
- Never commit failing code

## Development Workflow

### Standard Development Process with MCP Tools

1. **Research Phase**: Use Context7 MCP to research best practices and patterns
2. **Database Check**: Use Supabase MCP to verify current local database schema before modifications
3. **Implementation**:
   - Flutter/Dart: Consult Dart MCP for idiomatic patterns
   - Edge Functions: Reference TypeScript best practices via Context7
   - Python Backend: Use Context7 for FastAPI patterns
4. **Code Generation**: Use `make` commands for type safety (Riverpod, Drift)
5. **Schema Migration**: Use Drizzle for declarative schema management and migrations
6. **Verification**: Use IDE MCP to check for diagnostics and errors
7. **Quality Checks**: Run component-specific checks before commits

## MCP-Enhanced Development Flow

### For Flutter/Dart Development

```
1. Supabase MCP → Check local database schema
2. Dart MCP → Get widget/state management patterns
3. Implement code following FSD structure (create Freezed models manually)
4. flutter pub run build_runner build → Generate code (Freezed/Riverpod/i18n)
5. IDE MCP → Verify no errors
6. make check-flutter → Quality assurance
```

### For Database Changes (Drizzle)

```
1. Supabase MCP → Analyze current local database schema
2. Context7 → Research migration best practices with Drizzle
3. Update drizzle/schema/*.ts files (TypeScript schema definition)
4. make migrate-dev → Generate migrations, push to local DB, execute custom SQL, generate types
5. Supabase MCP → Verify changes in local database
6. make drizzle-studio → Visually inspect changes (optional)
```

### For Edge Functions

```
1. Supabase MCP → Check available tables/views in local database
2. Context7 → Research Deno/TypeScript patterns
3. Implement function
4. IDE MCP → Check for type errors
5. make check-edge-functions → Validate
```

## High-Risk Operations

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

## CI/CD Integration

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
