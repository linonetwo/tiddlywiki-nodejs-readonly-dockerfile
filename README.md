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

The image uses the same command sequence as TidGi Desktop's
`startNodeJSWiki.ts`. The exclusion filter is appended after `--listen`:

```text
--setfield <excluded-plugin-filter> text "" text/plain
```

No temporary plugin, shadow tiddler, configuration tiddler, or replacement save
template is created. The selected plugin payloads are cleared in the running
wiki exactly as they are in TidGi Desktop.

TidGi Desktop does not load its filesystem write adaptor in read-only mode. A
server wiki may still explicitly list `tiddlywiki/filesystem` in
`tiddlywiki.info`, so the Node launcher protects only the selected plugin
titles from filesystem synchronization for the lifetime of the process. All
other tiddlers continue to use the configured adaptor. This prevents the
exclusion operation from rewriting source plugin files without changing its
upstream rendering behavior.

The default filter excludes these editing-heavy plugins:

- TiddlyWiki CodeMirror and all bundled CodeMirror add-ons
- `oeyoews/tiddlywiki-codemirror-6`
- `Gk0Wk/TW5-CodeMirror-Enhanced`
- TiddlyWiki ProseMirror
- `linonetwo/tw-whiteboard`
- `linonetwo/calendar`
- `linonetwo/tw-calendar`

Set `EXCLUDE_EDITING_PLUGINS=false` to serve every plugin. To replace the
defaults, provide a complete TiddlyWiki filter:

```bash
docker run --rm -p 8080:8080 \
  -e 'EXCLUDED_PLUGINS_FILTER=[prefix[$:/plugins/tiddlywiki/codemirror]] [[$:/plugins/example/editor]]' \
  -v /path/to/wiki:/wiki \
  linonetwo/tiddlywiki-nodejs-readonly
```

Plugin exclusion is applied only when `READ_ONLY_MODE=true`.

## CI/CD

Push to `master` → GitHub Actions builds and pushes to Docker Hub automatically.

## License

MIT
