#!/bin/bash

. $(dirname $0)/common.sh

{ "$SCRIPT_DIR/clone.sh" && cd "$CLONE_DIR" && $LAMBCI_DOCKER_CMD; } 2>&1 | tee "$LOG_FILE"

cleanup ${PIPESTATUS[0]}
