# Dockerfile for testing pg_ethiopian_calendar extension
# Supports PostgreSQL 11+
# Base image: PostgreSQL (version specified via ARG)
ARG PG_VERSION=14
FROM postgres:${PG_VERSION}

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
        cpanminus \
        make \
        gcc \
        libc6-dev \
        git \
        wget \
        ca-certificates \
        perl \
        libperl-dev \
        postgresql-plperl-${PG_MAJOR} \
        && \
    # Install pgTAP from source
    cd /tmp && \
    git clone --depth 1 https://github.com/theory/pgtap.git && \
    cd pgtap && \
    make && \
    make install && \
    # Install Perl dependencies for pg_prove
    cpanm --notest TAP::Parser::SourceHandler::pgTAP TAP::Harness && \
    # Clean up
    cd / && \
    rm -rf /tmp/pgtap /tmp/pg_major_version && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /usr/src/extension

# Copy extension source files
COPY Makefile ./
COPY pg_ethiopian_calendar.control ./
COPY sql/ ./sql/
COPY src/ ./src/

# Build the extension (but don't install yet - will install in test script)
RUN make clean || true && \
    make

# Copy test files
COPY test/ ./test/

# Set up test script as executable
RUN chmod +x /usr/src/extension/test/pgtest.sh

# Set environment variables
ENV PGDATA=/var/lib/postgresql/data
# PostgreSQL environment variables must be provided via docker-compose or .env file
# Required: POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB

# Default command: start postgres and run tests
CMD ["bash", "-c", "docker-entrypoint.sh postgres & sleep 5 && /usr/src/extension/test/pgtest.sh"]
