## ADDED Requirements

### Requirement: Complete and Correct README
The `README.md` MUST be free of truncated sentences. Every section MUST be fully written
and grammatically complete in English.

#### Scenario: README contains no truncated paragraphs
- **WHEN** the README is reviewed for sentence completeness
- **THEN** every paragraph ends with a complete sentence
- **AND** there are no lines that end mid-thought with "…as the tunnel" or similar fragments

#### Scenario: Quick Start section references docker-compose.yml
- **WHEN** a user reads the Quick Start section
- **THEN** they are offered both the `docker run` command and a reference to `docker-compose.yml`

### Requirement: CONTRIBUTING.md is Present
A `CONTRIBUTING.md` file MUST exist at the repository root describing how to build,
test, and submit contributions.

#### Scenario: CONTRIBUTING.md contains build instructions
- **WHEN** a contributor opens `CONTRIBUTING.md`
- **THEN** they find clear instructions to: install prerequisites, run `docker build .`,
  run `./scripts/test-dockerfile.sh`, and submit a pull request against the `develop` branch

#### Scenario: CONTRIBUTING.md is linked from README
- **WHEN** a user reads the Contributing section of `README.md`
- **THEN** there is a hyperlink to `CONTRIBUTING.md`

### Requirement: CHANGELOG.md Follows Keep a Changelog Format
A `CHANGELOG.md` file MUST exist at the repository root and MUST follow the
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format with an `[Unreleased]`
section and entries for all prior tagged versions.

#### Scenario: CHANGELOG.md is present with all versions
- **WHEN** `cat CHANGELOG.md` is run
- **THEN** the file starts with `# Changelog`
- **AND** sections exist for `[Unreleased]`, `[0.0.0.7]` through `[0.0.0.1]` (or `[1.0.0]` for the first properly versioned release)

### Requirement: docker-compose.yml Example Provided
A `docker-compose.yml` file MUST exist at the repository root as a ready-to-use example
that reflects the same configuration as the Quick Start `docker run` command.

#### Scenario: docker-compose.yml is valid
- **WHEN** `docker compose config` is run at the project root
- **THEN** the command exits 0 and prints the resolved compose configuration
- **AND** the configuration references the `rinzlerfr/idena-node` image

#### Scenario: docker-compose.yml documents required environment variables
- **WHEN** a user opens `docker-compose.yml`
- **THEN** `IDENA_USER_ACCOUNT_NAME` and `IDENA_USER_ACCOUNT_PASS` are present as
  environment variable placeholders with a comment explaining they are required
