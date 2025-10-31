#!/usr/bin/env bash

set -euo pipefail

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${THIS_DIR}/.." && pwd)"

source "${THIS_DIR}/common.sh"

DEVCONTAINER_RUN=0

while (( "$#" )); do
  case "$1" in
    --devcontainer)
      DEVCONTAINER_RUN=1
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Usage: scripts/bootstrap.sh [--devcontainer]

Prepare the developer platform by installing dependencies, copying template
environment files, and configuring Git hooks.
EOF
      exit 0
      ;;
    *)
      log WARN "Unknown argument: $1"
      shift
      ;;
  esac
done

cd "${PROJECT_ROOT}"

copy_template() {
  local template="$1"
  local target="$2"

  if [ -f "${target}" ]; then
    log INFO "Keeping existing ${target}"
  elif [ -f "${template}" ]; then
    cp "${template}" "${target}"
    log INFO "Created ${target} from template"
  fi
}

copy_template ".env.template" ".env"
copy_template ".env.local.template" ".env.local"

seed_jarvis_templates() {
  local jarvis_root
  jarvis_root="$(resolve_jarvis_root)"
  local template_root="${PROJECT_ROOT}/templates/jarvis"

  if [ ! -d "${jarvis_root}" ]; then
    log WARN "Jarvis repository not found at ${jarvis_root}; skipping template sync."
    return
  fi

  if [ ! -d "${template_root}" ]; then
    return
  fi

  log INFO "Syncing environment templates into Jarvis repo at ${jarvis_root}"
  while IFS= read -r template; do
    local relative="${template#${template_root}/}"
    local target="${jarvis_root}/${relative%.template}"
    mkdir -p "$(dirname "${target}")"
    if [ -f "${target}" ]; then
      log INFO "Keeping existing ${target}"
    else
      cp "${template}" "${target}"
      log INFO "Created ${target}"
    fi
  done < <(find "${template_root}" -type f -name '*.template' | sort)
}

seed_jarvis_templates

ensure_task() {
  if command -v task >/dev/null 2>&1; then
    return
  fi

  log INFO "Installing Taskfile CLI (task)"
  mkdir -p "${HOME}/.local/bin"
  sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b "${HOME}/.local/bin"
  export PATH="${HOME}/.local/bin:${PATH}"

  if ! command -v task >/dev/null 2>&1; then
    log WARN "Task installation skipped or failed; please install manually."
  fi
}

ensure_pre_commit() {
  if command -v pre-commit >/dev/null 2>&1; then
    return
  fi

  if command -v uv >/dev/null 2>&1; then
    log INFO "Installing pre-commit with uv"
    uv tool install pre-commit
  else
    log INFO "Installing pre-commit with pip --user"
    python3 -m pip install --user pre-commit
    export PATH="${HOME}/.local/bin:${PATH}"
  fi
}

ensure_task
ensure_pre_commit

if command -v pre-commit >/dev/null 2>&1; then
  if [ -d "${PROJECT_ROOT}/.git" ]; then
    pre-commit install --install-hooks
  else
    log WARN "Not a git repository; skipping pre-commit hook installation."
  fi
else
  log WARN "pre-commit not available; skipped hook installation."
fi

if command -v task >/dev/null 2>&1; then
  if task --list >/dev/null 2>&1; then
    log INFO "Installing project dependencies via Task"
    task sync || log WARN "Dependency bootstrap incomplete; check logs above."
  fi
else
  log WARN "Task CLI missing; dependency bootstrap skipped."
fi

if [ "${DEVCONTAINER_RUN}" -eq 1 ]; then
  log INFO "Devcontainer bootstrap complete."
else
  log INFO "Bootstrap finished."
fi
