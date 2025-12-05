# PostgreSQL extension Makefile
# Uses PGXS (PostgreSQL Extension System)
# Follows PostgreSQL extension standards: https://www.postgresql.org/docs/current/extend-pgxs.html

# Extension name (lowercase with underscores, using pg_ prefix)
# MODULES must match the source file name (without .c extension)
EXTENSION = pg_ethiopian_calendar
MODULES = ethiopian_calendar

# SQL files (versioned migration files following PostgreSQL standards)
# Format: extension--version.sql (initial version)
# Format: extension--from_version--to_version.sql (migrations)
# Note: Migration files are only included when they're part of the default version path
DATA = sql/pg_ethiopian_calendar--1.0.sql

# Source files are in src/ directory
VPATH = src

# Control file is in root directory (not in src/)
# PGXS expects control file in current directory when VPATH is set
override srcdir = .

# PostgreSQL build configuration using PGXS
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

# Docker-based development commands
.PHONY: docker-start docker-dev docker-stop docker-restart docker-rebuild docker-test docker-shell docker-logs docker-clean docker-status docker-init

# Initialize .env file if it doesn't exist
docker-init:
	@if [ ! -f .env ]; then \
		if [ -f .env.example ]; then \
			cp .env.example .env; \
			echo "✓ Created .env from .env.example"; \
		else \
			echo "⚠ .env.example not found"; \
		fi \
	fi

# Start PostgreSQL (production mode)
docker-start: docker-init
	@echo "🚀 Starting PostgreSQL with Ethiopian Calendar extension..."
	@docker compose --profile default up -d postgres || (echo "❌ Failed to start container" && docker compose logs postgres --tail 20 && exit 1)
	@echo "⏳ Waiting for PostgreSQL to be ready..."
	@sleep 3
	@for i in $$(seq 1 60); do \
		if docker compose exec -T postgres pg_isready -U $${POSTGRES_USER:-postgres} > /dev/null 2>&1; then \
			break; \
		fi; \
		if [ $$i -eq 60 ]; then \
			echo ""; \
			echo "❌ PostgreSQL failed to start within 60 seconds"; \
			echo "📋 Container status:"; \
			docker compose ps postgres; \
			echo ""; \
			echo "📋 Recent logs:"; \
			docker compose logs postgres --tail 30; \
			echo ""; \
			echo "💡 Try: make docker-clean && make docker-start"; \
			exit 1; \
		fi; \
		echo -n "."; \
		sleep 1; \
	done
	@echo ""
	@echo "✅ PostgreSQL is ready!"
	@echo ""
	@echo "Connection: postgresql://$${POSTGRES_USER:-postgres}:$${POSTGRES_PASSWORD:-postgres}@localhost:$${POSTGRES_PORT:-5432}/$${POSTGRES_DB:-postgres}"
	@echo "Test: docker compose exec postgres psql -U $${POSTGRES_USER:-postgres} -c \"SELECT to_ethiopian_date('2024-01-01'::timestamp);\""

# Start PostgreSQL (development mode)
docker-dev: docker-init
	@echo "🔧 Starting PostgreSQL in DEVELOPMENT mode..."
	@docker compose --profile dev up -d postgres-dev
	@echo "⏳ Waiting for PostgreSQL to be ready..."
	@timeout 30 bash -c 'until docker compose exec -T postgres-dev pg_isready -U $${POSTGRES_USER:-postgres} > /dev/null 2>&1; do sleep 1; done' || (echo "❌ PostgreSQL failed to start" && exit 1)
	@echo "✅ PostgreSQL (dev) is ready!"
	@echo ""
	@echo "Source code is mounted - restart container to rebuild after changes"
	@echo "Connection: postgresql://$${POSTGRES_USER:-postgres}:$${POSTGRES_PASSWORD:-postgres}@localhost:$${POSTGRES_PORT:-5432}/$${POSTGRES_DB:-postgres}"

# Stop PostgreSQL
docker-stop:
	@echo "🛑 Stopping PostgreSQL containers..."
	@docker compose stop postgres postgres-dev 2>/dev/null || true
	@echo "✅ Stopped"

# Restart PostgreSQL
docker-restart:
	@echo "🔄 Restarting PostgreSQL..."
	@docker compose restart postgres postgres-dev 2>/dev/null || true
	@echo "✅ Restarted"

