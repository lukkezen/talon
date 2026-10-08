FROM ghcr.io/ivo-toby/talond@sha256:cad826d0367f7109bf76786b7f5b8efa266c7c0090431b6e52c91e1cab095bcc

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
  io.hass.version="$BUILD_VERSION" \
  io.hass.type="app" \
  io.hass.arch="$BUILD_ARCH"

USER root

RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 \
      -o /usr/local/bin/ttyd \
    && chmod 0755 /usr/local/bin/ttyd

# The upstream image does not yet include this fork's attachment modules.
COPY install-video-support.cjs /opt/install-video-support.cjs
RUN set -eu; \
    for module in tools/host-tools/channel-send tools/host-tools-mcp-server channels/connectors/telegram/telegram-connector; do \
      mkdir -p "/tmp/talon-video/$(dirname "$module")"; \
      curl -fsSL "https://raw.githubusercontent.com/lukkezen/talon/8ad2cdeb997a3978aff2389839175ab3158cdb65/src/$module.ts" -o "/tmp/talon-video/$module.ts"; \
    done; \
    node /opt/install-video-support.cjs /tmp/talon-video /opt/talond/dist; \
    node --check /opt/talond/dist/tools/host-tools/channel-send.js; \
    node --check /opt/talond/dist/tools/host-tools-mcp-server.js; \
    node --check /opt/talond/dist/channels/connectors/telegram/telegram-connector.js

COPY run.sh /run.sh
COPY talonctl /usr/local/bin/talonctl
RUN chmod 0755 /run.sh /usr/local/bin/talonctl && mkdir -p /data/talon

ENTRYPOINT ["/usr/bin/tini", "--", "/run.sh"]
