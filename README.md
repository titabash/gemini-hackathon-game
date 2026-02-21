# Flutter Full-Stack Boilerplate

A production-ready full-stack Flutter application boilerplate with modular monorepo architecture

## 🚀 Overview

This boilerplate integrates all the essential elements needed for modern full-stack application development into a production-ready template.

### Key Features

- **Multi-platform Support**: Flutter frontend for iOS, Android, and Web
- **Modular Architecture**: Highly maintainable structure using Feature Sliced Design (FSD)
- **Multiple Backend Options**: Supabase Edge Functions (TypeScript/Deno) and Python FastAPI backend
- **Type Safety**: Type-safe database operations with Drizzle ORM and auto-generated type definitions
- **Real-time Capabilities**: Real-time data synchronization with Supabase
- **Comprehensive Testing**: TDD-focused development with unit, widget, integration, and E2E tests (Patrol)
- **Developer Experience**: Automated build, test, and deployment processes with quality hooks

## 📦 Technology Stack

### Frontend

- **Flutter** 3.35.6-stable - Multi-platform UI framework
- **Melos** - Monorepo management and workspace tooling
- **Riverpod** + **Flutter Hooks** - State management with code generation
- **GoRouter** - Declarative routing with authentication-aware navigation
- **Supabase Flutter** - Backend integration and real-time features
- **Dio** + **Retrofit** - HTTP client with type-safe API integration (core/api)
- **Drift** - Local database with type-safe queries
- **Slang** - Type-safe internationalization (i18n) with code generation
- **Patrol** - E2E testing framework with native automation support

#### Core Packages

- **core/api** - Centralized API client with Dio and Retrofit
- **core/auth** - Authentication state management and utilities
- **core/i18n** - Internationalization with slang (type-safe translations)
  - JSON-based translation files in `translations/`
  - Auto-generated type-safe access via build_runner
  - Riverpod integration for reactive language switching
  - SharedPreferences for language preference persistence
- **core/utils** - Shared utilities, logger, and constants
- **shared/ui** - Reusable UI components across applications

### Backend

#### Edge Functions (Recommended)

- **Deno Runtime** - TypeScript execution environment
- **Supabase Functions** - Serverless functions
- Ideal for lightweight business logic and API endpoints

#### Python Backend (For Complex Processing)

- **FastAPI** - High-performance Python web framework
- **SQLModel** - Type-safe ORM with synchronous database operations
- **LangChain** - AI/LLM integration
- **aiortc/LiveKit** - WebRTC support
- Suitable for transaction processing and complex computations

### Database & Infrastructure

- **Supabase (PostgreSQL)** - Primary database
- **Drizzle ORM** - TypeScript-first ORM for schema management, migrations, and Edge Functions
- **Docker** - Containerized development environment
- **Make** - Task automation
- **Bun** - Fast JavaScript runtime for Drizzle tooling
- **Node.js** 24.10.0 - JavaScript runtime for tooling
- **Python** 3.13.9 - Backend runtime

## 🏗 Project Structure

```
.
├── frontend/              # Flutter Monorepo (managed by Melos)
│   ├── melos.yaml         # Monorepo configuration
│   ├── apps/              # Applications
│   │   └── web/           # Main web application
│   │       ├── lib/
│   │       │   ├── app/          # App configuration (router, theme, etc.)
│   │       │   │   └── router/   # GoRouter configuration
│   │       │   ├── entities/     # Shared business entities (FSD)
│   │       │   ├── features/     # Feature modules (FSD)
│   │       │   │   ├── counter/  # Example: Counter feature
│   │       │   │   └── auth/     # Authentication feature
│   │       │   ├── pages/        # Route pages
│   │       │   └── shared/       # Shared utilities
│   │       ├── test/             # Unit and widget tests
│   │       ├── integration_test/ # Integration tests
│   │       └── patrol_test/      # Patrol E2E tests
│   │           ├── mobile/       # Mobile platform tests (iOS/Android)
│   │           │   ├── smoke/    # Smoke tests
│   │           │   └── auth/     # Authentication flow tests
│   │           └── web/          # Web platform tests
│   │               ├── smoke/    # Smoke tests
│   │               └── auth/     # Authentication flow tests
│   └── packages/          # Shared packages
│       ├── core/
│       │   ├── api/       # API client (Dio + Retrofit)
│       │   ├── auth/      # Authentication utilities
│       │   ├── i18n/      # Internationalization (slang)
│       │   └── utils/     # Common utilities and logger
│       └── shared/
│           └── ui/        # Shared UI components
│
├── backend-py/           # Python FastAPI backend
│   └── app/
│       └── src/
│           ├── controller/  # HTTP endpoints
│           ├── usecase/     # Application services
│           ├── domain/      # Domain logic
│           ├── gateway/     # Data access layer
│           └── infra/       # External service integrations
│
├── supabase/
│   ├── functions/        # Edge Functions (TypeScript/Deno)
│   │   ├── domain/       # Shared type definitions
│   │   ├── infra/        # Infrastructure (Drizzle client, etc.)
│   │   └── helloworld/   # Sample function
│   └── migrations/       # Generated migration files (by Drizzle)
│
├── drizzle/              # Database schema (Drizzle ORM)
│   ├── drizzle.config.ts # Drizzle configuration
│   ├── schema/           # Schema definitions (TypeScript)
│   ├── config/           # Custom SQL files (functions, triggers, extensions)
│   └── migrate.ts        # Custom migration script
│
└── env/                  # Environment configuration
    ├── frontend/         # Frontend environment variables
    └── backend/          # Backend environment variables
```

