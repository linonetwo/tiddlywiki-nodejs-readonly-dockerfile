#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

mkdir -p "$TEST_DIR/bin" "$TEST_DIR/wiki"
cat >"$TEST_DIR/bin/node" <<'EOF'
#!/bin/sh
shift
printf '%s\n' "$@" >"$CAPTURE_FILE"
EOF
chmod +x "$TEST_DIR/bin/node"

run_entrypoint() {
    capture_file="$1"
    shift
    env -i \
        PATH="$TEST_DIR/bin:/usr/bin:/bin" \
        CAPTURE_FILE="$capture_file" \
        WIKI_PATH="$TEST_DIR/wiki" \
        NODE_LAUNCHER_PATH="$ROOT_DIR/start-nodejs-wiki.js" \
        READ_ONLY_MODE=true \
        "$@" \
        sh "$ROOT_DIR/entrypoint.sh" >/dev/null
}

argument_value() {
    key="$1"
    capture_file="$2"
    sed -n "s/^${key}=//p" "$capture_file"
}

assert_random_credentials() {
    capture_file="$1"
    username="$(argument_value username "$capture_file")"
    password="$(argument_value password "$capture_file")"
    writers="$(argument_value writers "$capture_file")"
    readers="$(argument_value readers "$capture_file")"

    printf '%s' "$username" | grep -Eq '^readonly-[A-Za-z0-9]{24}$'
    printf '%s' "$password" | grep -Eq '^[A-Za-z0-9]{64}$'
    [ "$writers" = "$username" ]
    [ "$readers" = "(anon)" ]
}

run_entrypoint "$TEST_DIR/random-1.args"
run_entrypoint "$TEST_DIR/random-2.args"
assert_random_credentials "$TEST_DIR/random-1.args"
assert_random_credentials "$TEST_DIR/random-2.args"
grep -Fx -- '--setfield' "$TEST_DIR/random-1.args" >/dev/null
grep -F -- '[prefix[$:/plugins/tiddlywiki/codemirror]]' "$TEST_DIR/random-1.args" >/dev/null
grep -F -- '[[$:/plugins/linonetwo/calendar]]' "$TEST_DIR/random-1.args" >/dev/null
grep -F -- '[[$:/plugins/linonetwo/tw-calendar]]' "$TEST_DIR/random-1.args" >/dev/null
grep -F -- '[[$:/plugins/linonetwo/flow-chart]]' "$TEST_DIR/random-1.args" >/dev/null
grep -F -- '[[$:/plugins/linonetwo/hyper-table]]' "$TEST_DIR/random-1.args" >/dev/null
grep -F -- '[[$:/plugins/linonetwo/markdown-transformer]]' "$TEST_DIR/random-1.args" >/dev/null
grep -F -- '[[$:/plugins/oeyoews/mermaid]]' "$TEST_DIR/random-1.args" >/dev/null
grep -F -- '[[$:/plugins/linonetwo/super-tag]]' "$TEST_DIR/random-1.args" >/dev/null
grep -F -- '[[$:/plugins/linonetwo/tw-react]]' "$TEST_DIR/random-1.args" >/dev/null
listen_line="$(grep -n -Fx -- '--listen' "$TEST_DIR/random-1.args" | cut -d: -f1)"
setfield_line="$(grep -n -Fx -- '--setfield' "$TEST_DIR/random-1.args" | cut -d: -f1)"
[ "$listen_line" -lt "$setfield_line" ]

first_username="$(argument_value username "$TEST_DIR/random-1.args")"
second_username="$(argument_value username "$TEST_DIR/random-2.args")"
[ "$first_username" != "$second_username" ]

run_entrypoint "$TEST_DIR/explicit.args" USERNAME=editor PASSWORD=secret
[ "$(argument_value username "$TEST_DIR/explicit.args")" = "editor" ]
[ "$(argument_value password "$TEST_DIR/explicit.args")" = "secret" ]
[ "$(argument_value writers "$TEST_DIR/explicit.args")" = "editor" ]
[ "$(argument_value readers "$TEST_DIR/explicit.args")" = "(anon)" ]

run_entrypoint "$TEST_DIR/custom-filter.args" \
    EXCLUDED_PLUGINS_FILTER='[[$:/plugins/example/editor]]'
grep -Fx -- '[[$:/plugins/example/editor]]' "$TEST_DIR/custom-filter.args" >/dev/null

run_entrypoint "$TEST_DIR/exclusions-disabled.args" \
    EXCLUDE_EDITING_PLUGINS=false
if grep -Fx -- '--setfield' "$TEST_DIR/exclusions-disabled.args"; then
    echo "editing plugin exclusion was not disabled" >&2
    exit 1
fi
grep -Fx -- 'root-tiddler=$:/core/save/lazy-all' "$TEST_DIR/exclusions-disabled.args" >/dev/null

run_entrypoint "$TEST_DIR/custom-root.args" \
    ROOT_TIDDLER='$:/core/save/all'
grep -Fx -- 'root-tiddler=$:/core/save/all' "$TEST_DIR/custom-root.args" >/dev/null
grep -Fx -- '--setfield' "$TEST_DIR/custom-root.args" >/dev/null

echo "entrypoint tests passed"
