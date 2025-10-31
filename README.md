# Developer Platform in a Box

This repository packages a reproducible developer platform that you can point at any existing project. It combines a devcontainer-based workspace, a shared task runner, automated quality gates, secrets scaffolding, and CI automation so every engineer can spin up the full stack with minimal effort. Sample templates for the CIS 1912 Jarvis lab stack are included, but the tooling works with any codebase.

---

## 1. Feature Overview
- **Containerised workstation** via `.devcontainer/` with uv, Node.js, Docker CLI, Postgres/Redis clients, and the Task CLI pre-installed.
- **Unified task runner** (`Taskfile.yml`) that wraps dependency installs, linting, testing, security scans, Docker Compose lifecycle, and migration utilities.
- **Bootstrap automation** (`scripts/bootstrap.sh`) that seeds environment files, installs tooling, and syncs templates into your target project.
- **Secrets management templates** under `templates/` to standardise `.env` files (public + private) across services (Jarvis-specific samples are provided by default).
- **Quality gates** powered by pre-commit hooks and reusable shell wrappers (`scripts/*.sh`) so local workflows match CI.
- **GitHub Actions pipeline** (`.github/workflows/ci.yml`) running pre-commit, lint/test/security tasks, and Compose configuration validation.

---

## 2. Quick Start

