## ADDED Requirements

### Requirement: Absolute Paths for Tool References Inside Container
All shell scripts that run inside the container (`/tools/`) MUST use absolute paths
when referencing other files or scripts in `/tools/`. Relative paths MUST NOT be used
because the working directory at container runtime is `/` (not `/tools/`).

#### Scenario: version.remote.sh uses absolute path for url.releases.txt
- **WHEN** `grep 'url.releases.txt' tools/version.remote.sh` is run
- **THEN** the result contains `/tools/url.releases.txt` (absolute)
- **AND** the result does NOT contain `tools/url.releases.txt` without a leading `/`

#### Scenario: version.remote.sh executes correctly from any working directory
- **GIVEN** a running container with the image built from this repo
- **WHEN** `docker exec <id> bash -c "cd / && /tools/version.remote.sh"` is run
- **THEN** the command exits 0 and prints a semver string (e.g., `1.3.4`)

### Requirement: System Package Updates at Build Time Only
System package upgrades (`apt-get upgrade`, `apt-get dist-upgrade`) MUST be performed
during the Docker `build` phase, not during container startup. Container startup MUST
be deterministic and fast.

#### Scenario: start.sh does not call update-dist.sh
- **WHEN** `grep 'update-dist' tools/start.sh` is run
- **THEN** the output is empty

#### Scenario: Dockerfile calls update-dist.sh during build
- **WHEN** `grep 'update-dist' Dockerfile` is run
- **THEN** the output contains a `RUN /tools/update-dist.sh` line

#### Scenario: Container restarts in under 10 seconds (excluding Idena binary download)
- **GIVEN** an already-built and previously started container
- **WHEN** the container is stopped and restarted
- **THEN** the SSH service is available within 15 seconds
- **AND** no `apt-get` commands are logged in the container output during restart

### Requirement: Quick Test Does Not Rebuild When Image is Pre-Supplied
When `quick_test.sh` is invoked with the `--image_name` flag, it MUST use the
provided image directly and MUST NOT call `docker build`.

#### Scenario: --image_name flag skips build
- **WHEN** `./quick_test.sh --image_name idena-node:latest` is run
- **THEN** no `docker build` command is executed during the test run
- **AND** the script proceeds directly to `docker run`

#### Scenario: No --image_name flag triggers build
- **WHEN** `./quick_test.sh` is run without any arguments
- **THEN** `docker build .` is called before `docker run`
