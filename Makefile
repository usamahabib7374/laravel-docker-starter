# ============================================================
# Load variables from .env
# ============================================================
ifneq (,$(wildcard .env))
    include .env
    export
endif

DB_DATABASE  ?= laravel
DB_USERNAME  ?= laravel
DB_PASSWORD  ?= laravel_password

.DEFAULT_GOAL := help

.PHONY: help up down build rebuild restart logs logs-app shell \
        install configure key-generate setup \
        composer-install artisan migrate migrate-fresh seed \
        cache-clear db-import env

# ============================================================
# Help
# ============================================================
help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ============================================================
# Docker
# ============================================================
up: ## Start all containers in detached mode
	docker compose up -d

down: ## Stop and remove all containers
	docker compose down

build: ## Build Docker images
	docker compose build

rebuild: ## Rebuild images and restart containers
	docker compose up -d --build

restart: ## Restart all containers
	docker compose restart

logs: ## Tail logs for all services
	docker compose logs -f

logs-app: ## Tail logs for the PHP container only
	docker compose logs -f app

# ============================================================
# Application setup
# ============================================================
shell: ## Open a bash shell inside the app container
	docker compose exec app bash

permissions: ## Fix storage and bootstrap/cache permissions
	docker compose exec app chmod -R 775 storage bootstrap/cache
	docker compose exec app chown -R www-data:www-data storage bootstrap/cache

install: ## Install a fresh Laravel application into src/
	@if [ -f src/artisan ]; then \
		echo "Laravel is already installed in src/. Skipping."; \
	else \
		rm -f src/.gitkeep; \
		docker compose run --rm --no-deps app \
			composer create-project laravel/laravel . --prefer-dist; \
	fi

configure: ## Update src/.env with Docker service hostnames and credentials
	@if [ ! -f src/.env ]; then cp src/.env.example src/.env; fi
	@sed -i 's/^DB_CONNECTION=.*/DB_CONNECTION=mysql/' src/.env
	@sed -i 's/^#\s*DB_HOST=.*/DB_HOST=mysql/' src/.env
	@sed -i 's/^DB_HOST=127\.0\.0\.1/DB_HOST=mysql/' src/.env
	@sed -i 's/^#\s*DB_PORT=.*/DB_PORT=3306/' src/.env
	@sed -i 's/^#\s*DB_DATABASE=.*/DB_DATABASE=$(DB_DATABASE)/' src/.env
	@sed -i 's/^DB_DATABASE=.*/DB_DATABASE=$(DB_DATABASE)/' src/.env
	@sed -i 's/^#\s*DB_USERNAME=.*/DB_USERNAME=$(DB_USERNAME)/' src/.env
	@sed -i 's/^DB_USERNAME=.*/DB_USERNAME=$(DB_USERNAME)/' src/.env
	@sed -i 's/^#\s*DB_PASSWORD=.*/DB_PASSWORD=$(DB_PASSWORD)/' src/.env
	@sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD=$(DB_PASSWORD)/' src/.env
	@sed -i 's/^REDIS_HOST=127\.0\.0\.1/REDIS_HOST=redis/' src/.env
	@sed -i 's/^SESSION_DRIVER=.*/SESSION_DRIVER=redis/' src/.env
	@sed -i 's/^CACHE_STORE=.*/CACHE_STORE=redis/' src/.env
	@sed -i 's/^QUEUE_CONNECTION=.*/QUEUE_CONNECTION=redis/' src/.env
	@echo "src/.env configured for Docker networking."

key-generate: ## Generate the Laravel application key
	docker compose exec app php artisan key:generate

setup: ## Full first-time setup: build → start → install → configure → key → migrate
	$(MAKE) build
	$(MAKE) up
	$(MAKE) install
	$(MAKE) configure
	$(MAKE) key-generate
	$(MAKE) migrate

# ============================================================
# Composer & Artisan
# ============================================================
composer-install: ## Install Composer dependencies
	docker compose exec app composer install

artisan: ## Run an artisan command. Usage: make artisan CMD="route:list"
	docker compose exec app php artisan $(CMD)

wait-db: ## Wait until MySQL container is healthy
	@echo "Waiting for MySQL to be ready..."
	@until [ "$$(docker inspect --format='{{.State.Health.Status}}' autoscout_mysql 2>/dev/null)" = "healthy" ]; do \
		sleep 2; \
	done
	@echo "MySQL is ready."

migrate: wait-db ## Run database migrations
	docker compose exec app php artisan migrate

migrate-fresh: ## Drop all tables and re-run migrations
	docker compose exec app php artisan migrate:fresh

seed: ## Run database seeders
	docker compose exec app php artisan db:seed

# ============================================================
# Cache
# ============================================================
cache-clear: ## Clear all Laravel caches (cache, config, routes, views)
	docker compose exec app php artisan cache:clear
	docker compose exec app php artisan config:clear
	docker compose exec app php artisan route:clear
	docker compose exec app php artisan view:clear

# ============================================================
# Database
# ============================================================
db-import: ## Import a SQL dump. Usage: make db-import FILE=path/to/dump.sql
	@[ -n "$(FILE)" ] || (echo "Usage: make db-import FILE=path/to/dump.sql" && exit 1)
	docker compose exec -T -e MYSQL_PWD=$(DB_PASSWORD) mysql \
		mysql -u$(DB_USERNAME) $(DB_DATABASE) < $(FILE)

# ============================================================
# Environment
# ============================================================
env: ## Create .env from .env.example if it does not exist
	@if [ ! -f .env ]; then cp .env.example .env && echo ".env created from .env.example."; else echo ".env already exists."; fi
