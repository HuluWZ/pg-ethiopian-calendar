# Multi-stage Dockerfile for Ethiopian Calendar PostgreSQL Extension
# Supports PostgreSQL 11+
# Stage 1: Build the extension
ARG PG_VERSION=14
FROM postgres:${PG_VERSION} AS builder

# Get PostgreSQL major version
RUN PG_MAJOR=$(pg_config --version | sed -E 's/PostgreSQL ([0-9]+)\..*/\1/') && \
    echo "Building for PostgreSQL ${PG_MAJOR}" && \
    echo ${PG_MAJOR} > /tmp/pg_major_version

# Install build dependencies
RUN PG_MAJOR=$(cat /tmp/pg_major_version) && \
    apt-get update && \
    apt-get install -y \
    build-essential \
    postgresql-server-dev-${PG_MAJOR} \
    make \
    gcc \
    libc6-dev \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /usr/src/extension

# Copy extension source files (copy in order for better caching)
COPY Makefile ./
COPY pg_ethiopian_calendar.control ./
COPY sql/ ./sql/
COPY src/ ./src/

# Build the extension
RUN make clean || true && \
    make && \
    make install && \
    PG_MAJOR=$(cat /tmp/pg_major_version) && \
    echo "Extension installed to PostgreSQL ${PG_MAJOR}"

# Stage 2: Runtime image (minimal, no build tools)
FROM postgres:${PG_VERSION}

# Get PostgreSQL major version for copying files
RUN PG_MAJOR=$(pg_config --version | sed -E 's/PostgreSQL ([0-9]+)\..*/\1/') && \
    echo "Runtime PostgreSQL version: ${PG_MAJOR}" && \
    echo ${PG_MAJOR} > /tmp/pg_major_version

# Copy built extension from builder stage
# Use shell script to find and copy files
RUN --mount=from=builder,source=/usr/lib/postgresql,target=/mnt/lib,ro \
    --mount=from=builder,source=/usr/share/postgresql,target=/mnt/share,ro \
    PG_MAJOR=$(cat /tmp/pg_major_version) && \
    mkdir -p /usr/lib/postgresql/${PG_MAJOR}/lib && \
    mkdir -p /usr/share/postgresql/${PG_MAJOR}/extension && \
    find /mnt/lib -name "ethiopian_calendar.so*" -exec cp {} /usr/lib/postgresql/${PG_MAJOR}/lib/ \; && \
    find /mnt/share -name "pg_ethiopian_calendar*" -exec cp {} /usr/share/postgresql/${PG_MAJOR}/extension/ \; && \
    rm -f /tmp/pg_major_version

# Note: Extension must be created manually with: CREATE EXTENSION pg_ethiopian_calendar;

# PostgreSQL environment variables must be provided via docker-compose or .env file
# Required: POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB

# Expose PostgreSQL port
EXPOSE 5432

# Use default PostgreSQL entrypoint
# The extension will be available after database initialization
