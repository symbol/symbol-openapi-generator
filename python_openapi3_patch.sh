#!/bin/bash
set -e

PATCHFILE="$1"
ORIG_FILE="$2"
echo "ORIG_FILE=$ORIG_FILE"
echo "PATCHFILE=$PATCHFILE"

# The single quotes in some of the example values break the openapi generated unit tests.
# TODO Ideally fixed in openapi-generator for python.

SED_PATCH_NUMBERS=/example:.[0-9].*\'/s/\'/_/g


lines=$(grep -e "\bexample\b: [0-9].*'" "$PATCHFILE")

echo "Lines to fix:"
echo "$lines"

case $(uname | tr '[:upper:]' '[:lower:]') in
  linux*)
    echo "Fix invalid strings using sed on Linux"

    ;;
  darwin*)
    echo "Fix invalid strings using sed on OSX"
    sed -i '' -e "${SED_PATCH_NUMBERS}" "$PATCHFILE"
    ;;
  msys*)
    echo "This patch script does not run on Windows"
    ;;
  *)
    echo "This patch script does not run on $(uname)"
    ;;
esac

echo "diff $ORIG_FILE $PATCHFILE"
set +e
diff -U0 "$ORIG_FILE" "$PATCHFILE"
set +e
exit 0