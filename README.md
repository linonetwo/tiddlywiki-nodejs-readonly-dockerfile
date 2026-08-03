# TiddlyWiki Node.js Readonly Server

A read-only server for [TiddlyWiki](https://tiddlywiki.com/) wikis, based on [TidGi-Desktop](https://github.com/tiddly-gittly/TidGi-Desktop)'s `startNodeJSWiki.ts`.

## Docker Image

**Docker Hub:** `linonetwo/tiddlywiki-nodejs-readonly`

## Usage

```bash
docker run -p 8080:8080 -v /path/to/wiki:/wiki linonetwo/tiddlywiki-nodejs-readonly
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WIKI_PATH` | `/wiki` | Path to the wiki folder (repo root when using git subPath) |
| `WIKI_SUBPATH` | `` | Subdirectory inside WIKI_PATH that contains tiddlywiki.info |
| `PORT` | `8080` | Server port |
| `HOST` | `0.0.0.0` | Bind address |
| `ROOT_TIDDLER` | `$:/core/save/lazy-all` | Root tiddler for lazy loading |
| `READ_ONLY_MODE` | `true` | Enable read-only with gzip |
| `USERNAME` | Random `readonly-<24 chars>` | Writer username; generated per container start when omitted |
| `PASSWORD` | Random 64 characters | Writer password; generated per container start when omitted |
| `EXCLUDE_EDITING_PLUGINS` | `true` | Exclude editing-only plugins from the generated read-only HTML |
| `EXCLUDED_PLUGINS_FILTER` | See below | TiddlyWiki filter selecting plugin tiddlers to omit from HTML |

With `READ_ONLY_MODE=true`, anonymous users remain readers. Writing requires the
configured credentials or the unreported random credentials generated at
startup, so an instance without `USERNAME` and `PASSWORD` is safely read-only.

## Why the default is read-only

This follows the argument pattern used by TidGi Desktop's
`startNodeJSWiki.ts`:

```ts
const readonlyArguments = readOnlyMode === true
  ? [
      'gzip=yes',
      'readers=(anon)',
      `writers=${userName || nanoid()}`,
      `username=${userName}`,
      `password=${nanoid()}`,
    ]
  : [];
```

The container passes the equivalent TiddlyWiki listen arguments:

```text
readers=(anon)
writers=readonly-<random 24 characters>
username=readonly-<same random 24 characters>
password=<random 64 characters>
```

`readers=(anon)` permits public read requests. `writers` does not contain
`(anon)`, so an anonymous request cannot save, rename, or delete a tiddler.
When `USERNAME` and `PASSWORD` are omitted, the only writer account is generated
at container startup and its credentials are neither logged nor exposed. Normal
visitors therefore cannot authenticate as the generated writer, while the wiki
remains publicly readable.

Providing `USERNAME` and `PASSWORD` intentionally creates a known writer
account. Setting `READ_ONLY_MODE=false` disables this protection and starts
TiddlyWiki with `credentials=false`.

## Excluding editing plugins

TidGi Desktop excludes editing plugins by clearing their in-memory payloads
with `--setfield`. This image does not use that command because a wiki with the
filesystem syncer can persist the cleared value back to the mounted wiki.

Instead, the container loads a small temporary plugin that provides a variant
of `$:/core/save/lazy-all`. Its `saveTiddlerFilter` removes matching plugin
tiddlers only while generating the browser HTML. The source plugin tiddlers
remain available to the server, and source `.tid` and `.json` files on the
mounted wiki volume are never rewritten or deleted by the exclusion feature.
The temporary plugin is created under `/tmp` for each container start.

The default filter excludes these editing-heavy plugins:

- TiddlyWiki CodeMirror and all bundled CodeMirror add-ons
- `oeyoews/tiddlywiki-codemirror-6`
- `Gk0Wk/TW5-CodeMirror-Enhanced`
- TiddlyWiki ProseMirror
- `linonetwo/tw-whiteboard`
- `linonetwo/tw-calendar`

Set `EXCLUDE_EDITING_PLUGINS=false` to serve every plugin. To replace the
defaults, provide a complete TiddlyWiki filter:

```bash
docker run --rm -p 8080:8080 \
  -e 'EXCLUDED_PLUGINS_FILTER=[prefix[$:/plugins/tiddlywiki/codemirror]] [[$:/plugins/example/editor]]' \
  -v /path/to/wiki:/wiki \
  linonetwo/tiddlywiki-nodejs-readonly
```

Plugin exclusion is applied only when `READ_ONLY_MODE=true` and
`ROOT_TIDDLER=$:/core/save/lazy-all`. A custom root tiddler is preserved, and
the entrypoint logs that exclusion was skipped.

## CI/CD

Push to `master` → GitHub Actions builds and pushes to Docker Hub automatically.

## License

MIT
