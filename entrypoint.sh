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
GZIP="${GZIP:-yes}"
USE_BROWSER_CACHE="${USE_BROWSER_CACHE:-yes}"
NODE_ENV="${NODE_ENV:-production}"
TW_PLUGIN_PATH="${TIDDLYWIKI_PLUGIN_PATH:-/usr/local/lib/node_modules/tiddlywiki/plugins}"
EXCLUDE_EDITING_PLUGINS="${EXCLUDE_EDITING_PLUGINS:-true}"
DEFAULT_EXCLUDED_PLUGINS_FILTER='[prefix[$:/plugins/tiddlywiki/codemirror]] [[$:/plugins/oeyoews/tiddlywiki-codemirror-6]] [[$:/plugins/Gk0Wk/TW5-CodeMirror-Enhanced]] [[$:/plugins/tiddlywiki/prosemirror]] [[$:/plugins/linonetwo/tw-whiteboard]] [[$:/plugins/linonetwo/calendar]] [[$:/plugins/linonetwo/tw-calendar]]'
EXCLUDED_PLUGINS_FILTER="${EXCLUDED_PLUGINS_FILTER:-$DEFAULT_EXCLUDED_PLUGINS_FILTER}"
NODE_LAUNCHER_PATH="${NODE_LAUNCHER_PATH:-/start-nodejs-wiki.js}"

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
echo "Use browser cache: $USE_BROWSER_CACHE"
echo "Plugin path: $TW_PLUGIN_PATH"
echo "Exclude editing plugins: $EXCLUDE_EDITING_PLUGINS"

if [ "$READ_ONLY_MODE" = "true" ]; then
    WRITER_ACCOUNT_GENERATED="false"
    if [ -z "${USERNAME:-}" ]; then
        USERNAME="readonly-$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24)"
        WRITER_ACCOUNT_GENERATED="true"
    fi
    if [ -z "${PASSWORD:-}" ]; then
        PASSWORD="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 64)"
    fi
    READERS="(anon)"
    WRITERS="$USERNAME"
    if [ "$WRITER_ACCOUNT_GENERATED" = "true" ]; then
        echo "Writer account: generated for read-only protection"
    else
        echo "Writer account: configured"
    fi

    set -- node \
        "$NODE_LAUNCHER_PATH" \
        "$WIKI_PATH" \
        --listen \
        "port=$PORT" \
        "host=$HOST" \
        "root-tiddler=$ROOT_TIDDLER" \
        "gzip=$GZIP" \
        "use-browser-cache=$USE_BROWSER_CACHE" \
        "readers=$READERS" \
        "writers=$WRITERS" \
        "username=$USERNAME" \
        "password=$PASSWORD"

    if [ "${TOKEN_AUTH}" = "true" ] && [ -n "${AUTH_TOKEN}" ]; then
        AUTH_HEADER="${AUTH_HEADER:-X-TidGI-Auth}"
        set -- "$@" "authenticated-user-header=$AUTH_HEADER" "readers=$USERNAME" "writers=$USERNAME"
    fi

    if [ "$EXCLUDE_EDITING_PLUGINS" = "true" ] && [ -n "$EXCLUDED_PLUGINS_FILTER" ]; then
        export EXCLUDED_PLUGINS_FILTER
        set -- "$@" \
            --setfield \
            "$EXCLUDED_PLUGINS_FILTER" \
            "text" \
            "" \
            "text/plain"
        echo "Editing plugin payloads: excluded with TidGi --setfield arguments"
    else
        EXCLUDED_PLUGINS_FILTER=""
        export EXCLUDED_PLUGINS_FILTER
    fi
else
    EXCLUDED_PLUGINS_FILTER=""
    export EXCLUDED_PLUGINS_FILTER
    set -- node \
        "$NODE_LAUNCHER_PATH" \
        "$WIKI_PATH" \
        --listen \
        "port=$PORT" \
        "host=$HOST" \
        "root-tiddler=$ROOT_TIDDLER" \
        "use-browser-cache=$USE_BROWSER_CACHE" \
        "credentials=false"
fi

echo ""
echo "Starting TiddlyWiki with plugin: tiddlyweb"
echo ""

exec "$@"
