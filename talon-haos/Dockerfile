FROM ghcr.io/ivo-toby/talond:latest

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
  io.hass.version="$BUILD_VERSION" \
  io.hass.type="app" \
  io.hass.arch="$BUILD_ARCH"

USER root

COPY run.sh /run.sh
RUN chmod 0755 /run.sh && mkdir -p /data/talon

ENTRYPOINT ["/run.sh"]
