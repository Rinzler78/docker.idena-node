## Context

The `docker.idena-node` repository is already public on GitHub but fails several open-source
quality gates. This design document records the technical decisions taken during the
`improve-publish-readiness` change where non-obvious trade-offs exist.

## Goals / Non-Goals

**Goals:**
- Fix all critical and moderate issues identified in the review
- Keep the public Docker interface (ports, volumes, env vars) backward-compatible
- Achieve a passing CI pipeline on the next tag push

**Non-Goals:**
- Multi-arch builds (out of scope; can be a follow-up `feat`)
- Automated security scanning with Trivy (out of scope)
- Pinning Ubuntu package versions (would require a separate `pin-dependencies` change)

## Decisions

### Decision 1: Move `update-dist.sh` to build time, not startup

**Problem:** `start.sh` calls `update-dist.sh` (full `apt-get dist-upgrade`) on every container
restart, making restarts slow (30–60 s) and non-deterministic.

**Decision:** Run `update-dist.sh` as a Dockerfile `RUN` step, immediately after the base
package install block. Remove the call from `start.sh`.

**Alternatives considered:**
- Keep at runtime, add a flag to disable — adds complexity for no clear benefit
- Remove `update-dist.sh` entirely — too aggressive; system security updates at build time are valuable

**Trade-off:** Containers built at different times may have different OS patch levels, but this
is the standard Docker practice (rebuild to get updates). The Idena binary itself still
auto-updates at startup via `update.sh`.

---

### Decision 2: Remove `ENV IDENA_USER_ACCOUNT_PASS` from Dockerfile

**Problem:** Storing the password in `ENV` bakes it into every image layer and makes it
readable via `docker inspect`.

**Decision:** Remove `ENV IDENA_USER_ACCOUNT_PASS=…` from the Dockerfile entirely.
`start.sh` already uses `${IDENA_USER_ACCOUNT_PASS:?…}` which correctly errors if the
variable is not set at runtime. Users supply it via `-e IDENA_USER_ACCOUNT_PASS=…` at
`docker run` time, as documented in the README.

**Note:** The ARG `IDENA_USER_ACCOUNT_PASS` used during the `update.sh` build step is
unaffected — ARGs do not persist into the final image ENV.

---

### Decision 3: HEALTHCHECK — SSH only

**Problem:** The current healthcheck checks both TCP port 22 (SSH) AND `curl http://localhost:9009/`.
The Idena API on port 9009 requires an `api.key` and does not return HTTP 200 on `/`.
This causes the container to report `unhealthy` even when running correctly.

**Decision:** Reduce the healthcheck to SSH-only:
```dockerfile
HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=12 \
  CMD bash -c '</dev/tcp/localhost/22'
```

**Alternatives considered:**
- Use `idena-node` CLI to query node status — not available without api.key
- Check for process existence (`pgrep idena-node`) — does not verify SSH is usable
- Keep dual check, accept false negatives — bad UX; the Dockerfile test depends on healthy status

---

### Decision 4: `scripts/test-dockerfile.sh` — skip build when `--image_name` provided

**Problem:** the Dockerfile test entry point always calls `docker_build()` regardless of whether `--image_name`
was explicitly provided. In CI, this means the image is built twice (once by the workflow,
once by the test script).

**Decision:** Add a `--skip-build` flag, and automatically set it when `--image_name` is
supplied via the flag (not the positional argument). The positional argument path retains the
build behavior for local use.

**Implementation:**
```bash
# When --image_name flag is used → skip build (image is pre-built)
# When positional arg is used → build (legacy local usage)
if [ -n "$image_name_from_flag" ]; then
    skip_build=true
fi
```

---

### Decision 5: Semver tag migration

The existing tags use 4-segment versioning (`v0.0.0.1` to `v0.0.0.7`). These are invalid
SemVer. The next release after this change will use `v1.0.0` to signal the first stable,
properly-versioned release. Existing tags are kept for backward compatibility (Docker Hub
image history).

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| Moving `update-dist.sh` to build time may cause CI builds to take longer | Acceptable; Docker layer cache reduces impact after first build |
| Users who rely on `ENV IDENA_USER_ACCOUNT_PASS` in their `Dockerfile FROM` stacks will break | Breaking change is intentional for security; documented in CHANGELOG |
| HEALTHCHECK change means Dockerfile test must not rely on API port being healthy | Already the case; the Dockerfile test only checks SSH and version scripts |

## Open Questions

- Should we add multi-arch builds (`linux/amd64` + `linux/arm64`) in this change or a follow-up?
  → **Deferred to follow-up** `feat/multi-arch-build`
- Should we add Trivy security scanning to CI?
  → **Deferred to follow-up** `feat/security-scan-ci`
