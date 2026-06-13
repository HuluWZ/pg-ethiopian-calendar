#!/bin/bash
set -e

cd /usr/src/extension

if [ -f Makefile ]; then
    echo "Building extension..."
    make clean 2>/dev/null || true
    make USE_PGXS=1 with_llvm=no
    make USE_PGXS=1 with_llvm=no install
    echo "Extension built and installed successfully!"
else
    echo "Warning: Makefile not found. Source code should be mounted at /usr/src/extension"
fi

exec docker-entrypoint.sh postgres "$@"
