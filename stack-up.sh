#!/usr/bin/env bash
set -euo pipefail

# Load .env for local runs where env vars are not already exported.
if [[ -f ".env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source ".env"
  set +a
fi

if [[ -n "${CLOUDFLARED_TUNNEL_TOKEN:-}" ]]; then
  echo "CLOUDFLARED_TUNNEL_TOKEN detected: starting stack with cloud profile."
  docker compose --profile cloud up -d "$@"
else
  echo "No CLOUDFLARED_TUNNEL_TOKEN set: starting LAN/default stack."
  docker compose up -d "$@"
fi
