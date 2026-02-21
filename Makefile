# プラットフォームと環境を設定
PLATFORM=web
ENV=local

# 初期化コマンド
# プロジェクトの初期セットアップを実行します
# - 必要なツールの確認
# - asdfによる言語バージョン管理
# - Supabaseのセットアップ（local環境のみ起動）
# - 環境変数ファイルの準備
# - 依存関係のインストール（Drizzle, Flutter, Patrol CLI）
# - データベースの初期化とモデル生成
.PHONY: init
init:
	# 必要なツールがインストールされているかチェック
	sh ./bin/check_install.sh
	# asdfをインストール
	asdf install
	# dotenvxをインストール
	npm install -g @dotenvx/dotenvx;
	# Bunのインストール確認（Drizzle用）
	@if ! command -v bun >/dev/null 2>&1; then \
		echo "Installing Bun..."; \
		curl -fsSL https://bun.sh/install | bash; \
		echo "✅ Bun installed successfully"; \
		echo "⚠️  Please restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"; \
	else \
		echo "✅ Bun is already installed"; \
	fi
	# Supabaseにログイン（環境変数を読み込んで実行）
	npx dotenvx run -f env/backend/${ENV}.env -- supabase login
	# Supabaseを初期化（環境変数を読み込んで実行）
	yes 'N' | npx dotenvx run -f env/backend/${ENV}.env -- supabase init --force
	# Supabaseを起動（ENV=localの場合のみ）
	if [ "${ENV}" = "local" ]; then \
		npx dotenvx run -f env/backend/${ENV}.env -- supabase start; \
	fi
	# シークレットの設定がなければコピー
	if [ ! -f "env/secrets.env" ]; then \
		cp env/secrets.env.example env/secrets.env; \
	fi
	@if [ ! -f ".env" ]; then \
		echo "Creating .env file for Docker Compose..."; \
		echo "PROJECT_NAME=$$(basename $$(pwd))" > .env; \
		echo "✅ Created .env with PROJECT_NAME=$$(basename $$(pwd))"; \
	else \
		echo "ℹ️  .env file already exists, skipping creation"; \
	fi
	# env/backend/local.envのflutter-boilerplateをプロジェクト名に置換
	@if [ -f "env/backend/local.env" ]; then \
		PROJECT_NAME=$$(basename $$(pwd)); \
		echo "Updating env/backend/local.env with PROJECT_NAME=$$PROJECT_NAME..."; \
		sed -i.bak "s/flutter-boilerplate/$$PROJECT_NAME/g" env/backend/local.env; \
		rm -f env/backend/local.env.bak; \
		echo "✅ Updated env/backend/local.env with PROJECT_NAME=$$PROJECT_NAME"; \
	else \
		echo "⚠️  env/backend/local.env not found, skipping update"; \
	fi
	# Drizzleの依存関係をインストール
	cd drizzle && bun install
	# フロントエンドの依存関係をインストール
	cd frontend && flutter pub get
	# Patrol CLIのインストール確認（E2Eテスト用）
	@if ! command -v patrol >/dev/null 2>&1; then \
		echo "Installing Patrol CLI for E2E testing..."; \
		flutter pub global activate patrol_cli; \
		echo "✅ Patrol CLI installed successfully"; \
		echo "⚠️  Ensure ~/.pub-cache/bin is in your PATH"; \
	else \
		echo "✅ Patrol CLI is already installed"; \
	fi
	@echo ""
	@echo "✅ Initial setup complete!"
	@echo ""
	@echo "📝 Next steps:"
	@echo "  1. Run 'make migrate-dev' to generate and apply initial database migrations"
	@echo "  2. Run 'make run' to start backend services"
	@echo "  3. Run 'make frontend' to start frontend development server"
	@echo ""
	@echo "Woo-hoo! Everything's ready to roll!"

# ローカル環境での起動コマンド
# Supabase（local環境のみ）とバックエンドサービスを起動します
.PHONY: run
run:
	# プロジェクト名を設定
	export PROJECT_NAME=$$(basename $$(pwd))
	# # 共通の.git設定のファイルをコピー
	# make copy-git-config
	# Supabaseを起動（ENV=localの場合のみ）
	if [ "${ENV}" = "local" ]; then \
		npx dotenvx run -f env/backend/${ENV}.env -- supabase start; \
		npx dotenvx run -f env/backend/${ENV}.env -- supabase seed buckets --local; \
	fi
	# Docker Composeでバックエンドサービスを起動
	if [ "${ENV}" != "local" ]; then \
		export ENV=${ENV}; \
	fi
	docker-compose -f ./docker-compose.backend.yaml up -d --force-recreate


