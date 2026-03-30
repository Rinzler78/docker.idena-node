## Purpose

`docker.idena-node` is a Docker image that packages the [Idena network node](https://idena.io/) for easy self-hosting. The container exposes SSH access so users can securely forward the Idena API port to their local desktop application, supports persistent data storage via Docker volumes, and auto-updates the `idena-node` binary on startup.

**Key Goals:**
- Zero-config deployment of an Idena node via `docker run`
- Secure SSH tunnel to expose the node API locally
- Automatic binary update from the official GitHub release feed
- Public Docker Hub image for amd64 and arm64 platforms
- Exemplary open-source quality: documented, tested, with passing CI

## Tech Stack

- **Docker / Dockerfile**: Ubuntu 22.04 base image
- **Bash (>= 4)**: All tooling scripts (`start.sh`, `update.sh`, `update-dist.sh`, `version.*.sh`, `quick_test.sh`)
- **GitHub Actions**: CI/CD — build, test, push to Docker Hub, create GitHub Release
- **Docker Hub**: Public image registry (`rinzlerfr/idena-node`)
- **sshpass**: Used in test suite to verify SSH connectivity
- **jq / curl / wget**: Used in update pipeline to query GitHub Releases API

## Project Conventions

### Code Style — Shell Scripts
- `set -euo pipefail` at the top of every script
- Logging via `log()` function: `log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }`
- Error traps: `trap 'log "An error occurred." >&2' ERR`
- Required-command checks at the top of each script
- Absolute paths for all tool references inside the container (`/tools/…`)
- Mask sensitive values (passwords) in log output

### Dockerfile Conventions
- Single-stage Ubuntu 22.04 base
- `ARG` for build-time parameters; credentials MUST NOT be stored in `ENV` in the final image
- `RUN` layers combined and cache-cleaned to minimise image size
- No debug/diagnostic `RUN` commands in production images
- `VOLUME ["/datadir"]` for persistence
- `HEALTHCHECK` must reliably return healthy for a running, correctly configured container

### CI/CD Conventions
- Workflow file: `.github/workflows/docker-image.yml`
- Trigger: tags matching `v*` (SemVer `vMAJOR.MINOR.PATCH`)
- Steps: checkout → build → quick_test → push → release
- Uses current action versions (`actions/checkout@v4`, `softprops/action-gh-release@v2`)
- Secrets: `DOCKER_USER`, `DOCKER_PASSWORD` from GitHub repository secrets
- Output variables written to `$GITHUB_OUTPUT` (not deprecated `::set-output`)

### Versioning
- SemVer 3-segment: `vMAJOR.MINOR.PATCH` (e.g. `v1.0.0`)
- Tags pushed from `master` branch only

### Testing Strategy
- `quick_test.sh` is the integration test: build image → run container → wait for healthy → verify version scripts → test SSH
- CI calls `quick_test.sh --image_name <tag>` after the build step; the script MUST NOT re-build when a pre-built image is provided via `--image_name`
- All exit codes mapped to named constants (10=build fail, 11=run fail, 14=unhealthy, 16=version fail, 17=ssh fail)

### Git Workflow
- Branches: `master` (stable), `develop` (integration), `feature/<name>`
- Conventional Commits: `feat|fix|docs|chore|ci|refactor`
- No direct push to `master`; merge via PR from `develop`

## Domain Context

Idena is a proof-of-personhood blockchain. Running a node allows participation in the identity validation ceremony. The node binary is distributed as a single Linux ELF binary from [idena-network/idena-go](https://github.com/idena-network/idena-go/releases). The container provides SSH access so the Idena desktop app can forward port 9009 (node API) over SSH to the user's local machine.

## Important Constraints

- The container runs SSH as root (service management) — do not add the SSH user to the sudo group
- `IDENA_USER_ACCOUNT_PASS` must be injected at `docker run` time via `-e`; it must never be baked into the image via `ENV` in the final layer
- The `api.key` file is user-sensitive data persisted in `/datadir` volume, never copied into the image
- The container runs for long periods (`RUN_TIMEOUT=86400s`); Idena binary updates happen at each restart

## External Dependencies

| Dependency | Purpose | URL |
|------------|---------|-----|
| `idena-network/idena-go` | Provides the `idena-node` binary via GitHub Releases | https://api.github.com/repos/idena-network/idena-go/releases/latest |
| Docker Hub (`rinzlerfr/idena-node`) | Public image registry | https://hub.docker.com/r/rinzlerfr/idena-node |
| Ubuntu 22.04 base | Container OS | docker.io/library/ubuntu:22.04 |
