#!/bin/bash
set -e

# Start PostgreSQL in the background.
# pgtest.sh already polls pg_isready in a loop, so no sleep is needed here.
docker-entrypoint.sh postgres &

exec /usr/src/extension/test/pgtest.sh
