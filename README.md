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
| `WIKI_PATH` | `/wiki` | Path to the wiki folder |
| `PORT` | `8080` | Server port |
| `HOST` | `0.0.0.0` | Bind address |
| `ROOT_TIDDLER` | `$:/core/save/lazy-all` | Root tiddler for lazy loading |
| `READ_ONLY_MODE` | `true` | Enable read-only with gzip |
| `USERNAME` | `admin` | Admin username |
| `PASSWORD` | `changeme` | Admin password |

## CI/CD

Push to `master` → GitHub Actions builds and pushes to Docker Hub automatically.

## License

MIT
