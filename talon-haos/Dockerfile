# Home Assistant builds add-ons with talon-haos/ as the Docker context.
# Source commit and add-on version are pinned by the automatic HA release workflow.
# The release commit is not itself used as the source to avoid circular references.
FROM node:24-bookworm-slim AS builder
ARG TALON_GIT_REF=c8ac8d38ed55ad1c0955055f1d6a8b412e4976ae
RUN apt-get update && apt-get install -y --no-install-recommends python3 make g++ git ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /opt/talond
RUN git init . \
 && git remote add origin https://github.com/lukkezen/talon.git \
 && git fetch --depth 1 origin "$TALON_GIT_REF" \
 && git checkout --detach FETCH_HEAD \
 && npm ci \
 && npm run build \
 && npm prune --omit=dev

FROM node:24-bookworm-slim
ARG BUILD_VERSION=1.0.11
ARG BUILD_ARCH=amd64
LABEL io.hass.version="${BUILD_VERSION}" io.hass.type="app" io.hass.arch="${BUILD_ARCH}"
RUN apt-get update && apt-get install -y --no-install-recommends tini curl jq bash ca-certificates util-linux passwd && rm -rf /var/lib/apt/lists/* \
 && useradd -m -s /bin/bash talond \
 && curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 -o /usr/local/bin/ttyd \
 && echo "8a217c968aba172e0dbf3f34447218dc015bc4d5e59bf51db2f2cd12b7be4f55  /usr/local/bin/ttyd" | sha256sum -c - \
 && chmod 0755 /usr/local/bin/ttyd
RUN npm install -g @openai/codex@0.159.0
WORKDIR /opt/talond
COPY --from=builder /opt/talond/package.json ./package.json
COPY --from=builder /opt/talond/node_modules ./node_modules
COPY --from=builder /opt/talond/dist ./dist
COPY run.sh /run.sh
COPY talonctl /usr/local/bin/talonctl
COPY ingress-proxy.cjs /usr/local/lib/talon-ingress-proxy.cjs
COPY check-config.cjs /usr/local/lib/talon-check-config.cjs
COPY sync-attachment-origins.cjs /usr/local/lib/talon-sync-attachment-origins.cjs
RUN chmod 0755 /run.sh /usr/local/bin/talonctl && mkdir -p /data/talon
# Intentionally omit HEALTHCHECK. Explicit NONE leaves a nonempty metadata
# object that Supervisor treats as a check, waiting forever for a health event.
# The image smoke test also verifies that the base does not inherit a check.
ENTRYPOINT ["/usr/bin/tini", "--", "/run.sh"]
