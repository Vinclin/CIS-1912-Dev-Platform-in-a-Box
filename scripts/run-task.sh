#!/usr/bin/env bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${THIS_DIR}/common.sh"

if [ "$#" -lt 1 ]; then
  echo "Usage: scripts/run-task.sh <task> [args...]" >&2
  exit 2
fi

TARGET="$1"
shift || true

if ! command -v task >/dev/null 2>&1; then
  log ERROR "Task CLI not found in PATH. Install it via scripts/bootstrap.sh or visit https://taskfile.dev/#/installation."
  exit 127
fi

TARGET_REQUIRED=1
case "${TARGET}" in
  doctor|bootstrap)
    TARGET_REQUIRED=0
    ;;
esac

if [ "${TARGET_REQUIRED}" -eq 1 ]; then
  TARGET_ROOT="$(resolve_target_root)"
  if [ ! -d "${TARGET_ROOT}" ]; then
    if [ "${RUN_TASK_STRICT:-0}" -eq 1 ]; then
      log ERROR "Target project directory expected at ${TARGET_ROOT} but not found."
      exit 1
    fi
    log WARN "Skipping task '${TARGET}' because target project directory is missing (expected at ${TARGET_ROOT})."
    exit 0
  fi
fi

task "${TARGET}" "$@"
