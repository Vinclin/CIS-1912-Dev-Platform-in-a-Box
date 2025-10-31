#!/usr/bin/env bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${THIS_DIR}/common.sh"

TARGET_ROOT="$(resolve_target_root)"
COMPOSE_FILE="$(resolve_compose_file)"
COMPOSE_PROJECT_NAME="$(resolve_compose_project_name)"
DB_SERVICE="$(resolve_var "HEALTHCHECK_DB_SERVICE" "db")"
DB_USERNAME="$(resolve_var "HEALTHCHECK_DB_USER" "jarvis")"
DB_NAME="$(resolve_var "HEALTHCHECK_DB_NAME" "jarvis")"

if [ ! -d "${TARGET_ROOT}" ]; then
  if [ "${HEALTHCHECK_STRICT:-0}" -eq 1 ] || [ "${RUN_TASK_STRICT:-0}" -eq 1 ]; then
    log ERROR "Target project directory not found at ${TARGET_ROOT}"
    exit 1
  else
    log WARN "Target project directory not found at ${TARGET_ROOT}; skipping healthcheck."
    exit 0
  fi
fi

log INFO "Validating docker compose definition"
cd "${TARGET_ROOT}"
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
if docker compose --project-name "${COMPOSE_PROJECT_NAME}" -f "${COMPOSE_FILE}" ps "${DB_SERVICE}" >/dev/null 2>&1; then
  docker compose --project-name "${COMPOSE_PROJECT_NAME}" -f "${COMPOSE_FILE}" exec -T "${DB_SERVICE}" pg_isready -U "${DB_USERNAME}" -d "${DB_NAME}" || \
    log WARN "pg_isready failed; database may not be healthy."
else
  log WARN "Database service not running or not named ${DB_SERVICE}; skipping pg_isready."
fi

log INFO "Healthcheck complete."
