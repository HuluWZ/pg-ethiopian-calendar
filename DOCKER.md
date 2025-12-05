# Docker-based Development Guide

This project uses **Docker Compose** and **Makefile** for all operations - no shell scripts required!

## Quick Start

```bash
# Initialize .env file (auto-creates from .env.example if needed)
make docker-init

# Start PostgreSQL (production mode)
make docker-start

# Or start in development mode
make docker-dev

# Connect to database and create extension
make docker-shell
# Then in psql: CREATE EXTENSION pg_ethiopian_calendar;

# Run tests
make docker-test
```

## Available Commands

All commands are available via `make`:

| Command | Description |
|---------|-------------|
| `make docker-init` | Initialize .env file from .env.example |
| `make docker-start` | Start PostgreSQL (production mode) |
| `make docker-dev` | Start PostgreSQL (development mode) |
| `make docker-stop` | Stop PostgreSQL containers |
| `make docker-restart` | Restart PostgreSQL containers |
| `make docker-rebuild` | Rebuild and restart containers |
| `make docker-test` | Run all tests |
| `make docker-shell` | Open psql shell |
| `make docker-logs` | Show PostgreSQL logs |
| `make docker-status` | Show container and extension status |
| `make docker-clean` | Stop containers and remove volumes |
| `make docker-help` | Show help message |

## Docker Compose Profiles

The project uses Docker Compose profiles to manage different environments:

- **`default`** / **`production`**: Pre-built extension (optimized, smaller image)
- **`dev`**: Development mode with source code mounted (rebuilds on restart)
- **`test`**: Test container with pgTAP

### Using Profiles Directly

```bash
# Production mode
docker compose --profile default up -d postgres

# Development mode
docker compose --profile dev up -d postgres-dev

# Run tests
docker compose --profile test up --build --abort-on-container-exit test
```

## Configuration

### Environment Variables (.env)

Create a `.env` file to customize settings:

```bash
cp .env.example .env
# Edit .env with your settings
```

The `.env` file supports:
- `POSTGRES_USER` - PostgreSQL username (default: postgres)
- `POSTGRES_PASSWORD` - PostgreSQL password (default: postgres)
- `POSTGRES_DB` - Database name (default: postgres)
- `POSTGRES_PORT` - Host port mapping (default: 5432)
- `TEST_POSTGRES_*` - Test database settings

### Docker Compose Override

For local customizations, you can create `docker-compose.override.yml`:

```yaml
services:
  postgres:
    ports:
      - "5433:5432"  # Use different port
```

This file is automatically loaded by docker compose and is git-ignored (see `.gitignore`).

## Development Workflow

### Production Mode (Recommended for Testing)

```bash
make docker-start
# Extension is pre-built in the image
```

### Development Mode (For Code Changes)

```bash
make docker-dev
# Source code is mounted, extension rebuilds on container start
# After code changes: make docker-restart
```

## Architecture

### Multi-Stage Build

The production `Dockerfile` uses multi-stage builds:
1. **Builder stage**: Compiles the extension with build tools
2. **Runtime stage**: Minimal image with only the compiled extension

This results in a smaller final image (~50% smaller) without build tools.

### Development Image

The `Dockerfile.dev` includes build tools and automatically rebuilds the extension when the container starts, using mounted source code.

## Troubleshooting

### Container won't start

```bash
# Check logs
make docker-logs

# Check status
make docker-status

# Rebuild from scratch
make docker-rebuild
```

### Extension not found

```bash
# Connect to database
make docker-shell

# In psql, create the extension:
CREATE EXTENSION pg_ethiopian_calendar;

# Verify it's installed:
SELECT * FROM pg_extension WHERE extname = 'pg_ethiopian_calendar';
```

### Port already in use

Edit `.env` and change `POSTGRES_PORT` to a different port, then restart.

## Clean Up

```bash
# Stop containers
make docker-stop

# Remove everything (including data)
make docker-clean
```

## Advantages of Docker-Based Approach

✅ **No shell scripts** - Everything uses standard Docker Compose and Makefile  
✅ **Portable** - Works the same on Linux, macOS, and Windows  
✅ **Isolated** - No need to install PostgreSQL dev packages on host  
✅ **Reproducible** - Same environment for everyone  
✅ **Multi-stage builds** - Optimized production images  
✅ **Profile-based** - Easy switching between dev/prod/test  
✅ **Environment-based config** - `.env` files for customization  

