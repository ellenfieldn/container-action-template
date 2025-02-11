# if this session isn't interactive, then we don't want to allocate a
# TTY, which would fail, but if it is interactive, we do want to attach
# so that the user can send e.g. ^C through.

INTERACTIVE := `[ -t 0 ] && echo 1 || echo 0`
export DOCKER_FLAGS := if INTERACTIVE == "1" { env('DOCKER_FLAGS', "") + "-t" } else { env('DOCKER_FLAGS', "") }
export IMAGE := env('CONTAINER_IMAGE_TARGET', "standard")
export BUILD_DATE := env('BUILD_DATE', `date -u +'%Y-%m-%dT%H:%M:%SZ'`)
export BUILD_REVISION := env('BUILD_REVISION', `git rev-parse HEAD`)
export BUILD_VERSION := env('BUILD_VERSION', `git rev-parse HEAD`)
export TEST_CONTAINER_URL := env('CONTAINER_IMAGE_ID', "ghcr.io/ellenfieldn/container-toolkit-action-nodist:latest")

# Show help
[group('Just')]
help:
    @just --list

# Check Just Syntax
[group('Just')]
check-just:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
      echo "Checking syntax: $file"
      just --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
fix-just:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
      echo "Checking syntax: $file"
      just --unstable --fmt -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt -f Justfile || { exit 1; }

# Build the container image
build: docker-build-check
    DOCKER_BUILDKIT=1 docker buildx build --load \
      --build-arg BUILD_DATE=${BUILD_DATE} \
      --build-arg BUILD_REVISION=${BUILD_REVISION} \
      --build-arg BUILD_VERSION=${BUILD_VERSION} \
      --target ${IMAGE} \
      -t ${TEST_CONTAINER_URL} .

# Run the test suite
test: validate-labels docker-build-check npm-audit test-container

alias fmt := format
# Format the codebase
format:
    npm run format:write

# Run linters
lint:
    npm run lint

# Run Docker build checks against the container image
docker-build-check:
    DOCKER_BUILDKIT=1 docker buildx build --check \
    .

# Open an interactive shell in the container
run:
    docker run ${DOCKER_FLAGS} \
      --interactive \
      --entrypoint /bin/bash \
      --rm \
      ${TEST_CONTAINER_URL}

test-container:
    docker run \
      -e INPUT_MILLISECONDS=1000 \
      --rm \
      ${TEST_CONTAINER_URL}

# Validate container image labels
validate-labels: build
    @echo "Validating labels for: ${TEST_CONTAINER_URL}";
    @just _validate-labels ${TEST_CONTAINER_URL} "org.opencontainers.image.created" "${BUILD_DATE}"
    @just _validate-labels ${TEST_CONTAINER_URL} "org.opencontainers.image.revision" "${BUILD_REVISION}"
    @just _validate-labels ${TEST_CONTAINER_URL} "org.opencontainers.image.version" "${BUILD_VERSION}"

_validate-labels $container_url $label_key $expected_label:
    #!/usr/bin/env sh
    ACTUAL_LABEL="$(docker inspect --format "{{{{ index .Config.Labels \"${label_key}\" }}" "${container_url}")"
    if [[ "${ACTUAL_LABEL}" != "${expected_label}" ]]; then
      echo "[ERROR] Invalid container image label: ${label_key}: ${ACTUAL_LABEL}. Expected: ${expected_label}"
      exit 1
    else
      echo "${label_key} is valid: ${ACTUAL_LABEL}. Expected: ${expected_label}"
    fi

get-build-date:
    @echo "${BUILD_DATE}" # Already set by default

get-build-revision:
    @echo "${BUILD_REVISION}" # Already set by default

get-build-version:
    @echo "${BUILD_VERSION}" # Already set by default

# Run npm audit to check for known vulnerable dependencies
npm-audit:
    npm audit
