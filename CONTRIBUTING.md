# Contributing to PostgreSQL Ethiopian Calendar Extension

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Code Style](#code-style)
- [Documentation](#documentation)

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Respect different viewpoints and experiences

## Getting Started

### Prerequisites

- Docker and Docker Compose (recommended)
- OR PostgreSQL 11+ with development headers
- Make
- C compiler (gcc)

### Quick Start

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/yourusername/postgres-ethiopian-calendar-extension.git
   cd postgres-ethiopian-calendar-extension
   ```

2. **Set up environment**
   ```bash
   # Copy environment template
   cp .env.example .env
   # Edit .env if needed (optional)
   ```

3. **Start development environment**
   ```bash
   # Start PostgreSQL with extension
   make docker-dev
   
   # Or for production mode
   make docker-start
   ```

4. **Test the extension**
   ```bash
   # Run all tests
   make docker-test
   
   # Or connect to database
   make docker-shell
   # Then in psql:
   CREATE EXTENSION pg_ethiopian_calendar;
   SELECT to_ethiopian_date(NOW());
   ```

## Development Setup

### Docker-based Development (Recommended)

The project uses Docker for a consistent development environment:

```bash
# Development mode (source code mounted, rebuilds on restart)
make docker-dev

# After making changes, restart to rebuild
make docker-restart

# View logs
make docker-logs
```

### Manual Setup

If you prefer to develop without Docker:

```bash
# Install PostgreSQL development headers
# Ubuntu/Debian:
sudo apt-get install postgresql-server-dev-14 make gcc

# Build the extension
make

# Install (requires superuser)
sudo make install

# Create extension in your database
psql -d your_database -c "CREATE EXTENSION pg_ethiopian_calendar;"
```

## Making Changes

### Project Structure

```
postgres-ethiopian-calendar-extension/
├── src/
│   └── ethiopian_calendar.c      # C implementation
├── sql/
│   └── pg_ethiopian_calendar--1.0.sql  # SQL function definitions
├── test/
│   └── tests/
│       └── ethiopian_calendar_tests.sql  # pgTAP tests
├── Makefile                      # Build configuration
├── pg_ethiopian_calendar.control # Extension metadata
└── README.md                     # Documentation
```

### Making Code Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

2. **Make your changes**
   - Follow the [Code Style](#code-style) guidelines
   - Update tests if needed
   - Update documentation

3. **Test your changes**
   ```bash
   # Run tests
   make docker-test
   
   # Test manually
   make docker-shell
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "Description of your changes"
   ```

## Testing

### Running Tests

```bash
# Run all tests with Docker
make docker-test

# Or manually with pgTAP
psql -d your_database -f test/tests/ethiopian_calendar_tests.sql
```

### Writing Tests

Tests use pgTAP and are located in `test/tests/ethiopian_calendar_tests.sql`.

Test structure:
```sql
BEGIN;
SELECT plan(1);

SELECT ok(
    to_ethiopian_date('2024-01-01'::timestamp) = '2016-04-23',
    'Should convert Gregorian to Ethiopian correctly'
);

SELECT finish();
ROLLBACK;
```

### Test Coverage

Ensure your changes include tests for:
- New functionality
- Edge cases
- Error conditions
- Boundary values (leap years, year boundaries)

## Submitting Changes

### Pull Request Process

1. **Update your fork**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Push your branch**
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create a Pull Request**
   - Provide a clear title and description
   - Reference any related issues
   - Include test results
   - Update documentation if needed

### Pull Request Checklist

- [ ] Code follows style guidelines
- [ ] Tests pass (`make docker-test`)
- [ ] Documentation updated (README, code comments)
- [ ] Commit messages are clear and descriptive
- [ ] No merge conflicts
- [ ] Changes are focused and atomic

## Code Style

### C Code

- Follow PostgreSQL coding conventions
- Use 4 spaces for indentation (no tabs)
- Maximum line length: 80 characters (soft limit)
- Function names: lowercase with underscores
- Comment complex algorithms
- Use `ereport()` for error handling

Example:
```c
Datum
to_ethiopian_date(PG_FUNCTION_ARGS)
{
    Timestamp   timestamp = PG_GETARG_TIMESTAMP(0);
    // ... implementation
}
```

### SQL Code

- Use consistent formatting
- Include comments for complex queries
- Follow PostgreSQL extension naming conventions
- Use `IF NOT EXISTS` where appropriate

### Commit Messages

Follow conventional commit format:

```
type(scope): subject

body (optional)

footer (optional)
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Test additions/changes
- `refactor`: Code refactoring
- `chore`: Maintenance tasks

Examples:
```
feat: add support for Ethiopian datetime conversion
fix: correct leap year calculation for year 2015
docs: update README with new usage examples
test: add tests for year boundary conditions
```

## Documentation

### Code Documentation

- Comment all public functions
- Explain complex algorithms
- Include parameter and return value descriptions
- Add examples for non-obvious usage

### User Documentation

- Update README.md for user-facing changes
- Add examples for new features
- Update function documentation in SQL files
- Keep QUICK_START.md current

### Internal Documentation

- Document design decisions in code comments
- Update architecture notes if structure changes
- Keep CONTRIBUTING.md current

## Questions?

- Open an issue for bugs or feature requests
- Ask questions in issue discussions
- Review existing issues and PRs for context

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

Thank you for contributing! 🎉

