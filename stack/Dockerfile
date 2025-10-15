# Launcher image that starts the inner t247hb stack via the host Docker engine
FROM alpine:3.20

RUN apk add --no-cache docker-cli docker-cli-compose bash ca-certificates curl jq

COPY stack.compose.yml /stack/stack.compose.yml
COPY stack.compose.prod.yml /stack/stack.compose.prod.yml
COPY entrypoint.sh /stack/entrypoint.sh
RUN chmod +x /stack/entrypoint.sh && \
    touch /stack/api.env

ENV COMPOSE_PROJECT_NAME=t247hb
WORKDIR /stack
ENTRYPOINT ["/stack/entrypoint.sh"]
