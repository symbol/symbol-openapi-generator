#!/bin/bash
set -e

SNAPSHOT_PREFIX=-SNAPSHOT
FULL_VERSION=$(head -n 1 version.txt)
VERSION="${FULL_VERSION%$SNAPSHOT_PREFIX}"

rm -f openapi3.yml
rm -f openapi3-any-of-patch.yml
wget "https://github.com/nemtech/symbol-openapi/releases/download/v$VERSION/openapi3.yml" -O openapi3.yml

OPEN_API_VERSION="$(yaml get openapi3.yml info.version)"

if [ "$OPEN_API_VERSION" != "$VERSION" ]; then
  echo "Download open api version $OPEN_API_VERSION doesn't not match current version $VERSION !!!!"
  exit 1
fi

echo "Open api version $OPEN_API_VERSION has been downloaded"