## 🔧 Requirements

### Required Tools

- [Docker](https://www.docker.com/) - Container runtime
- [asdf](https://asdf-vm.com/) - Version management tool (manages Flutter, Node.js, Python versions)
- [Flutter](https://flutter.dev/) 3.35.6-stable - Flutter framework
- [Node.js](https://nodejs.org/) 24.10.0 - JavaScript runtime
- [Python](https://www.python.org/) 3.13.9 - Python runtime
- [Supabase CLI](https://supabase.com/docs/guides/cli) - Supabase development tools
- Make - Build tool

### Recommended Development Environment

- **VSCode** - Integrated Development Environment
  - Flutter/Dart extensions
  - ESLint/Prettier extensions

## 🚀 Setup

### 1. Initialize the Project

```bash
# Install required tools and initial setup
make init
```

This command will:

- Check for and install necessary tools
- Set up language versions with asdf
- Log in to and initialize Supabase
- Install dependencies (Drizzle, Flutter packages, Patrol CLI)
- Run initial database migrations
- Generate type definitions

### 2. Configure Environment Variables

Copy `env/secrets.env.example` to create `env/secrets.env` and set the required values:

```bash
cp env/secrets.env.example env/secrets.env
```

Key configuration items:

- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Supabase anonymous key
- `DATABASE_URL` - Database connection string
- Various AI/LLM provider API keys (as needed)

### 3. Database Setup

```bash
# Run migrations
make migration

# Seed initial data (optional)
make seed
```

## 💻 Development

### Starting Services

```bash
# Start backend services and Supabase
make run

# Start frontend (in separate terminal)
make frontend              # Web version (port 8080)
make frontend-ios          # iOS version
make frontend-android      # Android version
```

### Stopping Services

```bash
make stop
```

### Frontend Monorepo Commands (Melos)

```bash
# Setup and bootstrap workspace (link packages)
make frontend-bootstrap

# Code generation (Riverpod, i18n, Drift)
make frontend-generate
# Or use Melos directly:
cd frontend && melos run generate

# Run all quality checks (analyze + test)
make frontend-quality-check
# Or use Melos directly:
cd frontend && melos run quality_check

# Run tests for all packages
make frontend-test

# Clean all packages
make frontend-clean
```

## 📝 Main Make Commands

### Development Commands

| Command                       | Description                           |
| ----------------------------- | ------------------------------------- |
| `make init`                   | Initialize the project                |
| `make run`                    | Start backend services                |
| `make frontend`               | Start Flutter web dev server          |
| `make frontend-ios`           | Start iOS development                 |
| `make frontend-android`       | Start Android development             |
| `make frontend-bootstrap`     | Setup and link monorepo packages      |
| `make frontend-generate`      | Generate code (Riverpod, i18n, Drift) |
| `make frontend-quality-check` | Run all quality checks                |
| `make frontend-test`          | Run tests for all packages            |
| `make frontend-clean`         | Clean all packages                    |
| `make stop`                   | Stop all services                     |

### Database Management (Drizzle)

| Command               | Description                                                                       |
| --------------------- | --------------------------------------------------------------------------------- |
| `make migrate-dev`    | Generate migrations, push schema, execute custom SQL, generate types (local only) |
| `make migrate-deploy` | Apply existing migrations (all environments)                                      |
| `make migrate-status` | Show migration history                                                            |
| `make drizzle-studio` | Open Drizzle Studio (visual DB management)                                        |
| `make seed`           | Seed database (manual implementation required)                                    |
| `make db-reset`       | Reset database (local only)                                                       |

#### Drizzle Workflow

1. **Development**: `make migrate-dev` generates migrations from TypeScript schema, pushes to DB, executes custom SQL, and generates type definitions
2. **Production**: `make migrate-deploy` applies existing migration files via Supabase CLI
3. **Visual Management**: `make drizzle-studio` opens a web-based database browser

#### Deprecated Commands

| Command               | Replacement                                                           |
| --------------------- | --------------------------------------------------------------------- |
| `make migration`      | Use `make migrate-dev` instead                                        |
| `make init-migration` | Use `make migrate-dev` instead                                        |
| `make rollback`       | Manual rollback (remove migration file or create reverting migration) |

### Model Generation

| Command                              | Description                   |
| ------------------------------------ | ----------------------------- |
| `make build-model`                   | Generate all models           |
| `make build-model-frontend-supabase` | Generate Supabase types       |
| `make build-model-functions`         | Generate Edge Functions types |

### Quality Management

| Command                          | Description                                                 |
| -------------------------------- | ----------------------------------------------------------- |
| `make check-quality`             | Run all quality checks (Flutter + Edge Functions + Backend) |
| `make ci-check`                  | CI checks (same as check-quality, for GitHub Actions)       |
| `make check-flutter`             | Flutter code analysis                                       |
| `make check-edge-functions`      | Edge Functions code analysis                                |
| `make check-backend`             | Backend code analysis                                       |
| `make fix-format`                | Auto-format all code (Flutter + Edge Functions + Backend)   |
| `make fix-format-flutter`        | Auto-format Flutter code only                               |
| `make fix-format-edge-functions` | Auto-format Edge Functions code only                        |
| `make fix-format-backend`        | Auto-format Backend code only                               |
| `make test-all`                  | Run all tests                                               |
| `make hook-dart-check`           | Run Dart checks for hooks (requires FILE_PATH)              |
| `make hook-python-check`         | Run Python checks for hooks (requires FILE_PATH)            |

### E2E Testing (Patrol)

| Command                  | Description                                |
| ------------------------ | ------------------------------------------ |
| `make patrol-install`    | Install Patrol CLI (auto-installed in init) |
| `make patrol-test`       | Run all Patrol E2E tests                   |
| `make patrol-test-web`   | Run Web platform tests only                |
| `make patrol-test-mobile`| Run Mobile platform tests (iOS/Android)    |
| `make patrol-test-smoke` | Run smoke tests only                       |

### Deployment

| Command                 | Description           |
| ----------------------- | --------------------- |
| `make deploy-functions` | Deploy Edge Functions |

## 🏛 Architecture

### Frontend Architecture

#### Monorepo Structure (Melos)

The frontend is organized as a monorepo with:

- **apps/web/** - Main application following FSD
- **packages/core/** - Core functionality packages
  - **api/** - Centralized API client (Dio + Retrofit)
  - **auth/** - Authentication state and utilities
  - **i18n/** - Type-safe internationalization (slang)
  - **utils/** - Common utilities and logging
- **packages/shared/ui/** - Reusable UI components

#### Feature Sliced Design (FSD)

The main application (apps/web/) follows FSD architecture:

- **app/** - Application-level configuration
  - **router/** - GoRouter configuration with authentication guards
- **entities/** - Business entities and shared models
- **features/** - Feature-based modules
  - **api/** - API integration layer
  - **model/** - State management and business logic (Riverpod)
  - **ui/** - UI components
- **pages/** - Routable page components
- **shared/** - Shared utilities and components

### Backend Architecture

#### Edge Functions (Recommended)

- Lightweight and fast serverless functions
- TypeScript/Deno runtime
- Direct Supabase integration
- Optimal for real-time processing

#### Python Backend (For Complex Processing)

- Layered architecture (Clean Architecture)
- Synchronous database operations (SQLModel with sync sessions)
- Transaction processing
- AI/ML integration (LangChain, various LLM providers)

## 🔐 Security

- **Row Level Security (RLS)** - Database-level access control
- **JWT Authentication** - Authentication management via Supabase
- **Environment Variables** - Secret management with dotenv
- **Type Safety** - Type checking with Drizzle ORM and TypeScript

## 🧪 Testing

This project follows Test-Driven Development (TDD) practices with comprehensive testing coverage.

### Test Types

#### 1. Unit Tests

Test individual functions, classes, and business logic in isolation.

```bash
# Run unit tests for all packages
make frontend-test
```

#### 2. Widget Tests

Test Flutter widgets and UI components.

```bash
# Run widget tests (included in frontend-test)
cd frontend/apps/web && flutter test
```

#### 3. Integration Tests

Test complete user flows with navigation and state management.

```bash
# Run integration tests (requires device/simulator)
make frontend-integration-test

# Web integration tests (requires ChromeDriver)
make frontend-integration-test-web
```

#### 4. E2E Tests (Patrol)

Test complete user journeys with native automation support.

```bash
# Run all E2E tests
make patrol-test

# Run platform-specific tests
make patrol-test-web      # Web only
make patrol-test-mobile   # Mobile only (requires device/simulator)
make patrol-test-smoke    # Quick smoke tests
```

**Patrol Features**:
- ✅ Native automation (permissions, notifications, system settings)
- ✅ Cross-platform (iOS, Android, macOS, Web)
- ✅ Hot restart for faster test execution
- ✅ Type-safe Dart code with IDE support

### Run All Tests

```bash
# Run all tests (unit, widget, integration, E2E) for all components
make test-all
```

Note: `make test-all` internally runs tests for all components (Flutter, Edge Functions, Backend) based on what's available in the project.

### Test Organization

```
frontend/apps/web/
├── test/              # Unit and widget tests
├── integration_test/  # Integration tests
└── patrol_test/       # E2E tests with Patrol
    ├── mobile/        # Mobile platform tests
    │   ├── smoke/     # Basic smoke tests
    │   └── auth/      # Authentication flows
    └── web/           # Web platform tests
        ├── smoke/     # Basic smoke tests
        └── auth/      # Authentication flows
```

### Testing Best Practices

1. **TDD Workflow**: Write tests first, then implement features
2. **Test Isolation**: Each test should be independent
3. **Mocking**: Use `mock_supabase_http_client` for Supabase integration tests
4. **Coverage**: Aim for ≥90% code coverage for new features
5. **CI Integration**: All tests run automatically in GitHub Actions

For detailed testing guidelines, see [`.claude/skills/patrol/`](./.claude/skills/patrol/) and [`.claude/rules/tdd.md`](./.claude/rules/tdd.md).

## 📚 Documentation

### Project Guidelines

- [CLAUDE.md](./CLAUDE.md) - AI development assistant (Claude Code) guidelines
- [AGENTS.md](./AGENTS.md) - AI coding assistant guidelines
- [CONTRIBUTING.md](./CONTRIBUTING.md) - Contribution guidelines
- [SECURITY.md](./SECURITY.md) - Security policy and best practices

### Technical Documentation

- [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) - Detailed architecture overview
- [docs/DEVELOPMENT.md](./docs/DEVELOPMENT.md) - Development workflow and best practices
- [docs/DEPLOYMENT.md](./docs/DEPLOYMENT.md) - Deployment procedures
- [docs/TESTING.md](./docs/TESTING.md) - Testing strategy and TDD workflow

### Claude Code Skills

The project includes comprehensive skill guides for AI-assisted development:

- [`.claude/skills/`](./.claude/skills/) - Complete skills documentation
  - **Flutter Development**: flutter-feature, flutter-model, flutter-provider, flutter-test, flutter-generate
  - **E2E Testing**: patrol (native automation, cross-platform testing)
  - **Supabase**: supabase-edge-function, supabase-migration
  - See [`.claude/skills/README.md`](./.claude/skills/README.md) for full skill catalog

### Reference

- [Makefile](./Makefile) - Detailed command reference

## 🤝 Contributing

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Create a Pull Request

### Commit Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `style:` Code style changes
- `refactor:` Code refactoring
- `test:` Test additions/modifications
- `chore:` Build process or auxiliary tool changes

## 🔮 Roadmap

- [x] GoRouter implementation - Implemented with authentication-aware routing
- [x] Internationalization (i18n) - Implemented with Slang
- [x] Monorepo structure with Melos - Fully implemented with modular packages
- [x] E2E testing - Implemented with Patrol (native automation support)
- [ ] CI/CD pipeline setup
- [ ] Performance monitoring
- [ ] Error tracking (Sentry integration)
- [ ] Payment processing (Stripe/RevenueCat)

## 📄 License

This project is released under the MIT License.

## 🙏 Acknowledgments

This boilerplate is built upon the excellent contributions from the Flutter, Supabase, and FastAPI communities.

---

**For questions or issues regarding development, please create an Issue.**