# Frontend commands (Melos)
.PHONY: frontend-bootstrap frontend-clean frontend-generate frontend-test frontend-integration-test frontend-integration-test-web frontend-integration-test-web-drive frontend-test-all frontend-quality-check

frontend-bootstrap:
	cd frontend && melos bootstrap

frontend-clean:
	cd frontend && melos clean

frontend-generate:
	cd frontend/apps/web && dart run build_runner build --delete-conflicting-outputs

frontend-test:
	cd frontend && melos run test

frontend-integration-test:
	cd frontend && melos run integration_test

frontend-integration-test-web:
	cd frontend && melos run integration_test_web

frontend-integration-test-web-drive:
	cd frontend && melos run integration_test_web_drive

frontend-test-all:
	cd frontend && melos run test_all

frontend-quality-check:
	cd frontend && dart analyze . && dart format --set-exit-if-changed . && flutter test

# ローカル環境でのフロントエンド起動コマンド
# Flutter webアプリケーションを開発モードで起動します
.PHONY: frontend
frontend: frontend-bootstrap
	cd frontend/apps/web && flutter run -d chrome --web-port=8080 --dart-define-from-file=../../../env/frontend/${ENV}.json

# ローカル環境での停止コマンド
# Supabase（local環境のみ）とバックエンドサービスを停止します
.PHONY: stop
stop:
	if [ "${ENV}" != "local" ]; then \
		export ENV=${ENV}; \
	fi
	docker-compose -f ./docker-compose.backend.yaml down
	# Supabaseを停止（ENV=localの場合のみ）
	if [ "${ENV}" = "local" ]; then \
		npx dotenvx run -f env/backend/${ENV}.env -- supabase stop; \
	fi

# iOS用のローカル起動コマンド
.PHONY: frontend-ios
frontend-ios:
	cd frontend/apps/web && flutter run -d ios --dart-define-from-file=../../../env/frontend/${ENV}.json

# Android用のローカル起動コマンド
.PHONY: frontend-android
frontend-android:
	cd frontend/apps/web && flutter run -d android --dart-define-from-file=../../../env/frontend/${ENV}.json

# フロントエンドビルドコマンド
# Flutter webアプリケーションをプロダクションビルドします
.PHONY: build-frontend
build-frontend:
	@echo "Building Flutter web application..."
	cd frontend/apps/web && flutter build web

# Edge Functionsデプロイコマンド
# supabase/functions/配下の全関数を自動検出してデプロイします
# ENV=local以外の環境でのみ実行されます
.PHONY: deploy-functions
deploy-functions:
	# ENV=localの場合はスキップ、それ以外は自動検出してデプロイ
	if [ "${ENV}" != "local" ]; then \
		npx dotenvx run -f env/backend/${ENV}.env -- bash -c '\
			for dir in supabase/functions/*/; do \
				if [ -f "$${dir}index.ts" ]; then \
					func_name=$$(basename $$dir); \
					echo "Deploying function: $$func_name"; \
					supabase functions deploy $$func_name --no-verify-jwt --project-ref $$SUPABASE_PROJECT_REF; \
				fi; \
			done'; \
	else \
		echo "Skipping deploy-functions for local environment"; \
	fi

# サービス状態確認コマンド
# SupabaseとDocker Composeサービスの状態を確認します
.PHONY: check
check:
	@echo "Checking service status..."
	export PROJECT_NAME=$$(basename $$(pwd))
	# Supabaseの状態確認（ENV=localの場合のみ）
	if [ "${ENV}" = "local" ]; then \
		npx dotenvx run -f env/backend/${ENV}.env -- supabase status; \
	fi
	# バックエンドサービスの状態確認
	docker-compose -f ./docker-compose.backend.yaml ps

# 共通の.git設定のファイルをコピー
# プリコミットフックなども含む
.PHONY: copy-git-config
copy-git-config:
	\cp -f .git-dev/info/exclude .git/info/exclude

