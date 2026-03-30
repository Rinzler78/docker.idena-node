# Contributing

## Prerequisites

- Docker 20+
- Docker Compose plugin (`docker compose`)
- `sshpass` for the integration test

## Local build

```sh
docker build -t idena-node .
```

## Running tests

```sh
./scripts/test-dockerfile.sh
```

Convenience wrappers are also available:

```sh
./scripts/build-dockerfile.sh
./scripts/build-compose.sh
./scripts/run-dockerfile.sh
./scripts/run-compose.sh
./scripts/test-dockerfile.sh
./scripts/test-compose.sh
```

The default Compose setup uses the named Docker volume `idena-node-data` for `/datadir`.
Set `IDENA_USER_ACCOUNT_PASS` in your shell or `.env` file before running `docker compose up`.

To test a pre-built image without rebuilding it:

```sh
./scripts/test-dockerfile.sh --image_name rinzlerfr/idena-node:quicktest
```

## Submitting a PR

1. Create a feature branch from `develop`.
2. Keep changes focused and documented.
3. Run the local test suite before opening the PR.
4. Use a conventional commit message.

## Code style

- Use `set -euo pipefail` in shell scripts.
- Keep logging timestamped and concise.
- Prefer absolute `/tools/...` paths inside the container.
