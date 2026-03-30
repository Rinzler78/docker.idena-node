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
./quick_test.sh
```

To test a pre-built image without rebuilding it:

```sh
./quick_test.sh --image_name rinzlerfr/idena-node:quicktest
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
