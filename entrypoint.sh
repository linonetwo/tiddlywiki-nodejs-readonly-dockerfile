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
TW_PLUGIN_PATH="${TIDDLYWIKI_PLUGIN_PATH:-/usr/local/lib/node_modules/tiddlywiki/plugins}"

export TIDDLYWIKI_PLUGIN_PATH="$TW_PLUGIN_PATH"

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
echo "Plugin path: $TW_PLUGIN_PATH"

if [ "$READ_ONLY_MODE" = "true" ]; then
    USERNAME="${USERNAME:-admin}"
    PASSWORD="${PASSWORD:-changeme}"
    READERS="(anon)"
    WRITERS="$USERNAME"
    echo "Admin username: $USERNAME"
    echo "Admin password: $PASSWORD"

    set -- tiddlywiki \
        +plugins/tiddlywiki/tiddlyweb \
        "$WIKI_PATH" \
        --listen \
        "port=$PORT" \
        "host=$HOST" \
        "root-tiddler=$ROOT_TIDDLER" \
        "gzip=yes" \
        "readers=$READERS" \
        "writers=$WRITERS" \
        "username=$USERNAME" \
        "password=$PASSWORD"

    if [ "${TOKEN_AUTH}" = "true" ] && [ -n "${AUTH_TOKEN}" ]; then
        AUTH_HEADER="${AUTH_HEADER:-X-TidGI-Auth}"
        set -- "$@" "authenticated-user-header=$AUTH_HEADER" "readers=$USERNAME" "writers=$USERNAME"
    fi
else
    set -- tiddlywiki \
        +plugins/tiddlywiki/tiddlyweb \
        "$WIKI_PATH" \
        --listen \
        "port=$PORT" \
        "host=$HOST" \
        "root-tiddler=$ROOT_TIDDLER" \
        "credentials=false"
fi

echo ""
echo "Starting TiddlyWiki with plugin: tiddlyweb"
echo "  $*"
echo ""

exec "$@"