.PHONY: build-model-backend
build-model-backend:
	# ENV=localの場合のみ実行
	if [ "${ENV}" = "local" ]; then \
		npx dotenvx run -f env/backend/${ENV}.env -- supabase start; \
		docker-compose -f ./docker-compose.backend.yaml restart; \
	fi

# Edge functionsのモデルをビルド
# Supabaseのデータベーススキーマから型定義を生成し、Drizzleスキーマをコピーします
.PHONY: build-model-functions
build-model-functions:
	# Supabaseを起動（ENV=localの場合のみ）
	if [ "${ENV}" = "local" ]; then \
		npx dotenvx run -f env/backend/${ENV}.env -- supabase start; \
	fi
	# Supabase型を生成
	mkdir -p ./supabase/functions/shared/supabase && npx dotenvx run -f env/backend/${ENV}.env -- supabase gen types typescript --local > ./supabase/functions/shared/supabase/schema.ts
	# Drizzleスキーマをコピー（Edge Functions用）
	mkdir -p ./supabase/functions/shared/drizzle && cp -r ./drizzle/schema/* ./supabase/functions/shared/drizzle/
	@echo "✅ Copied Drizzle schema to supabase/functions/shared/drizzle/"

# モデルをビルド
# Edge Functions用の型定義を生成します
# フロントエンドはFreezedで手動作成するため、型生成は不要
.PHONY: build-model
build-model:
	# Edge functionsのモデルをビルド
	make build-model-functions
	# Backendのモデルをビルド
	make build-model-backend

# ===== Drizzle マイグレーションコマンド =====

# 開発用マイグレーション（Drizzle development workflow）
# ローカル環境専用: マイグレーション生成 → 適用 → カスタムSQL実行 → 型生成を一括実行
.PHONY: migrate-dev
migrate-dev:
	@# ENVが指定されていて、かつlocal以外の場合は警告
	@if [ -n "${ENV}" ] && [ "${ENV}" != "local" ]; then \
		echo "⚠️  ERROR: migrate-dev is for local development only!"; \
		echo "Specified ENV: ${ENV}"; \
		echo ""; \
		echo "Use 'ENV=${ENV} make migrate-deploy' for remote environments."; \
		exit 1; \
	fi
	@echo "🚀 Running migrate-dev (generate + apply + build-model)..."
	@echo ""
	# Supabaseを起動
	npx dotenvx run -f env/backend/local.env -- supabase start
	# Pre-migration SQL適用（extensions等）
	@echo "🔧 Applying pre-migration SQL (extensions)..."
	cd drizzle && npx dotenvx run -f ../env/migration/local.env -- bun run migrate:pre
	# マイグレーションを生成
	@echo "📝 Generating migration..."
	cd drizzle && npx dotenvx run -f ../env/migration/local.env -- bun run generate
	# マイグレーションを適用
	@echo "✅ Applying migration to local database..."
	cd drizzle && npx dotenvx run -f ../env/migration/local.env -- bun run migrate
	# Post-migration SQL適用（functions/triggers等）
	@echo "🔧 Applying post-migration SQL (functions, triggers)..."
	cd drizzle && npx dotenvx run -f ../env/migration/local.env -- bun run migrate:post
	# モデル生成
	@echo "🔧 Generating database types..."
	make build-model
	@echo ""
	@echo "✨ Done! Don't forget to commit migration files to Git."

# 本番用マイグレーション適用（Drizzle production deployment）
# 全環境で使用可能: 既存のマイグレーションファイルを適用するだけ
.PHONY: migrate-deploy
migrate-deploy:
	@echo "🚀 Deploying migrations to ${ENV} environment..."
	@echo ""
	# Supabaseを起動（ENV=localの場合のみ）
	if [ "${ENV}" = "local" ] || [ -z "${ENV}" ]; then \
		npx dotenvx run -f env/backend/local.env -- supabase start; \
	fi
	# Pre-migration SQL適用（extensions等）
	@echo "🔧 Applying pre-migration SQL (extensions)..."
	@if [ -z "${ENV}" ] || [ "${ENV}" = "local" ]; then \
		cd drizzle && npx dotenvx run -f ../env/migration/local.env -- bun run migrate:pre; \
	else \
		cd drizzle && npx dotenvx run -f ../env/migration/${ENV}.env -- bun run migrate:pre; \
	fi
	# マイグレーションを適用
	@if [ -z "${ENV}" ] || [ "${ENV}" = "local" ]; then \
		echo "📍 Deploying to: local"; \
		cd drizzle && npx dotenvx run -f ../env/migration/local.env -- bun run migrate; \
	else \
		echo "📍 Deploying to: ${ENV}"; \
		cd drizzle && npx dotenvx run -f ../env/migration/${ENV}.env -- bun run migrate; \
	fi
	# Post-migration SQL適用（functions/triggers等）
	@echo "🔧 Applying post-migration SQL (functions, triggers)..."
	@if [ -z "${ENV}" ] || [ "${ENV}" = "local" ]; then \
		cd drizzle && npx dotenvx run -f ../env/migration/local.env -- bun run migrate:post; \
	else \
		cd drizzle && npx dotenvx run -f ../env/migration/${ENV}.env -- bun run migrate:post; \
	fi
	# モデル生成（ローカルのみ）
	@if [ -z "${ENV}" ] || [ "${ENV}" = "local" ]; then \
		make build-model; \
	fi
	@echo ""
	@echo "✅ Migration deployment complete!"

# スキーマを直接DBにプッシュ（開発時の高速プロトタイピング用）
# NOTE: マイグレーションファイルは生成されません
.PHONY: drizzle-push
drizzle-push:
	@echo "⚠️  WARNING: This bypasses migration history!"
	@echo "🚀 Pushing schema directly to database..."
	@echo ""
	npx dotenvx run -f env/backend/local.env -- supabase start
	cd drizzle && npx dotenvx run -f ../env/migration/local.env -- bun run push
	cd drizzle && npx dotenvx run -f ../env/migration/local.env -- bun run migrate:custom
	@echo "✅ Schema pushed successfully!"

# Drizzle Studio（データベースGUI）
.PHONY: drizzle-studio
drizzle-studio:
	@echo "🖥️  Starting Drizzle Studio..."
	@echo "Opening at http://localhost:4983"
	cd drizzle && npx dotenvx run -f ../env/migration/local.env -- bun run studio

# スキーマ検証（Drizzleベース）
.PHONY: drizzle-validate
drizzle-validate:
	@echo "✅ Validating Drizzle schema..."
	cd drizzle && npx dotenvx run -f ../env/migration/local.env -- bun run check

# マイグレーション履歴の表示
.PHONY: migrate-status
migrate-status:
	@echo "📋 Migration status for ${ENV} environment..."
	@if [ -z "${ENV}" ] || [ "${ENV}" = "local" ]; then \
		npx dotenvx run -f env/backend/local.env -- supabase migration list; \
	else \
		npx dotenvx run -f env/backend/${ENV}.env -- supabase migration list; \
	fi

# データベースシードコマンド
# supabase/seed.sql を既存DBに追加投入する（DBリセットなし）
# ON CONFLICT DO NOTHING により既存データがあってもエラーにならない
.PHONY: seed
seed:
	@echo "🌱 Applying seed data (supabase/seed.sql)..."
	npx dotenvx run -f env/migration/local.env -- bash -c 'psql "$$DATABASE_URL" -f supabase/seed.sql'
	@echo "✅ Seed data applied!"

# ロールバックコマンド
.PHONY: rollback
rollback:
	@echo "⚠️  Drizzle does not have built-in rollback command."
	@echo "For rollback, use one of these approaches:"
	@echo "  1. Manually remove the last migration file from supabase/migrations/"
	@echo "     and run 'make migrate-deploy' to apply the reverted state."
	@echo "  2. Create a new migration that reverts the changes."
	@echo "  3. Use 'make db-reset' for local development (drops all data)."
	@exit 1

# データベースリセットコマンド
# supabase db reset がマイグレーション適用 + seed.sql 実行を行うため、
# その後は post-migration SQL とモデル生成のみ実行する（migrate-dev の再実行は不要）
.PHONY: db-reset
db-reset:
	@echo "⚠️  Warning: This will drop and recreate the database!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	@if [ -z "${ENV}" ] || [ "${ENV}" = "local" ]; then \
		echo "🔄 Resetting Supabase database..."; \
		npx dotenvx run -f env/backend/local.env -- supabase db reset; \
		echo "🔧 Applying post-migration SQL (functions, triggers)..."; \
		cd drizzle && npx dotenvx run -f ../env/migration/local.env -- bun run migrate:post; \
		echo "🔧 Generating database types..."; \
		make build-model; \
		echo "✅ Database reset complete!"; \
	else \
		echo "❌ db-reset is only available for local environment"; \
		exit 1; \
	fi

# ===== 後方互換性のためのエイリアス =====

# 旧コマンド名との互換性を保つ
.PHONY: migration
migration:
	@echo "ℹ️  'make migration' is deprecated. Use 'make migrate-dev' instead."
	@make migrate-dev

.PHONY: init-migration
init-migration:
	@echo "ℹ️  'make init-migration' is deprecated. Use 'make migrate-dev' instead."
	@make migrate-dev

# CI/CD Pipeline Integration
.PHONY: check-quality
check-quality:
	@echo "Running all quality checks..."
	make check-flutter
	make check-edge-functions
	make check-backend
	@echo "All quality checks completed!"

# CI用の全チェック（GitHub Actions等で使用） - エラーがあっても全チェックを実行
.PHONY: ci-check
ci-check:
	@echo "Running CI checks..."
	@echo "=== Step 1/4: Quality Checks (Lint & Format) ==="
	@make check-quality || (echo "Quality checks failed but continuing..." && exit 0)
	@echo ""
	@echo "=== Step 2/4: Type Check - Backend Python ==="
	@if [ -d "backend-py/app" ]; then \
		cd backend-py/app && \
		if command -v uv >/dev/null 2>&1; then \
			echo "Running mypy type check..."; \
			uv run mypy src || echo "Type check failed or mypy not configured"; \
		else \
			echo "uv not installed, skipping type check"; \
		fi; \
	fi
	@echo ""
	@echo "=== Step 3/4: Test - Flutter ==="
	@echo "Flutter tests already run in check-quality"
	@echo ""
	@echo "=== Step 4/4: Test - Backend Python ==="
	@if [ -d "backend-py/app" ]; then \
		cd backend-py/app && \
		if command -v uv >/dev/null 2>&1; then \
			echo "Running pytest..."; \
			uv run pytest || echo "Tests failed or pytest not configured"; \
		else \
			echo "uv not installed, skipping tests"; \
		fi; \
	fi
	@echo ""
	@echo "All CI checks completed!"

# CI用の全チェック（厳格版） - エラーがあれば停止
.PHONY: ci-check-strict
ci-check-strict:
	@echo "Running CI checks (strict mode)..."
	@echo "=== Step 1/4: Quality Checks (Lint & Format) ==="
	make check-quality
	@echo ""
	@echo "=== Step 2/4: Type Check - Backend Python ==="
	@if [ -d "backend-py/app" ]; then \
		cd backend-py/app && \
		if command -v uv >/dev/null 2>&1; then \
			echo "Running mypy type check..."; \
			uv run mypy src; \
		else \
			echo "uv not installed, skipping type check"; \
		fi; \
	fi
	@echo ""
	@echo "=== Step 3/4: Test - Flutter ==="
	@echo "Flutter tests already run in check-quality"
	@echo ""
	@echo "=== Step 4/4: Test - Backend Python ==="
	@if [ -d "backend-py/app" ]; then \
		cd backend-py/app && \
		if command -v uv >/dev/null 2>&1; then \
			echo "Running pytest..."; \
			uv run pytest; \
		else \
			echo "uv not installed, skipping tests"; \
		fi; \
	fi
	@echo ""
	@echo "All CI checks completed!"

# 全プロジェクトのフォーマット自動修正
.PHONY: fix-format
fix-format:
	@echo "Auto-fixing all code formatting..."
	make fix-format-flutter
	make fix-format-edge-functions
	make fix-format-backend
	@echo "All code formatting completed!"

.PHONY: check-flutter
check-flutter:
	@echo "Running Flutter quality checks..."
	# Melos bootstrap
	cd frontend && melos bootstrap
	# 静的解析
	cd frontend && dart analyze .
	# テスト実行（web_appのみ）
	cd frontend/apps/web && flutter test || echo "Tests failed or not found"
	# フォーマットチェック（自動生成ファイルを除外）
	cd frontend && find . -name "*.dart" \
		! -name "*.g.dart" \
		! -name "*.freezed.dart" \
		! -name "*.gr.dart" \
		! -path "*/generated/*" \
		! -path "*/.dart_tool/*" \
		! -path "*/build/*" \
		-exec dart format --set-exit-if-changed {} +
	@echo "Flutter quality checks completed!"

.PHONY: check-edge-functions
check-edge-functions:
	@echo "Running Edge Functions quality checks..."
	# Denoの設定確認とlinting
	if [ -d "supabase/functions" ]; then \
		cd supabase/functions && \
		for dir in */; do \
			if [ -f "$$dir/index.ts" ]; then \
				echo "Checking $$dir..."; \
				cd "$$dir" && \
				deno lint . && \
				deno fmt --check . && \
				cd ..; \
			fi; \
		done; \
	fi
	@echo "Edge Functions quality checks completed!"

