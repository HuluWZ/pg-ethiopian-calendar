# Multi-stage Dockerfile for Ethiopian Calendar PostgreSQL Extension
# Supports PostgreSQL 14+ (Alpine-based for minimal size)
#
# Build: docker build --build-arg PG_VERSION=16 -t pg-ethiopian-calendar .
# Run:   docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres pg-ethiopian-calendar

ARG PG_VERSION=16

#############################################
# Stage 1: Build the extension
#############################################
FROM postgres:${PG_VERSION}-alpine AS builder

# Install build dependencies (minimal for C extension)
RUN apk add --no-cache build-base

# Copy source files
COPY src/ /tmp/pg_ethiopian_calendar/src/
COPY sql/ /tmp/pg_ethiopian_calendar/sql/
COPY Makefile /tmp/pg_ethiopian_calendar/
COPY pg_ethiopian_calendar.control /tmp/pg_ethiopian_calendar/

WORKDIR /tmp/pg_ethiopian_calendar

# Build without LLVM/JIT support (not needed for this extension)
RUN make USE_PGXS=1 with_llvm=no && make USE_PGXS=1 with_llvm=no install

#############################################
# Stage 2: Create minimal runtime image
#############################################
FROM postgres:${PG_VERSION}-alpine

# Copy only the built extension files from builder stage
COPY --from=builder /usr/local/share/postgresql/extension/pg_ethiopian_calendar* /usr/local/share/postgresql/extension/
COPY --from=builder /usr/local/lib/postgresql/ethiopian_calendar.so /usr/local/lib/postgresql/

# Note: Extension must be created manually with: CREATE EXTENSION pg_ethiopian_calendar;
# Or use docker-entrypoint-initdb.d scripts

EXPOSE 5432