# Rebuild and restart
docker-rebuild:
	@echo "🔨 Rebuilding PostgreSQL containers..."
	@docker compose --profile default build --no-cache postgres
	@docker compose --profile dev build --no-cache postgres-dev 2>/dev/null || true
	@echo "🚀 Starting containers..."
	@$(MAKE) docker-start

# Run tests
docker-test:
	@echo "🧪 Running tests..."
	@docker compose --profile test up --build --abort-on-container-exit test
	@TEST_EXIT=$$?; \
	docker compose --profile test down -v 2>/dev/null || true; \
	exit $$TEST_EXIT

# Connect to PostgreSQL with psql
docker-psql:
	@if docker compose ps postgres-dev 2>/dev/null | grep -q "Up"; then \
		docker compose exec postgres-dev psql -U $${POSTGRES_USER:-postgres}; \
	elif docker compose ps postgres 2>/dev/null | grep -q "Up"; then \
		docker compose exec postgres psql -U $${POSTGRES_USER:-postgres}; \
	else \
		echo "❌ No PostgreSQL container is running. Start with 'make docker-start' or 'make docker-dev'"; \
		exit 1; \
	fi

# Open psql shell (alias for docker-psql)
docker-shell:
	@if docker compose ps postgres-dev 2>/dev/null | grep -q "Up"; then \
		docker compose exec postgres-dev psql -U $${POSTGRES_USER:-postgres}; \
	elif docker compose ps postgres 2>/dev/null | grep -q "Up"; then \
		docker compose exec postgres psql -U $${POSTGRES_USER:-postgres}; \
	else \
		echo "❌ No PostgreSQL container is running. Start with 'make docker-start' or 'make docker-dev'"; \
		exit 1; \
	fi

# Show logs
docker-logs:
	@if docker compose ps postgres-dev 2>/dev/null | grep -q "Up"; then \
		docker compose logs -f postgres-dev; \
	elif docker compose ps postgres 2>/dev/null | grep -q "Up"; then \
		docker compose logs -f postgres; \
	else \
		echo "❌ No PostgreSQL container is running"; \
		exit 1; \
	fi

# Show status
docker-status:
	@echo "📊 Container Status:"
	@docker compose ps
	@echo ""
	@echo "📦 Extension Status:"
	@if docker compose ps postgres 2>/dev/null | grep -q "Up"; then \
		docker compose exec -T postgres psql -U $${POSTGRES_USER:-postgres} -c "SELECT extname, extversion FROM pg_extension WHERE extname = 'pg_ethiopian_calendar';" 2>/dev/null || echo "⚠ Could not query extension status"; \
	elif docker compose ps postgres-dev 2>/dev/null | grep -q "Up"; then \
		docker compose exec -T postgres-dev psql -U $${POSTGRES_USER:-postgres} -c "SELECT extname, extversion FROM pg_extension WHERE extname = 'ethiopian_calendar';" 2>/dev/null || echo "⚠ Could not query extension status"; \
	else \
		echo "⚠ PostgreSQL container is not running"; \
	fi

# Clean up (stop and remove volumes)
docker-clean:
	@echo "🧹 This will stop containers and remove all volumes (data will be lost)"
	@read -p "Are you sure? (y/N) " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		echo "✅ Cleanup complete"; \
	else \
		echo "❌ Cleanup cancelled"; \
	fi

# Help
docker-help:
	@echo "Docker-based commands for Ethiopian Calendar Extension"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  docker-init      Initialize .env file from .env.example"
	@echo "  docker-start     Start PostgreSQL (production mode)"
	@echo "  docker-dev       Start PostgreSQL (development mode)"
	@echo "  docker-stop      Stop PostgreSQL containers"
	@echo "  docker-restart   Restart PostgreSQL containers"
	@echo "  docker-rebuild   Rebuild and restart containers"
	@echo "  docker-test      Run tests"
	@echo "  docker-shell     Open psql shell"
	@echo "  docker-logs      Show PostgreSQL logs"
	@echo "  docker-status    Show container and extension status"
	@echo "  docker-clean     Stop containers and remove volumes"
	@echo "  docker-help      Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make docker-start    # Start production PostgreSQL"
	@echo "  make docker-dev      # Start development PostgreSQL"
	@echo "  make docker-test     # Run all tests"
	@echo "  make docker-shell    # Open psql shell"
