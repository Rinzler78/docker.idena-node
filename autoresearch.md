# Autoresearch: Reduce Docker Image Size

## Goal
Minimize the size of the `idena-node` Docker image by:
1. Optimizing the Dockerfile build layers
2. Experimenting with smaller base images

## Primary metric
**Image size in MB** — lower is better.

## Benchmark
```bash
docker build -t idena-node:bench . && docker image inspect idena-node:bench --format '{{.Size}}' | awk '{printf "%.1f\n", $1/1024/1024}'
```

## Constraints
- All existing tests must still pass (`scripts/test-dockerfile.sh`)
- The image must expose ports 22, 40405, 9009
- SSH server must work
- idena-node binary must be fetchable / runnable
- The runtime contract (assert_image_contract) must hold

## Ideas log
See autoresearch.ideas.md