### Prerequisites
- Docker Engine with the Compose plugin
- Git, curl, bash
- Optional (for native usage) installations of Python 3.11+, Node.js 20+, and the [Task CLI](https://taskfile.dev/#/installation)

### Option A – Devcontainer (recommended)
1. Clone this repo and the project you want to automate (or update `.env.template` with the correct `TARGET_ROOT`).
2. Open the folder in VS Code or `devcontainer up`.
3. The `postCreateCommand` runs `scripts/bootstrap.sh --devcontainer`, installing hooks, syncing templates, and prepping dependencies.
4. Use `task doctor` inside the container to verify tool versions.

### Option B – Native shell
1. Copy `.env.template` to `.env` and update `TARGET_ROOT` to point at the project you want to automate.
2. Run `bash scripts/bootstrap.sh` to install Task + pre-commit, seed environment files, and queue dependency installs.
3. Execute recurring workflows via `task <target>` or the helper scripts in `scripts/`.


**Note:** The repo ships with sample templates for the Jarvis lab (`templates/jarvis/**`). Delete or replace them when targeting a different project.

---

## 3. Daily Workflow Cheat Sheet
- `task sync` – Install frontend + backend dependencies with uv/npm.
- `task lint` / `bash scripts/lint.sh` – Run ruff and frontend lint scripts.
- `task format` – Apply code formatters (ruff format + prettier fallback).
- `task test` – Execute backend pytest and frontend test scripts (skips if undefined).
- `task security` – Run `bandit` via `uvx` and `npm audit --audit-level=high`.
- `task compose-up` / `task compose-down` – Manage the Docker Compose stack.
- `task migrate` – Apply Alembic migrations for the shared database.
- `task healthcheck` – Validate Compose configuration and service health.
- `task ci` – Aggregate lint, test, and security steps (mirrors the CI workflow).

All task targets honour the `.env` or `.env.local` overrides. If the target project directory is missing, wrapper scripts skip gracefully unless `RUN_TASK_STRICT=1` is set.

---

## 4. Secrets & Environment Management
- Copy `.env.template` to `.env` to configure `TARGET_ROOT`, Compose options, and relative service paths.
- Files under `templates/` are copied into the target project (only when the destination file is missing). This repo ships with Jarvis-specific examples under `templates/jarvis/`; keep them, remove them, or replace them with templates that match your own repository structure.
- Sensitive keys (Gemini, Brave Search) live in `backend/services/chat/docker.env.private`, which remains gitignored upstream. The template provides placeholder values and guidance.
- Use `.env.local` (from `.env.local.template`) for machine-specific overrides that should not be checked in.

---

## 5. Automation Tooling

### Pre-commit
- Configured via `.pre-commit-config.yaml` to run base hygiene hooks plus project tasks (`task format/lint/test/security`).
- Install hooks with `pre-commit install` (handled automatically by `scripts/bootstrap.sh`).
- Temporarily skip expensive hooks via `SKIP=task-test,task-security git commit ...`.

### GitHub Actions
- Workflow: `.github/workflows/ci.yml`.
- Steps: checkout → setup uv/node/task → run pre-commit → execute lint/test/security via task wrappers → perform Compose validation (`scripts/healthcheck.sh`).
- The job succeeds even if the target project directory is not present, but emits warnings so you remember to clone it or set `TARGET_ROOT` correctly.
- To integrate with a private repository, add a checkout step in the workflow or extend `scripts/bootstrap.sh` to clone from a secret URL.

---

## 6. Devcontainer Details
- Base image: `mcr.microsoft.com/devcontainers/base:ubuntu-24.04`.
- Installs: uv, node 20 (with pnpm + npm), docker CLI + compose plugin, Postgres & Redis clients, Task CLI.
- Mounts host Docker socket for Compose parity.
- `postCreateCommand` reruns bootstrap to ensure hooks + templates are applied inside the container.
- Custom VS Code extensions provide Python, Ruff, Docker, and GitHub Actions integration.

---

## 7. Health Checks & Troubleshooting
- `task healthcheck` (or `bash scripts/healthcheck.sh`) validates `docker compose config`, inspects running services, and probes Postgres readiness when available. Configure `HEALTHCHECK_DB_SERVICE`, `HEALTHCHECK_DB_USER`, and `HEALTHCHECK_DB_NAME` in your env files if your database service uses different identifiers.
- Use `task doctor` to confirm binary versions across host and container environments.
- If `task` or `pre-commit` are missing, rerun `scripts/bootstrap.sh`. The script installs both (using uv where possible) and keeps user-level binaries on your PATH.
- Override behaviour with environment variables:
  - `RUN_TASK_STRICT=1` – Fail instead of skipping when the target project directory is missing.
  - `HEALTHCHECK_STRICT=1` – Force healthcheck failures when prerequisites are absent.
  - `COMPOSE_UP_FLAGS` – Adjust Compose behaviour (e.g., `--build --detach --remove-orphans`).
  - `HEALTHCHECK_DB_SERVICE`, `HEALTHCHECK_DB_USER`, `HEALTHCHECK_DB_NAME` – Override the database service/name/user used by `task healthcheck`.

---

## 8. Repository Layout
- `.devcontainer/` – Devcontainer Dockerfile + configuration.
- `.github/workflows/ci.yml` – Continuous integration pipeline.
- `.env.template`, `.env.local.template` – Root environment configuration templates.
- `Taskfile.yml` – Task runner definition for all workflows.
- `scripts/` – Bootstrap, healthcheck, task wrappers, shared utilities.
- `templates/` – Example configuration templates copied into the target project (Jarvis samples provided by default).

---

## 9. Original Proposal (Archived)
The initial proposal, timeline, and scope discussion are preserved below for reference.

- **Overview:** Build a reproducible developer platform for Jarvis with devcontainer, automation, and documentation.
- **Planned Components:** Devcontainer, task orchestration, pre-commit automation, CI pipeline, secrets management, and onboarding docs.
- **Anticipated Challenges:** Balancing devcontainer weight vs. parity; keeping automation DRY across tasks, hooks, and CI.
- **Implementation Timeline:** 11/06 – 12/01 milestones covering environment setup, automation wiring, CI integration, and polish.
- **Cloud Usage:** Entirely local tooling; CI runs on GitHub-hosted runners without external cloud resources.

---

## 10. Next Steps & Extension Ideas
- Add optional Vault/SOPS integration under `infra/secrets/` for automated secret rotation.
- Publish a base devcontainer image to GHCR and reference it in `.devcontainer/devcontainer.json` to speed up onboarding.
- Extend CI with Docker image builds and `docker compose` smoke tests using GitHub service containers.
- Integrate Renovate or Dependabot to keep uv and npm dependencies current.
