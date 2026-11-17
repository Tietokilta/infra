FROM ghcr.io/twin/gatus:v5.38.0

COPY config.yaml /app/config.yaml

ENV GATUS_CONFIG_PATH=/app/config.yaml

# Validate config.yaml: Gatus exits with an error on an invalid config, and
# shuts down cleanly when the timeout stops it. Its image has no shell, so
# borrow a static busybox for this step.
RUN --mount=from=busybox:1.38.0-musl,src=/bin,dst=/bin \
  TELEGRAM_TOKEN=x ALERT_CHANNEL_ID=x INFOSCREEN_TOKEN=x BACKUPS_TOKEN=x timeout 5 /gatus
