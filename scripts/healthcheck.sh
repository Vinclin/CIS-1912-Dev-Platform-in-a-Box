#!/usr/bin/env bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${THIS_DIR}/common.sh"

JARVIS_ROOT="$(resolve_jarvis_root)"
COMPOSE_FILE="$(resolve_compose_file)"
COMPOSE_PROJECT_NAME="$(resolve_compose_project_name)"

if [ ! -d "${JARVIS_ROOT}" ]; then
  if [ "${HEALTHCHECK_STRICT:-0}" -eq 1 ] || [ "${RUN_TASK_STRICT:-0}" -eq 1 ]; then
    log ERROR "Jarvis repository not found at ${JARVIS_ROOT}"
    exit 1
  else
    log WARN "Jarvis repository not found at ${JARVIS_ROOT}; skipping healthcheck."
    exit 0
  fi
fi

log INFO "Validating docker compose definition"
cd "${JARVIS_ROOT}"
docker compose --project-name "${COMPOSE_PROJECT_NAME}" -f "${COMPOSE_FILE}" config >/dev/null
log INFO "Compose configuration is valid"

log INFO "Checking service status"
if docker compose --project-name "${COMPOSE_PROJECT_NAME}" -f "${COMPOSE_FILE}" ps >/dev/null 2>&1; then
  RUNNING_COUNT="$(docker compose --project-name "${COMPOSE_PROJECT_NAME}" -f "${COMPOSE_FILE}" ps --status running --services | wc -l | tr -d '[:space:]')"
  if [ "${RUNNING_COUNT}" -gt 0 ]; then
    log INFO "${RUNNING_COUNT} service(s) currently running."
  else
    log WARN "No running containers detected. Start the stack with 'task compose-up'."
  fi
else
  log WARN "Unable to read compose status. Is docker running?"
fi

log INFO "Testing connectivity to Postgres (if running)"
if docker compose --project-name "${COMPOSE_PROJECT_NAME}" -f "${COMPOSE_FILE}" ps db >/dev/null 2>&1; then
  docker compose --project-name "${COMPOSE_PROJECT_NAME}" -f "${COMPOSE_FILE}" exec -T db pg_isready -U jarvis -d jarvis || \
    log WARN "pg_isready failed; database may not be healthy."
else
  log WARN "Database service not running; skipping pg_isready."
fi

log INFO "Healthcheck complete."
