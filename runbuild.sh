#!/bin/bash -e

# Try to clean up old images, but don't care if we fail
OLD_IMGS=$(docker images | grep -E '^lambci-ecs-.+(week|month|year)s? ago' | awk '{print $3}')
[ -z "$OLD_IMGS" ] || docker rmi $OLD_IMGS 2>/dev/null || true

set -x

# Build the repo's Dockerfile.test
docker build --pull -f "$LAMBCI_DOCKER_FILE" -t $LAMBCI_DOCKER_TAG $LAMBCI_DOCKER_BUILD_ARGS .

set +x

# Pass a filtered list of env vars through to docker run
# TODO: Does it even make sense to have this feature?
ENV_ARGS=$(node ${SCRIPT_DIR}/filterEnv "$LAMBCI_DOCKER_FILE" | awk '{print "-e "$1}')

set -x

docker run --rm $ENV_ARGS $LAMBCI_DOCKER_RUN_ARGS $LAMBCI_DOCKER_TAG

# We don't want to remove the docker image right away because we want to keep the cached layers
