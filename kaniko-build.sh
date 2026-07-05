#!/bin/sh
VERSION=$(date +%Y%m%d-%H%M%S)
echo "Building version $VERSION"

mkdir -p /kaniko/.docker
AUTH=$(printf "%s:%s" "$HARBOR_USER" "$HARBOR_PASSWORD" | base64)
# Auth for push (harbor) + pull via mapped registry (both names)
printf '{"auths":{"harbor.k3s.onetwo.website":{"auth":"%s"},"harbor-docker-io.k3s.onetwo.website":{"auth":"%s"},"index.docker.io":{"auth":"%s"},"docker.io":{"auth":"%s"}}}\n' "$AUTH" "$AUTH" "$AUTH" "$AUTH" > /kaniko/.docker/config.json

echo "=== Starting Kaniko ==="
/kaniko/executor --context dir:///workspace/lindongwu/tiddlywiki-nodejs-readonly-dockerfile --dockerfile Dockerfile --destination "harbor.k3s.onetwo.website/library/tiddlywiki-nodejs-readonly:$VERSION" --destination harbor.k3s.onetwo.website/library/tiddlywiki-nodejs-readonly:latest --registry-map index.docker.io=harbor-docker-io.k3s.onetwo.website --skip-tls-verify-registry=harbor-docker-io.k3s.onetwo.website --cache=true --cache-repo=harbor.k3s.onetwo.website/library/tiddlywiki-nodejs-readonly-cache --cache-copy-layers --cleanup --verbosity=info
echo "Pushed version: $VERSION"
