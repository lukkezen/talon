FROM ghcr.io/ivo-toby/talond:latest

USER root

COPY run.sh /run.sh
RUN chmod 0755 /run.sh && mkdir -p /data/talon

ENTRYPOINT ["/run.sh"]