.PHONY: check-backend
check-backend:
	@echo "Running Backend quality checks..."
	# Python backend checks with uv
	@if [ -d "backend-py/app" ]; then \
		cd backend-py/app && \
		if [ -f "pyproject.toml" ]; then \
			if command -v uv >/dev/null 2>&1; then \
				echo "Running ruff check with uv..."; \
				uv run ruff check . && \
				echo "Running ruff format check with uv..."; \
				uv run ruff format --check .; \
			else \
				echo "uv not installed, skipping Python checks"; \
			fi; \
		else \
			echo "pyproject.toml not found, skipping Python checks"; \
		fi; \
	else \
		echo "backend-py/app directory not found, skipping Python checks"; \
	fi
	@echo "Backend quality checks completed!"

.PHONY: fix-format-flutter
fix-format-flutter:
	@echo "Auto-fixing Flutter code formatting (excluding generated files)..."
	cd frontend && find . -name "*.dart" \
		! -name "*.g.dart" \
		! -name "*.freezed.dart" \
		! -name "*.gr.dart" \
		! -path "*/generated/*" \
		! -path "*/.dart_tool/*" \
		! -path "*/build/*" \
		-exec dart format {} +
	@echo "Flutter code formatting completed!"

.PHONY: fix-format-edge-functions
fix-format-edge-functions:
	@echo "Auto-fixing Edge Functions code formatting..."
	if [ -d "supabase/functions" ]; then \
		cd supabase/functions && \
		for dir in */; do \
			if [ -f "$$dir/index.ts" ]; then \
				echo "Formatting $$dir..."; \
				cd "$$dir" && deno fmt . && cd ..; \
			fi; \
		done; \
	fi
	@echo "Edge Functions code formatting completed!"

