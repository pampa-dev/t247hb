#!/usr/bin/env bash
# Simple smoke test for t247hb: checks Dashboard (8501) and API (8000)
set -euo pipefail

HOST=${HOST:-localhost}
DASHBOARD_URL=${DASHBOARD_URL:-http://$HOST:8501/}
# Set to 1 to skip dashboard check (used in prod where dashboard is disabled)
SKIP_DASHBOARD_CHECK=${SKIP_DASHBOARD_CHECK:-0}
# Try common API health endpoints in order
API_BASE=${API_BASE:-http://$HOST:8000}
API_PATHS=("/")
TIMEOUT_SECS=${TIMEOUT_SECS:-120}
SLEEP_SECS=${SLEEP_SECS:-2}

log() { echo "[smoke] $*"; }

http_ok() {
  local url="$1"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" "$url" || true)
  [[ "$code" =~ ^2[0-9][0-9]$ ]]
}

wait_for_ok() {
  local name="$1"; shift
  local url_fn="$1"; shift
  local deadline=$(( $(date +%s) + TIMEOUT_SECS ))
  while [[ $(date +%s) -lt $deadline ]]; do
    local url
    url=$(eval echo "$url_fn")
    if http_ok "$url"; then
      log "OK: $name is reachable at $url"
      return 0
    fi
    log "Waiting for $name at $url ..."
    sleep "$SLEEP_SECS"
  done
  log "FAIL: $name did not become ready within ${TIMEOUT_SECS}s"
  return 1
}

# 1) Dashboard (optional)
if [[ "$SKIP_DASHBOARD_CHECK" -eq 1 ]]; then
  log "Skipping dashboard check (SKIP_DASHBOARD_CHECK=1)"
else
  wait_for_ok "Dashboard" "$DASHBOARD_URL"
fi

# 2) API (try multiple paths)
api_ready=1
for p in "${API_PATHS[@]}"; do
  if wait_for_ok "API" "${API_BASE}${p}"; then
    api_ready=0
    break
  fi
  # Short pause between attempts to different paths
  sleep 1
  # Reset timeout per path attempt
  :
  # (We rely on per-attempt timeout above)
  # Continue trying next path
  continue

done

if [[ $api_ready -ne 0 ]]; then
  log "FAIL: API did not respond OK on any of: ${API_PATHS[*]}"
  exit 2
fi

log "SUCCESS: t247hb smoke test passed."
