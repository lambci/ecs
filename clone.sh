#!/bin/bash -e

CLONE_URL="https://${GITHUB_TOKEN}@github.com/${LAMBCI_CLONE_REPO}.git"

rm -rf "$CLONE_DIR"

git clone --depth 5 "$CLONE_URL" -b "$LAMBCI_CHECKOUT_BRANCH" "$CLONE_DIR"

# Echo a "safe" version of the command
echo "+ git clone --depth 5 ${CLONE_URL/$GITHUB_TOKEN/XXXX} -b $LAMBCI_CHECKOUT_BRANCH $CLONE_DIR"

set -x

cd "$CLONE_DIR"

git checkout -qf $LAMBCI_COMMIT

