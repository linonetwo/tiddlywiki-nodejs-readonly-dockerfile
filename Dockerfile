FROM node:20-alpine AS builder

WORKDIR /app

# Install tiddlywiki and dependencies
RUN apk add --no-cache git python3 make g++ && \
    npm install -g npm@latest

# Install tiddlywiki from npm (official release)
RUN npm install tiddlywiki@5.3.6

# Copy startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Runtime stage
FROM node:20-alpine

RUN apk add --no-cache tzdata ca-certificates

COPY --from=builder /app/node_modules /usr/local/lib/node_modules
COPY --from=builder /entrypoint.sh /entrypoint.sh

# Create symlink so tiddlywiki is in PATH
RUN ln -s /usr/local/lib/node_modules/tiddlywiki/tiddlywiki.js /usr/local/bin/tiddlywiki

# Volume for wiki data
VOLUME ["/wiki"]

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
