#!/bin/sh
set -e
VERSION=$(date +%Y%m%d-%H%M%S)
echo "Building version $VERSION"

mkdir -p /kaniko/.docker
AUTH=$(printf "%s:%s" "$HARBOR_USER" "$HARBOR_PASSWORD" | base64 2>/dev/null || printf "%s:%s" "$HARBOR_USER" "$HARBOR_PASSWORD" | openssl base64 -A 2>/dev/null)
# Auth for pushing AND mirror pull
printf '{"auths":{"harbor.k3s.onetwo.website":{"auth":"%s"},"harbor-docker-io.k3s.onetwo.website":{"auth":"%s"}}}\n' "$AUTH" "$AUTH" > /kaniko/.docker/config.json

echo "=== Starting Kaniko ==="
/kaniko/executor --context dir:///workspace/lindongwu/tiddlywiki-nodejs-readonly-dockerfile --dockerfile Dockerfile --destination "harbor.k3s.onetwo.website/library/tiddlywiki-nodejs-readonly:$VERSION" --destination harbor.k3s.onetwo.website/library/tiddlywiki-nodejs-readonly:latest --registry-mirror=harbor-docker-io.k3s.onetwo.website --cache=true --cache-repo=harbor.k3s.onetwo.website/library/tiddlywiki-nodejs-readonly-cache --cache-copy-layers --cleanup --verbosity=info
echo "Pushed version: $VERSION"