.PHONY: fix-format-backend
fix-format-backend:
	@echo "Auto-fixing Backend code formatting..."
	@if [ -d "backend-py/app" ]; then \
		cd backend-py/app && \
		if [ -f "pyproject.toml" ]; then \
			if command -v uv >/dev/null 2>&1; then \
				echo "Running ruff check --fix with uv..."; \
				uv run ruff check . --fix && \
				echo "Running ruff format with uv..."; \
				uv run ruff format .; \
			else \
				echo "uv not installed, skipping Python formatting"; \
			fi; \
		fi; \
	fi
	@echo "Backend code formatting completed!"

.PHONY: hook-dart-check
hook-dart-check:
	@if [ -z "$(FILE_PATH)" ]; then \
		echo "Error: FILE_PATH is required"; \
		exit 1; \
	fi
	@dart format "$(FILE_PATH)" >/dev/null 2>&1 || exit 2
	@cd frontend && flutter analyze >/dev/null 2>&1 || exit 2

.PHONY: hook-python-check
hook-python-check:
	@if [ -z "$(FILE_PATH)" ]; then \
		echo "Error: FILE_PATH is required" >&2; \
		exit 1; \
	fi; \
	cd backend-py/app && uv run ruff format "$(FILE_PATH)" >/dev/null 2>&1 && \
	uv run ruff check "$(FILE_PATH)" >/dev/null 2>&1 && \
	uv run mypy "$(FILE_PATH)" >/dev/null 2>&1 || exit 2

