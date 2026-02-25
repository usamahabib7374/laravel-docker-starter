# Laravel Docker Starter

A ready-to-use Docker development environment for Laravel applications. Clone it, run two commands, and have a fully working Laravel stack running locally — no PHP, Composer, or any other tool required on your host machine beyond Docker.

## Stack

| Service | Technology |
|---------|------------|
| Web server | Nginx (alpine) |
| Application | PHP 8.4-FPM |
| Database | MySQL 8.0 |
| Cache / Sessions / Queues | Redis 7 |

## Project Structure

```
.
├── docker-compose.yml          # Service definitions
├── Makefile                    # Developer commands
├── .env.example                # Docker-level environment variables
├── docker/
│   ├── nginx/default.conf      # Nginx virtual host config
│   └── php/Dockerfile          # PHP 8.4-FPM image with Laravel extensions
└── src/                        # Laravel application lives here
```

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (with Docker Compose v2)
- `make` (pre-installed on macOS and most Linux distros)

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/usamahabib7374/laravel-docker-starter.git
cd laravel-docker-starter
```

### 2. Create your environment file

```bash
cp .env.example .env
```

You can leave the defaults as-is for local development. Open `.env` if you want to change ports or database credentials.

### 3. Build the Docker image

This is a one-time step. It compiles the PHP 8.4-FPM image with all required Laravel extensions.

```bash
make build
```

### 4. Start all containers

```bash
make up
```

This starts Nginx, PHP-FPM, MySQL and Redis in the background. Storage permissions are fixed automatically on startup.

### 5. Install Composer dependencies

```bash
make composer-install
```

### 6. Run database migrations

The command automatically waits for MySQL to be fully ready before running.

```bash
make migrate
```

### 7. Open the app

Visit [http://localhost:8080](http://localhost:8080)

---

## Daily Usage

```bash
make up          # Start containers
make down        # Stop and remove containers
make restart     # Restart all containers
make logs        # Tail logs from all services
make logs-app    # Tail logs from the PHP container only
```

---

## All Available Commands

Run `make` or `make help` to see every available command:

```
up                   Start all containers in detached mode
down                 Stop and remove all containers
build                Build Docker images
rebuild              Rebuild images and restart containers
restart              Restart all containers
logs                 Tail logs for all services
logs-app             Tail logs for the PHP container only
shell                Open a bash shell inside the app container
permissions          Fix storage and bootstrap/cache permissions
install              Install a fresh Laravel application into src/
configure            Update src/.env with Docker service hostnames and credentials
key-generate         Generate the Laravel application key
setup                Full first-time setup: build → start → install → configure → key → migrate
composer-install     Install Composer dependencies
artisan              Run an artisan command. Usage: make artisan CMD="route:list"
wait-db              Wait until MySQL container is healthy
migrate              Run database migrations
migrate-fresh        Drop all tables and re-run migrations
seed                 Run database seeders
cache-clear          Clear all Laravel caches (cache, config, routes, views)
db-import            Import a SQL dump. Usage: make db-import FILE=path/to/dump.sql
env                  Create .env from .env.example if it does not exist
```

---

## Useful Examples

```bash
# Open a shell inside the PHP container
make shell

# Run any artisan command
make artisan CMD="route:list"
make artisan CMD="make:model Post -mcr"
make artisan CMD="tinker"

# Clear all Laravel caches
make cache-clear

# Import an existing database dump
make db-import FILE=path/to/dump.sql

# Drop all tables and re-run migrations from scratch
make migrate-fresh

# Run database seeders
make seed
```

---

## Environment Variables

The root `.env` file controls Docker-level settings (ports, database credentials). These are separate from the Laravel `src/.env`.

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_PORT` | `8080` | Host port mapped to Nginx |
| `DB_PORT` | `3306` | Host port mapped to MySQL |
| `DB_DATABASE` | `laravel` | Database name |
| `DB_ROOT_PASSWORD` | `root_password` | MySQL root password |
| `DB_USERNAME` | `laravel` | MySQL application user |
| `DB_PASSWORD` | `laravel_password` | MySQL application password |
| `REDIS_PORT` | `6379` | Host port mapped to Redis |

---

## Using This With an Existing Laravel Project

To swap in your own Laravel codebase instead of the included starter:

1. Delete the contents of `src/`
2. Copy or clone your Laravel project into `src/`
3. Run `make configure` to automatically update `src/.env` with the correct Docker hostnames
4. Run `make composer-install` then `make migrate`
