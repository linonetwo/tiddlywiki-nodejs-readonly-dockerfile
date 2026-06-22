#!/bin/sh
set -e

# ==========================================
# TiddlyWiki Node.js Read-only Server
# ==========================================
# Based on TidGi Desktop's startNodeJSWiki.ts
# 
# Environment variables:
#   WIKI_PATH       - Path to wiki folder (default: /wiki)
#   PORT            - Server port (default: 8080)
#   HOST            - Server host (default: 0.0.0.0)
#   ROOT_TIDDLER    - Root tiddler for lazy loading (default: $:/core/save/lazy-all)
#   READ_ONLY_MODE  - Enable read-only mode (default: true)
#   USERNAME        - Username for admin access (default: auto-generated)
#   PASSWORD        - Password for admin access (default: auto-generated)
#   TOKEN_AUTH      - Use token authentication (default: false)
#   AUTH_TOKEN      - The auth token value
#   EXTRA_PLUGINS   - Extra plugins to load (comma-separated)
#   NODE_ENV        - Node environment
# ==========================================

# Configurable defaults
WIKI_PATH="${WIKI_PATH:-/wiki}"
PORT="${PORT:-8080}"
HOST="${HOST:-0.0.0.0}"
ROOT_TIDDLER="${ROOT_TIDDLER:-\$:/core/save/lazy-all}"
READ_ONLY_MODE="${READ_ONLY_MODE:-true}"
NODE_ENV="${NODE_ENV:-production}"

echo "=== TiddlyWiki Read-only Server ==="
echo "Wiki path: $WIKI_PATH"
echo "Port: $PORT"
echo "Host: $HOST"
echo "Read-only: $READ_ONLY_MODE"
echo "Root tiddler: $ROOT_TIDDLER"

# Validate wiki path
if [ ! -f "$WIKI_PATH/tiddlywiki.info" ] && [ ! -d "$WIKI_PATH/tiddlers" ]; then
    echo "ERROR: No tiddlywiki.info or tiddlers/ found in $WIKI_PATH"
    echo "Please mount your wiki data to $WIKI_PATH"
    exit 1
fi

# Build arguments
ARGS=("$WIKI_PATH" "--listen")

# Port and host
ARGS+=("port=${PORT}" "host=${HOST}")

# Root tiddler for lazy loading
ARGS+=("root-tiddler=${ROOT_TIDDLER}")

# Read-only mode: anonymous readers, authenticated writers
if [ "$READ_ONLY_MODE" = "true" ]; then
    # Generate random credentials if not provided
    USERNAME="${USERNAME:-$(cat /proc/sys/kernel/random/uuid | cut -d- -f1)}"
    PASSWORD="${PASSWORD:-$(cat /proc/sys/kernel/random/uuid)}"
    
    ARGS+=("gzip=yes")
    ARGS+=("readers=(anon)")
    ARGS+=("writers=${USERNAME}")
    ARGS+=("username=${USERNAME}")
    ARGS+=("password=${PASSWORD}")
    
    echo "Admin username: ${USERNAME}"
    echo "Admin password: ${PASSWORD}"
else
    # Writable mode: no auth
    ARGS+=("credentials=false")
fi

# Token authentication
if [ "${TOKEN_AUTH}" = "true" ] && [ -n "${AUTH_TOKEN}" ]; then
    ARGS+=("authenticated-user-header=X-TidGI-Auth")
    ARGS+=("readers=${USERNAME:-admin}")
    ARGS+=("writers=${USERNAME:-admin}")
fi

echo "Starting TiddlyWiki with arguments:"
echo "  tiddlywiki ${ARGS[*]}"
echo ""

# Start TiddlyWiki
exec tiddlywiki "${ARGS[@]}"