.PHONY: test-all
test-all:
	@echo "Running all tests (unit, widget, and integration)..."
	# Flutter unit and widget tests
	@echo "📝 Running Flutter unit and widget tests..."
	cd frontend && melos run test
	# Flutter integration tests
	@echo "🔄 Running Flutter integration tests..."
	cd frontend && melos run integration_test
	# Edge Functions tests (if test files exist)
	if [ -d "supabase/functions" ]; then \
		cd supabase/functions && \
		for dir in */; do \
			if [ -f "$$dir/test.ts" ] || [ -d "$$dir/tests" ]; then \
				echo "Testing $$dir..."; \
				cd "$$dir" && \
				deno test --allow-all && \
				cd ..; \
			fi; \
		done; \
	fi
	# Backend tests (if test files exist)
	if [ -d "backend-py" ] && [ -f "backend-py/pyproject.toml" ]; then \
		cd backend-py && \
		if command -v pytest >/dev/null 2>&1; then \
			pytest; \
		else \
			echo "pytest not installed, skipping Python tests"; \
		fi; \
	fi
	@echo "✅ All tests completed!"

# ==============================================================================
# Patrol E2E Testing
# ==============================================================================

# Patrol CLI インストール
# patrol_cliをグローバルにインストールします
# Note: 'make init' で自動的にインストールされますが、手動で再インストールする場合に使用
.PHONY: patrol-install
patrol-install:
	@command -v patrol >/dev/null 2>&1 || { \
		echo "Installing patrol_cli..."; \
		flutter pub global activate patrol_cli; \
		echo "✅ patrol_cli installed. Ensure ~/.pub-cache/bin is in your PATH"; \
		echo "Run 'patrol doctor' to verify installation"; \
	}
	@echo "Verifying Patrol CLI installation..."
	@patrol doctor

