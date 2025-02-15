# if this session isn't interactive, then we don't want to allocate a
# TTY, which would fail, but if it is interactive, we do want to attach
# so that the user can send e.g. ^C through.

INTERACTIVE := `[ -t 0 ] && echo 1 || echo 0`
export DOCKER_FLAGS := if INTERACTIVE == "1" { env('DOCKER_FLAGS', "") + "-t" } else { env('DOCKER_FLAGS', "") }
export IMAGE := env('CONTAINER_IMAGE_TARGET', "standard")
export BUILD_DATE := env('BUILD_DATE', `date -u +'%Y-%m-%dT%H:%M:%SZ'`)
export BUILD_REVISION := env('BUILD_REVISION', `git rev-parse HEAD`)
export BUILD_VERSION := env('BUILD_VERSION', `git rev-parse HEAD`)
export DEFAULT_IMAGE_NAME := env('CONTAINER_IMAGE_NAME', "container-action-template")
export DEFAULT_CONTAINER_URL := env('CONTAINER_IMAGE_ID', "ghcr.io/ellenfieldn/container-action-template:latest")

# Show help
help:
    @just --list

# Initialize the local development environment for the project
init:
    npm install

# Build the container image
[group('Build, Run, Test')]
build $container_url=DEFAULT_CONTAINER_URL: _docker-build-check
    DOCKER_BUILDKIT=1 docker buildx build --load \
      --build-arg BUILD_DATE=${BUILD_DATE} \
      --build-arg BUILD_REVISION=${BUILD_REVISION} \
      --build-arg BUILD_VERSION=${BUILD_VERSION} \
      --target ${IMAGE} \
      -t ${container_url} .

# Run Docker build checks against the container image
_docker-build-check:
    DOCKER_BUILDKIT=1 docker buildx build --check \
    .

# Open an interactive shell in the container
[group('Build, Run, Test')]
run $container_url=DEFAULT_CONTAINER_URL:
    docker run ${DOCKER_FLAGS} \
      --interactive \
      --entrypoint /bin/bash \
      --rm \
      ${container_url}

alias fix-format := format
alias fmt := format

# Format all files in repository
[group('Code Quality')]
format:
    npm run format:write
    @just _format-just

# Check the format of all files in repository
[group('Code Quality')]
check-format:
    npm run format:check
    @just _check-format-just

# Check Just Syntax
_check-format-just:
    #!/usr/bin/env sh
    set -euxo pipefail

    find . -type f -name "*.just" | while read -r file; do
      echo "Checking syntax: $file"
      just --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt --check -f {{ justfile() }}

# Fix Just Syntax
_format-just:
    #!/usr/bin/env sh
    set -euxo pipefail

    find . -type f -name "*.just" | while read -r file; do
      echo "Fixing syntax: $file"
      just --unstable --fmt -f $file
    done
    echo "Fixing syntax: Justfile"
    just --unstable --fmt -f {{ justfile() }} || { exit 1; }

# Lint all files in repository
[group('Code Quality')]
lint:
    npm run lint
    docker run \
      -e DEFAULT_BRANCH=main \
      -e FILTER_REGEX_EXCLUDE=dist/**/* \
      -e LOG_LEVEL=INFO \
      -e RUN_LOCAL=true \
      -e VALIDATE_ALL_CODEBASE=true \
      -e VALIDATE_JAVASCRIPT_STANDARD=false \
      -e VALIDATE_JAVASCRIPT_ES=false \
      -e VALIDATE_JSCPD=false \
      -e VALIDATE_JSON=false \
      -e VALIDATE_TYPESCRIPT_ES=false \
      -e VALIDATE_TYPESCRIPT_STANDARD=false \
      -v ./:/tmp/lint \
      --rm \
      ghcr.io/super-linter/super-linter:latest

# Scan for vulnerabilities
[group('Code Quality')]
scan:
    npm audit

# Run the test suite
[group('Build, Run, Test')]
test: _validate-labels _docker-build-check _test-container

[group('Build, Run, Test')]
_test-container $container_url=DEFAULT_CONTAINER_URL:
    docker run \
      -e INPUT_MILLISECONDS=1000 \
      --rm \
      ${container_url}

# Validate container image labels
[group('Build, Run, Test')]
_validate-labels $container_url=DEFAULT_CONTAINER_URL: build
    @echo "Validating labels for: ${container_url}";
    @just _validate-label ${container_url} "org.opencontainers.image.created" "${BUILD_DATE}"
    @just _validate-label ${container_url} "org.opencontainers.image.revision" "${BUILD_REVISION}"
    @just _validate-label ${container_url} "org.opencontainers.image.version" "${BUILD_VERSION}"

_validate-label $container_url $label_key $expected_label:
    #!/usr/bin/env sh
    set -euxo pipefail

    ACTUAL_LABEL="$(docker inspect --format "{{{{ index .Config.Labels \"${label_key}\" }}" "${container_url}")"
    if [[ "${ACTUAL_LABEL}" != "${expected_label}" ]]; then
      echo "[ERROR] Invalid container image label: ${label_key}: ${ACTUAL_LABEL}. Expected: ${expected_label}"
      exit 1
    else
      echo "${label_key} is valid: ${ACTUAL_LABEL}. Expected: ${expected_label}"
    fi

[group('Util')]
get-build-date:
    @echo "${BUILD_DATE}" # Already set by default

[group('Util')]
get-build-revision:
    @echo "${BUILD_REVISION}" # Already set by default

[group('Util')]
get-build-version:
    @echo "${BUILD_VERSION}" # Already set by default
