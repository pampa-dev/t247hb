#!/usr/bin/env bash
set -euo pipefail

# Compute today's date tag (YYYY-MM-DD) if not provided
TODAY_TAG=$(date +%F)

export DASHBOARD_IMAGE=${DASHBOARD_IMAGE:-pampadev/t247hb-dashboard:${TODAY_TAG}}
export API_IMAGE=${API_IMAGE:-pampadev/t247hb-api:${TODAY_TAG}}

# If a file is mounted at /config/api.env, use it for the inner API service
if [[ -f "/config/api.env" ]]; then
  cp /config/api.env /stack/api.env
fi

# Docker socket must be mounted so the launcher can run the inner stack
if [[ ! -S "/var/run/docker.sock" ]]; then
  echo "Error: /var/run/docker.sock must be mounted into this container." >&2
  exit 1
fi

# Select compose file; default to the standard stack which includes dev-only services guarded by profiles
COMPOSE_FILE_PATH=${COMPOSE_FILE_PATH:-/stack/stack.compose.yml}

# Allow enabling compose profiles (e.g., COMPOSE_PROFILES=dev) from the environment
export COMPOSE_PROFILES=${COMPOSE_PROFILES:-}

# Bring up the inner stack (detached)
docker compose -p "${COMPOSE_PROJECT_NAME:-t247hb}" -f "${COMPOSE_FILE_PATH}" up -d

# Shutdown handler
_term() {
  echo "Stopping t247hb stack..."
  docker compose -p "${COMPOSE_PROJECT_NAME:-t247hb}" -f "${COMPOSE_FILE_PATH}" down
  exit 0
}
trap _term SIGTERM SIGINT

# Keep the container running
while true; do sleep 3600; done
