# Development Commands

## Initial Setup

```bash
make init                    # Full project initialization (installs dependencies, sets up DB)
```

## Running Services

```bash
make run                     # Start backend services with Docker + Supabase
make frontend                # Start Flutter web development (port 8080) - includes bootstrap
make frontend-ios            # Start iOS development
make frontend-android        # Start Android development
make stop                   # Stop all services
```

**IMPORTANT**: Always use `make frontend` for development server startup instead of direct `flutter run` commands. The make command ensures:

- Proper Melos bootstrap
- Correct environment variable loading
- Consistent port configuration (8080)
- Proper working directory setup

## Frontend Monorepo Commands (Melos)

```bash
make frontend-bootstrap                # Setup workspace and link packages
make frontend-generate                 # Run code generation (Riverpod, Drift)
make frontend-clean                    # Clean all packages
make frontend-test                     # Run unit and widget tests for all packages
make frontend-integration-test         # Run integration tests (requires device/simulator)
make frontend-integration-test-web     # Run web integration tests (requires device)
make frontend-integration-test-web-drive # Run web integration tests with flutter drive (requires ChromeDriver)
make frontend-test-all                 # Run all tests (unit, widget, integration)
make frontend-quality-check            # Run all quality checks
```

## Code Generation (Flutter)

```bash
# Generate Freezed models, Riverpod providers, and i18n translations
make frontend-generate                              # Generate all code (Freezed, Riverpod, Drift)
cd frontend/apps/web && flutter pub run build_runner build --delete-conflicting-outputs  # Force regeneration
cd frontend/apps/web && flutter pub run build_runner watch  # Watch mode for development
```

**Generated Code Types:**
- **Freezed**: Immutable data classes with copyWith, equality, serialization
- **Riverpod**: State management providers and notifiers
- **i18n**: Type-safe translations with slang
- **Drift**: SQLite database models (if used)

## Model Generation

```bash
make build-model                        # Generate Edge Functions models only
make build-model-functions              # Generate types for edge functions
```

**Frontend Model Strategy:**
- Frontend models are **manually created using Freezed** for type-safe immutable data classes
- No automatic type generation from database schema
- Use `build_runner` to generate Freezed code along with Riverpod and i18n

## Testing Commands

```bash
# Comprehensive testing
make test-all                      # Run all tests (unit, widget, integration) across all components

# Frontend testing
make frontend-test                 # Run unit and widget tests only
make frontend-integration-test     # Run integration tests for all apps
make frontend-integration-test-web # Run integration tests for web app
make frontend-test-all             # Run all frontend tests (unit, widget, integration)
```

**Test Types**:
- **Unit Tests**: Test individual functions and classes in isolation
- **Widget Tests**: Test Flutter widgets and UI components
- **Integration Tests**: Test complete user flows end-to-end with navigation and state

Note: `make test-all` includes unit, widget, and integration tests for Flutter, plus tests for Edge Functions and Backend when available.

## Quality Checks & Formatting

```bash
# Quality check commands
make check-quality          # Run all quality checks
make check-flutter         # Flutter-specific checks (analyze, test)
make check-edge-functions   # Edge Functions-specific checks
make check-backend         # Backend-specific checks (ruff)

# Code formatting commands
make fix-format            # Auto-fix all code formatting
make fix-format-flutter    # Auto-fix Flutter formatting only
make fix-format-edge-functions # Auto-fix Edge Functions formatting only
make fix-format-backend    # Auto-fix Backend formatting only

# Hook commands for file-specific checks
make hook-dart-check FILE_PATH=<path>    # Run Dart checks for specific file
make hook-python-check FILE_PATH=<path>  # Run Python checks for specific file
```

**IMPORTANT: Generated Files Handling**

Auto-generated files are automatically excluded from formatting checks:

- `*.g.dart` - build_runner, Riverpod, json_serializable
- `*.freezed.dart` - freezed
- `*.gr.dart` - auto_route
- `*/generated/*` - all files in generated directories
- `*/.dart_tool/*` - Dart tool cache
- `*/build/*` - build artifacts

The formatting commands automatically filter out these patterns, so generated files will not cause CI failures or require manual formatting.

## Deployment Commands

```bash
make deploy-functions  # Deploy all edge functions to Supabase
```
