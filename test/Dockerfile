# Dockerfile for testing pg_ethiopian_calendar extension
# Alpine-based to match production images (Dockerfile / Dockerfile.hub)
ARG PG_VERSION=16
FROM postgres:${PG_VERSION}-alpine

# Install build tools + Perl stack for pgTAP / pg_prove
RUN apk add --no-cache \
    build-base \
    bash \
    git \
    perl \
    perl-dev \
    wget \
    make \
    ca-certificates

# Install cpanminus, then the pg_prove Perl module
RUN wget -q -O /tmp/cpanminus https://cpanmin.us && \
    perl /tmp/cpanminus App::cpanminus && \
    cpanm --notest TAP::Parser::SourceHandler::pgTAP TAP::Harness && \
    rm /tmp/cpanminus

# Build pgTAP from source (not available in Alpine apk repos)
RUN cd /tmp && \
    git clone --depth 1 https://github.com/theory/pgtap.git && \
    cd pgtap && \
    make && \
    make install && \
    rm -rf /tmp/pgtap

WORKDIR /usr/src/extension

# Copy and build the extension
COPY Makefile ./
COPY pg_ethiopian_calendar.control ./
COPY sql/ ./sql/
COPY src/ ./src/

RUN make clean 2>/dev/null || true && make

# Copy test files and make the test runner executable
COPY test/ ./test/
RUN chmod +x ./test/run-tests.sh ./test/pgtest.sh

ENV PGDATA=/var/lib/postgresql/data

# run-tests.sh starts postgres in the background then calls pgtest.sh,
# which polls pg_isready — no blind sleep needed.
CMD ["/usr/src/extension/test/run-tests.sh"]
