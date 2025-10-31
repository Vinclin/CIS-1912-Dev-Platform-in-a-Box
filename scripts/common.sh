#!/usr/bin/env bash

# Common helper functions for project scripts.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
  local level="${1:-INFO}"
  shift || true
  printf '[%s] %s\n' "$level" "$*" 1>&2
}

read_dotenv_var() {
  local key="$1"
  local default="${2:-}"
  local value="${default}"

  if [ -f "${PROJECT_ROOT}/.env" ]; then
    local line
    line="$(grep -E "^${key}=" "${PROJECT_ROOT}/.env" | tail -n1 || true)"
    if [ -n "$line" ]; then
      value="${line#${key}=}"
      value="${value%$'\r'}"
    fi
  fi

  printf '%s' "${value}"
}

resolve_var() {
  local key="$1"
  local default="${2:-}"

  if [ -n "${!key:-}" ]; then
    printf '%s' "${!key}"
    return
  fi

  read_dotenv_var "$key" "$default"
}

resolve_target_root() {
  resolve_var "TARGET_ROOT" "${PROJECT_ROOT}/target"
}

resolve_compose_file() {
  resolve_var "COMPOSE_FILE" "compose.yaml"
}

resolve_compose_project_name() {
  resolve_var "COMPOSE_PROJECT_NAME" "devplatform"
}
