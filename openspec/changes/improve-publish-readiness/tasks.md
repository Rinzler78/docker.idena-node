## Phase 1 — Critical Fixes

- [x] 1.1 Add `LICENSE` file (MIT, year 2025, author Rinzler78)
  - **Validation:** `ls LICENSE` returns file; file contains "MIT License" and current year

- [x] 1.2 Fix `tools/version.remote.sh` — replace relative path with absolute
  - Change `cat tools/url.releases.txt` → `cat /tools/url.releases.txt`
  - **Validation:** `grep 'cat /tools/url.releases.txt' tools/version.remote.sh` returns 1 match

- [x] 1.3 Fix CI workflow — replace deprecated `::set-output` with `$GITHUB_OUTPUT`
  - File: `.github/workflows/docker-image.yml`
  - Replace: `echo ::set-output name=tag_name::…` → `echo "tag_name=…" >> $GITHUB_OUTPUT`
  - Replace references: `steps.extract_tag.outputs.tag_name` remains valid (no change needed)
  - **Validation:** `grep 'set-output' .github/workflows/docker-image.yml` returns empty

- [x] 1.4 Update CI action versions
  - `actions/checkout@v2` → `actions/checkout@v4`
  - `softprops/action-gh-release@v1` → `softprops/action-gh-release@v2`
  - **Validation:** `grep 'checkout@v' .github/workflows/docker-image.yml` shows `@v4`; `grep 'action-gh-release@' .github/workflows/docker-image.yml` shows `@v2`

- [x] 1.5 Remove `ENV IDENA_USER_ACCOUNT_PASS` from Dockerfile final layer
  - Delete the line: `ENV IDENA_USER_ACCOUNT_PASS=${IDENA_USER_ACCOUNT_PASS}`
  - Keep `ARG IDENA_USER_ACCOUNT_PASS=idenaClientPassword` (build-time only, not persisted)
  - **Validation:** `docker inspect <image> | jq '.[0].Config.Env'` does NOT contain `IDENA_USER_ACCOUNT_PASS`; `docker build .` succeeds; `docker run -e IDENA_USER_ACCOUNT_NAME=x -e IDENA_USER_ACCOUNT_PASS=y …` starts correctly

## Phase 2 — Moderate Fixes

- [x] 2.1 Remove diagnostic `RUN ls -l …` from Dockerfile
  - Delete line 50: `RUN ls -l /tools && ls -l /bin && echo "PATH=$PATH"`
  - **Validation:** `grep 'ls -l /tools' Dockerfile` returns empty

- [x] 2.2 Move `update-dist.sh` from runtime to build time
  - In `Dockerfile`: Add `RUN /tools/update-dist.sh` after the `COPY tools` + `chmod` block and before `RUN /tools/update.sh`
  - In `tools/start.sh`: Remove the line `/tools/update-dist.sh`
  - **Validation:** `grep 'update-dist' tools/start.sh` returns empty; `grep 'update-dist' Dockerfile` returns 1 match with `RUN`; `docker build .` succeeds

- [x] 2.3 Add `.dockerignore`
  - Create `.dockerignore` with at minimum: `.git`, `.github`, `*.md`, `openspec`, `LICENSE`
  - **Validation:** `cat .dockerignore` shows the listed patterns; `docker build .` produces a smaller build context (verify via `docker build --progress=plain 2>&1 | grep "Sending build context"`)

- [x] 2.4 Fix `HEALTHCHECK` in Dockerfile — SSH only
  - Replace current HEALTHCHECK with:
    ```dockerfile
    HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=12 \
      CMD bash -c '</dev/tcp/localhost/22'
    ```
  - **Validation:** `docker run …` container reaches `healthy` status within 60 s; `./quick_test.sh` exits 0

- [x] 2.5 Complete truncated README paragraph (line 107)
  - The sentence starting "...as the tunnel..." is cut off; complete the explanation
  - **Validation:** `grep -n 'as the tunnel' README.md` returns empty (sentence completed); README renders cleanly in GitHub preview

- [x] 2.6 Fix `quick_test.sh` — skip build when `--image_name` flag is provided
  - Add `skip_build=false` variable; set `skip_build=true` when `image_name_from_flag` is non-empty
  - Wrap `docker_build` call: `if [ "$skip_build" = false ]; then docker_build … fi`
  - **Validation:** `./quick_test.sh --image_name idena-node:latest` does NOT trigger `docker build`; `./quick_test.sh` (no flag) still builds; CI log shows single build step

## Phase 3 — Quality Improvements

- [x] 3.1 Add `CONTRIBUTING.md`
  - Sections: Prerequisites, Local build, Running tests, Submitting a PR, Code style
  - **Validation:** File exists, renders on GitHub, linked from README Contributing section

- [x] 3.2 Add `CHANGELOG.md`
  - Format: [Keep a Changelog](https://keepachangelog.com) with entries for v0.0.0.1–v0.0.0.7 reconstructed from git log, plus `[Unreleased]` section for this change
  - **Validation:** `cat CHANGELOG.md | head -5` shows `# Changelog`; all 7 prior versions listed

- [x] 3.3 Remove `htop` from Dockerfile
  - Delete `htop \` from the `apt-get install` block
  - **Validation:** `grep 'htop' Dockerfile` returns empty; `docker build .` succeeds; final image size is equal or smaller

- [x] 3.4 Add `docker-compose.yml` example
  - Covers the standard `docker run` parameters as a compose service
  - **Validation:** `docker compose config` in project dir validates without errors; compose file referenced in README Quick Start

## Phase 4 — Final Validation

- [x] 4.1 Run `docker build .` locally — must succeed with 0 errors and 0 warnings
  - **Validation:** Exit code 0; no `WARN` lines in output

- [x] 4.2 Run `./quick_test.sh` locally — must exit 0
  - **Validation:** Final line reads `[SUCCESS] All tests passed.`

- [x] 4.3 Verify `openspec validate improve-publish-readiness --strict` passes
  - **Validation:** Exit code 0, no validation errors

- [x] 4.4 Commit on `develop` with conventional commit message
  - Message: `fix: resolve critical issues and improve publish readiness`
  - **Validation:** `git log --oneline -1` shows the commit; `git status` is clean

- [ ] 4.5 Merge `develop` → `master` and push tag `v1.0.0`
  - **Validation:** GitHub Actions workflow triggers; all steps pass green; Docker Hub image tagged `v1.0.0` and `latest`; GitHub Release created
