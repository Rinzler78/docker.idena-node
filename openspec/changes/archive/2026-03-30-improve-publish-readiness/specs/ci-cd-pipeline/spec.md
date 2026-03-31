## ADDED Requirements

### Requirement: CI Uses Current GitHub Actions Syntax
The workflow file `.github/workflows/docker-image.yml` MUST use the current,
non-deprecated syntax for all GitHub Actions features.

#### Scenario: set-output is not used
- **WHEN** the CI workflow runs on a tag push
- **THEN** no `::set-output` commands are present in any `run` step
- **AND** tag extraction uses `echo "tag_name=…" >> $GITHUB_OUTPUT`
- **AND** the extracted tag is correctly referenced via `${{ steps.extract_tag.outputs.tag_name }}`

#### Scenario: CI completes without deprecation warnings
- **WHEN** a `v*` tag is pushed to the repository
- **THEN** the GitHub Actions workflow run produces zero deprecation warnings
- **AND** all steps complete with green status

### Requirement: CI Uses Up-to-Date Action Versions
All GitHub Actions referenced in `.github/workflows/docker-image.yml` MUST use
version tags that are current and not end-of-life.

#### Scenario: checkout action is v4
- **WHEN** the CI workflow is parsed
- **THEN** `actions/checkout` is pinned to `@v4` or later
- **AND** no `@v1`, `@v2`, or `@v3` references exist

#### Scenario: release action is v2
- **WHEN** the CI workflow is parsed
- **THEN** `softprops/action-gh-release` is pinned to `@v2` or later

### Requirement: Quick Test Runs Once Per CI Pipeline
The CI pipeline MUST NOT build the Docker image more than once per workflow run.
`scripts/test-dockerfile.sh`, when invoked with `--image_name`, MUST use the pre-built image
without triggering a rebuild.

#### Scenario: Single build in CI
- **WHEN** the CI workflow runs
- **THEN** `docker build` is invoked exactly once (in the "docker build" step)
- **AND** the "Quick Test" step reuses the already-built image
- **AND** the total CI duration does not include a second build phase
