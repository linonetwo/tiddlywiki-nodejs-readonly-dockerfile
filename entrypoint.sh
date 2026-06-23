#!/bin/sh
set -e

WIKI_ROOT="${WIKI_PATH:-/wiki}"
WIKI_SUBPATH="${WIKI_SUBPATH:-}"
if [ -n "$WIKI_SUBPATH" ]; then
    WIKI_PATH="$WIKI_ROOT/$WIKI_SUBPATH"
else
    WIKI_PATH="$WIKI_ROOT"
fi

PORT="${PORT:-8080}"
HOST="${HOST:-0.0.0.0}"
ROOT_TIDDLER="${ROOT_TIDDLER:-\$:/core/save/lazy-all}"
READ_ONLY_MODE="${READ_ONLY_MODE:-true}"
NODE_ENV="${NODE_ENV:-production}"

echo "=== TiddlyWiki Read-only Server ==="
echo "Wiki root: $WIKI_ROOT"
if [ -n "$WIKI_SUBPATH" ]; then
    echo "Wiki subpath: $WIKI_SUBPATH"
fi
echo "Wiki path: $WIKI_PATH"
echo "Port: $PORT"
echo "Host: $HOST"
echo "Read-only: $READ_ONLY_MODE"
echo "Root tiddler: $ROOT_TIDDLER"

ARGS="$WIKI_PATH --listen"
ARGS="$ARGS port=$PORT"
ARGS="$ARGS host=$HOST"
ARGS="$ARGS root-tiddler=$ROOT_TIDDLER"

if [ "$READ_ONLY_MODE" = "true" ]; then
    USERNAME="${USERNAME:-admin}"
    PASSWORD="${PASSWORD:-changeme}"
    ARGS="$ARGS gzip=yes"
    ARGS="$ARGS readers=(anon)"
    ARGS="$ARGS writers=$USERNAME"
    ARGS="$ARGS username=$USERNAME"
    ARGS="$ARGS password=$PASSWORD"
    echo "Admin username: $USERNAME"
    echo "Admin password: $PASSWORD"
else
    ARGS="$ARGS credentials=false"
fi

if [ "${TOKEN_AUTH}" = "true" ] && [ -n "${AUTH_TOKEN}" ]; then
    ARGS="$ARGS authenticated-user-header=X-TidGI-Auth"
    ARGS="$ARGS readers=${USERNAME:-admin}"
    ARGS="$ARGS writers=${USERNAME:-admin}"
fi

echo ""
echo "Starting TiddlyWiki with arguments:"
echo "  $ARGS"
echo ""

exec tiddlywiki $ARGS