# Patrol E2Eテスト実行（すべて）
# すべてのPatrolテストを実行します
.PHONY: patrol-test
patrol-test:
	@echo "Running all Patrol E2E tests..."
	cd frontend/apps/web && patrol test --exclude=skip

# Patrol E2Eテスト実行（Web）
# WebプラットフォームのPatrolテストのみを実行します
.PHONY: patrol-test-web
patrol-test-web:
	@echo "Running Patrol E2E tests for Web..."
	cd frontend/apps/web && patrol test --tags=web --exclude=skip

# Patrol E2Eテスト実行（Mobile）
# Mobileプラットフォーム（iOS/Android）のPatrolテストを実行します
.PHONY: patrol-test-mobile
patrol-test-mobile:
	@echo "Running Patrol E2E tests for Mobile..."
	cd frontend/apps/web && patrol test --tags=mobile --exclude=skip

# Patrol E2Eテスト実行（スモークテストのみ）
# 基本的な動作確認用のスモークテストのみを実行します
.PHONY: patrol-test-smoke
patrol-test-smoke:
	@echo "Running Patrol smoke tests..."
	cd frontend/apps/web && patrol test --tags=smoke --exclude=skip

# ==============================================================================
# Widgetbook UI Component Catalog
# ==============================================================================

# Widgetbook 起動（bootstrap + コード生成 + 起動を一括実行）
# UIコンポーネントカタログをブラウザで開きます (http://localhost:9000)
.PHONY: frontend-widgetbook
frontend-widgetbook: frontend-bootstrap
	@echo "🎨 Starting Widgetbook..."
	@echo "Generating Widgetbook directories..."
	cd frontend/widgetbook && dart run build_runner build --delete-conflicting-outputs
	@echo "Opening Widgetbook at http://localhost:9000"
	cd frontend/widgetbook && flutter run -d chrome --web-port 9000

# Widgetbook コード生成のみ（CI用など）
.PHONY: frontend-widgetbook-generate
frontend-widgetbook-generate:
	@echo "Generating Widgetbook directories..."
	cd frontend/widgetbook && dart run build_runner build --delete-conflicting-outputs

# Widgetbook Web用ビルド
.PHONY: frontend-widgetbook-build
frontend-widgetbook-build: frontend-widgetbook-generate
	@echo "Building Widgetbook for web..."
	cd frontend/widgetbook && flutter build web
