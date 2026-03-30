# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Added `LICENSE`, `CONTRIBUTING.md`, `.dockerignore`, and `docker-compose.yml`.

### Changed
- Moved distribution updates to image build time.
- Updated the CI workflow to current GitHub Actions conventions.
- Improved README guidance for SSH tunneling and Compose usage.

### Fixed
- Fixed `tools/version.remote.sh` to use the correct absolute path inside the container.
- Fixed `quick_test.sh` to skip rebuilding when `--image_name` is supplied.
- Fixed the Docker healthcheck to verify SSH availability reliably.

### Removed
- Removed the password from persisted Docker image environment variables.
- Removed the diagnostic Dockerfile layer and the `htop` package from the image.

## [v0.0.0.7]

### Changed
- Refined `quick_test.sh` image selection with the `--image_name` flag.
- Improved README formatting and API tunnel documentation.

## [v0.0.0.6]

### Added
- Expanded project badges and troubleshooting documentation.

### Changed
- Reworked `quick_test.sh` structure and parameter handling.
- Updated Dockerfile healthcheck and startup behavior.

## [v0.0.0.5]

### Changed
- Pushed the `latest` Docker tag after tagged image publication.
- Improved CI quick-test handling.

## [v0.0.0.4]

### Changed
- Hardened CI timeout handling for the quick test workflow.

## [v0.0.0.3]

### Changed
- Iterated on the Docker image CI workflow and test execution.

## [v0.0.0.2]

### Added
- Added `quick_test.sh`.

### Fixed
- Fixed version handling and download issues.

## [v0.0.0.1]

### Changed
- Initial tagged CI workflow for Docker image publishing.
