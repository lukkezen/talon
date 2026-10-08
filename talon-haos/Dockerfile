FROM ghcr.io/ivo-toby/talond:latest

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

# Apply Talon channel and MCP compatibility modules from a reviewed source revision.
# The upstream base image follows latest; check compatibility on each rebuild.
ARG TALON_SOURCE_REF=6eba57c713c07aabdcf0884afc532307a0c306ae
COPY install-runtime-overlays.cjs /opt/install-runtime-overlays.cjs
RUN set -eu; \
    for module in \
      tools/host-tools/channel-send \
      tools/host-tools-mcp-server \
      channels/connectors/telegram/telegram-connector \
      providers/openai-compatible/agent-cli/responses-api; do \
      mkdir -p "/tmp/talon-overlay/$(dirname "$module")"; \
      curl -fsSL "https://raw.githubusercontent.com/lukkezen/talon/$TALON_SOURCE_REF/src/$module.ts" \
        -o "/tmp/talon-overlay/$module.ts"; \
    done; \
    node /opt/install-runtime-overlays.cjs /tmp/talon-overlay /opt/talond/dist; \
    for module in \
      tools/host-tools/channel-send \
      tools/host-tools-mcp-server \
      channels/connectors/telegram/telegram-connector \
      providers/openai-compatible/agent-cli/responses-api; do \
      node --check "/opt/talond/dist/$module.js"; \
    done

COPY run.sh /run.sh
COPY talonctl /usr/local/bin/talonctl
RUN chmod 0755 /run.sh /usr/local/bin/talonctl && mkdir -p /data/talon

ENTRYPOINT ["/usr/bin/tini", "--", "/run.sh"]
