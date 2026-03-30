## ADDED Requirements

### Requirement: No Credentials in Image ENV Layer
The Dockerfile MUST NOT persist `IDENA_USER_ACCOUNT_PASS` in any `ENV` instruction
that survives into the final image. Credentials MUST only be provided at container
runtime via the `-e` flag.

#### Scenario: docker inspect shows no password
- **WHEN** `docker inspect <image>` is run on a built image
- **THEN** the `Config.Env` array does NOT contain any entry starting with `IDENA_USER_ACCOUNT_PASS`
- **AND** the image still accepts `-e IDENA_USER_ACCOUNT_PASS=<value>` at `docker run` time

#### Scenario: start.sh enforces password at runtime
- **WHEN** `docker run` is called without `-e IDENA_USER_ACCOUNT_PASS`
- **THEN** `start.sh` exits with a non-zero code and the message `IDENA_USER_ACCOUNT_PASS is not set`
- **AND** the container does not start the SSH server or Idena node

### Requirement: No Debug Instructions in Production Dockerfile
The Dockerfile MUST NOT contain `RUN` instructions whose sole purpose is diagnostics
(e.g., `ls`, `echo PATH`) that produce no build artifact.

#### Scenario: Dockerfile contains no diagnostic RUN lines
- **WHEN** `grep -n 'ls -l' Dockerfile` is executed
- **THEN** the output is empty
- **AND** `docker build .` produces no extraneous stdout lines from ls or echo

### Requirement: Reliable Container Health Check
The `HEALTHCHECK` instruction MUST verify the SSH service is responsive.
It MUST NOT attempt to curl the Idena API port, which is not reliably accessible
without a valid `api.key`.

#### Scenario: Healthy container reports healthy within 60 seconds
- **WHEN** a container is started with valid credentials
- **THEN** `docker inspect --format='{{.State.Health.Status}}' <id>` returns `healthy` within 60 seconds
- **AND** the healthcheck interval is 5 seconds with 12 retries and a 10-second start period

#### Scenario: Unhealthy SSH reports unhealthy
- **WHEN** the SSH service inside the container is stopped
- **THEN** `docker inspect --format='{{.State.Health.Status}}' <id>` transitions to `unhealthy`

### Requirement: Minimal Production Image
The Docker image MUST NOT include packages that serve no purpose at container runtime.

#### Scenario: htop is not installed
- **WHEN** `docker run --rm <image> which htop` is executed
- **THEN** the command exits with a non-zero code (htop not found)
- **AND** the Dockerfile's `apt-get install` block does not list `htop`

### Requirement: Build Context Excludes Non-Essential Files
A `.dockerignore` file MUST be present and MUST exclude `.git/`, `.github/`,
documentation files, and the `openspec/` directory from the Docker build context.

#### Scenario: .dockerignore is present
- **WHEN** `cat .dockerignore` is run at the project root
- **THEN** the file exists and contains entries for `.git`, `.github`, `*.md`, and `openspec`

#### Scenario: Build context is smaller than without .dockerignore
- **WHEN** `docker build --progress=plain . 2>&1 | grep context` is run
- **THEN** the reported build context size is less than 100 KB
