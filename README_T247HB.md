## t247hb microservice launcher

This provides a single-container launcher image that starts the internal t247hb stack:

- Dashboard (pampadev/t247hb-dashboard)
- Hummingbot API (pampadev/t247hb-api)
- EMQX broker (internal only)
- Postgres (internal only)

Your other project only needs to run one container and care about:

- Dashboard: http://localhost:8501
- API: http://localhost:8000

### Contents

- `Dockerfile.t247hb-dashboard`: Builds dashboard image with `pages/` and `credentials.yml` baked in
- `Dockerfile.t247hb-api`: Builds API image with `bots/` baked in
- `stack/`
  - `stack.compose.yml`: Inner Compose file run by the launcher
  - `Dockerfile`: Launcher image that runs the inner compose
  - `entrypoint.sh`: Starts/stops the inner stack
  - `api.env.example`: Example env file for the inner API service
- `CONSUMER_COMPOSE_EXAMPLE.yml`: Example compose for your other project
- `Makefile`: Helpers to build/push with sensible defaults

### Auto date tags

- The launcher and Makefile default image tags to today’s date (`YYYY-MM-DD`).
- You can override with `TAG=...` (Makefile) or explicitly set `DASHBOARD_IMAGE` / `API_IMAGE` at runtime.
- To differentiate dev vs prod images, you can append a suffix using `TAG_SUFFIX` or use presets:
  - Dev: `make build-dev` / `make push-dev` -> tags like `2025-10-15-dev`
  - Prod: `make build-prod` / `make push-prod` -> tags like `2025-10-15-prod`
  - Inspect effective tag: `make date` (shows `TAG_WITH_SUFFIX`)

## Build images

From repo root (macOS, zsh):

- Build with Makefile (defaults to `REGISTRY=pampadev`, `TAG=$(date +%F)`):

  - Build all:
    - `make build`
  - Push all:
    - `make push`
  - Show effective tag:
    - `make date`

- Or build manually:
  - App images:
    - `docker build -f Dockerfile.t247hb-dashboard -t pampadev/t247hb-dashboard:$(date +%F) .`
    - `docker build -f Dockerfile.t247hb-api       -t pampadev/t247hb-api:$(date +%F) .`
  - Launcher:
    - `docker build -f stack/Dockerfile -t pampadev/t247hb-stack-launcher:$(date +%F) stack`
  - Push (optional):
    - `docker push pampadev/t247hb-dashboard:$(date +%F)`
    - `docker push pampadev/t247hb-api:$(date +%F)`
    - `docker push pampadev/t247hb-stack-launcher:$(date +%F)`

Using suffixes manually:

- Build dev images:
  - `make TAG_SUFFIX=-dev build`
- Build prod images:
  - `make TAG_SUFFIX=-prod build`
- Push dev/prod variants similarly with `make TAG_SUFFIX=-dev push` or `-prod`.

## Use from a consumer project

Create a compose file (see `CONSUMER_COMPOSE_EXAMPLE.yml`):

```yaml
services:
  t247hb:
    image: pampadev/t247hb-stack-launcher:2025-10-15 # or use today’s tag
    container_name: t247hb
    environment:
      USERNAME: admin
      PASSWORD: abc
      # Optional: override app images later
      # DASHBOARD_IMAGE: pampadev/t247hb-dashboard:2025-11-01
      # API_IMAGE: pampadev/t247hb-api:2025-11-01
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      # Optional: pass API env variables to inner API
      # - ./api.env:/config/api.env:ro
```

Run it:

```bash
docker compose up -d
```

Access:

- Dashboard: http://localhost:8501
- API: http://localhost:8000

### Notes

- EMQX and Postgres are internal; no published ports.
- The launcher requires access to the host Docker socket (`/var/run/docker.sock`).
- If you don’t push images to a registry, build on the same host where you run the consumer project.
- Date-based tags are used by default; you can override as needed.
- The launcher also accepts `TAG_SUFFIX` (e.g., `-dev`, `-prod`) to pick default images matching that suffix if you don’t override `DASHBOARD_IMAGE` / `API_IMAGE` explicitly.

## Smoke test

After your consumer project brings the stack up, you can run a simple smoke test from this repo to verify the Dashboard and API are reachable:

```bash
make smoke
```

This will:

- Probe the Dashboard at http://localhost:8501
- Try common API endpoints at http://localhost:8000 (health, docs, etc.)

Environment overrides (optional):

- `HOST` (default: localhost)
- `DASHBOARD_URL` (default: http://localhost:8501/)
- `API_BASE` (default: http://localhost:8000)
- `TIMEOUT_SECS` (default: 120)

## Dev vs Prod modes

The Dashboard is intended for development. For production, you should not expose it or even start it. We provide two mechanisms:

1. Compose profiles (default file):

- The `dashboard` service in `stack/stack.compose.yml` is marked with `profiles: [dev]`.
- By default (no profiles), the dashboard will NOT start.
- To enable for development, set the env var `COMPOSE_PROFILES=dev` when running the launcher container.

2. Dedicated production compose file:

- Use `stack/stack.compose.prod.yml`, which excludes the dashboard entirely.
- Set `COMPOSE_FILE_PATH=/stack/stack.compose.prod.yml` in the launcher container env to use it.

Smoke testing in production:

- When the dashboard is disabled, run the smoke test with `SKIP_DASHBOARD_CHECK=1` to avoid checking port 8501.
