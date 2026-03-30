## Why

A code review of `docker.idena-node` (public repo, v0.0.0.7) identified 4 critical issues
that prevent the repository from meeting open-source quality standards, plus 6 moderate and
8 minor issues. The critical issues include a missing LICENSE file, a deprecated GitHub Actions
output syntax that silently breaks the CI pipeline, a path bug in `version.remote.sh`, and
credentials stored in image ENV layers visible via `docker inspect`.

This change resolves all issues systematically before the repository is promoted as a
reference-quality public project.

## What Changes

### 🔴 Critical (correctness / legal)
- **ADDED** MIT `LICENSE` file — repository currently claims MIT in README/badge but has no file
- **FIXED** `version.remote.sh`: relative `tools/url.releases.txt` → absolute `/tools/url.releases.txt`
- **FIXED** CI workflow: deprecated `::set-output` → `$GITHUB_OUTPUT`
- **FIXED** CI workflow: `actions/checkout@v2` → `actions/checkout@v4`; `softprops/action-gh-release@v1` → `@v2`
- **REMOVED** `ENV IDENA_USER_ACCOUNT_PASS` from Dockerfile final layer (credential leak via `docker inspect`)

### 🟠 Moderate (quality / reliability)
- **REMOVED** diagnostic `RUN ls -l /tools …` from Dockerfile
- **MOVED** `update-dist.sh` from container runtime (`start.sh`) to Dockerfile `RUN` layer — prevents non-deterministic, slow container restarts
- **ADDED** `.dockerignore` to exclude `.git/`, `.github/`, `*.md` from build context
- **FIXED** `HEALTHCHECK`: removed unreliable `curl` to Idena API; check SSH-only (`/dev/tcp/localhost/22`)
- **FIXED** README: completed truncated paragraph at line 107
- **FIXED** `quick_test.sh`: skip `docker_build()` when `--image_name` flag is supplied (avoids double build in CI)

### 🟡 Minor (completeness)
- **ADDED** `CONTRIBUTING.md`
- **ADDED** `CHANGELOG.md` with historical entries from commit log
- **REMOVED** `htop` from Dockerfile (monitoring tool, not needed in the production image)
- **ADDED** `docker-compose.yml` example for easier onboarding

## Impact

- Affected specs: `license-compliance`, `ci-cd-pipeline`, `dockerfile-security`, `shell-scripts-quality`, `documentation`
- Affected files:
  - `LICENSE` (new)
  - `Dockerfile`
  - `.dockerignore` (new)
  - `.github/workflows/docker-image.yml`
  - `tools/version.remote.sh`
  - `tools/start.sh`
  - `tools/update-dist.sh`
  - `quick_test.sh`
  - `README.md`
  - `CONTRIBUTING.md` (new)
  - `CHANGELOG.md` (new)
  - `docker-compose.yml` (new)
- **No breaking changes** to the public Docker image interface or runtime behaviour
- Idena node auto-update still occurs at container restart (via `update.sh`)
- System package updates (`update-dist.sh`) move to image build time — containers become deterministic
