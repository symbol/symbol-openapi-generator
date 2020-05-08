#!/bin/bash
set -e

PATCHFILE="$1"
ORIG_FILE="$2"
echo "ORIG_FILE=$ORIG_FILE"
echo "PATCHFILE=$PATCHFILE"

# The single quotes in some of the example values break the openapi generated unit tests.
# TODO Ideally fixed in openapi-generator for python.

# The following script encloses those values with double quotes but still breaks the openapi generated unit tests.
# For example:
#   1'000 becomes "1'000"
#   0x621E'C5B4'0385'6FC2 becomes "0x621E'C5B4'0385'6FC2"
#SED_ARGS_EXAMPLE_PATCH_1=/\"/!s/0x621E\'C5B4\'0385\'6FC2/\"0x621E\'C5B4\'0385\'6FC2\"/g
#SED_ARGS_EXAMPLE_PATCH_2=/\"/!s/0x4291\'ED23\'000A\'037A/\"0x4291\'ED23\'000A\'037A\"/g
#SED_ARGS_EXAMPLE_PATCH_3=/\"/!s/9\'000\'000\'000\'000\'000/\"9\'000\'000\'000\'000\'000\"/g
#SED_ARGS_EXAMPLE_PATCH_4=/\"/!s/8\'998\'999\'998\'000\'000/\"8\'998\'999\'998\'000\'000\"/g
#SED_ARGS_EXAMPLE_PATCH_5=/\"/!s/15\'000\'000/\"15\'000\'000\"/g
#SED_ARGS_EXAMPLE_PATCH_6=/\"/!s/10\'000\'000/\"10\'000\'000\"/g
#SED_ARGS_EXAMPLE_PATCH_7=/\"/!s/4\'000\'000/\"4\'000\'000\"/g
#SED_ARGS_EXAMPLE_PATCH_8=/\"/!s/200\'000/\"200\'000\"/g
#SED_ARGS_EXAMPLE_PATCH_9=/\"/!s/10\'000/\"10\'000\"/g
#SED_ARGS_EXAMPLE_PATCH_10=/\"/!s/1\'000/\"1\'000\"/g

# The following workaround removes those single quotes and does not break the openapi generated unit tests.
# For example:
#   1'000 is replaced with 1000
#   0x621E'C5B4'0385'6FC2 is replaced with 0x621EC5B403856FC2
SED_ARGS_EXAMPLE_PATCH_1=/example/s/8\'998\'999\'998\'000\'000/8998999998000000/g
SED_ARGS_EXAMPLE_PATCH_2=/example/s/0x621E\'C5B4\'0385\'6FC2/0x621EC5B403856FC2/g
SED_ARGS_EXAMPLE_PATCH_3=/example/s/0x4291\'ED23\'000A\'037A/0x4291ED23000A037A/g
SED_ARGS_EXAMPLE_PATCH_4=/example/s/\'000/000/g

lines=$(grep -e "\bexample\b: [0-9']\+'000$"\
    -e "\bexample\b: 0x621E'[[:alnum:]]\+"\
    -e "\bexample\b: 0x4291'[[:alnum:]]\+" "$PATCHFILE")

echo "Lines to fix:"
echo "$lines"

case $(uname | tr '[:upper:]' '[:lower:]') in
  linux*)
    echo "Fix invalid strings using sed on Linux"
    sed -i "$SED_ARGS_EXAMPLE_PATCH_1" "$PATCHFILE"
    sed -i "$SED_ARGS_EXAMPLE_PATCH_2" "$PATCHFILE"
    sed -i "$SED_ARGS_EXAMPLE_PATCH_3" "$PATCHFILE"
    sed -i "$SED_ARGS_EXAMPLE_PATCH_4" "$PATCHFILE"
#    sed -i "$SED_ARGS_EXAMPLE_PATCH_5" "$PATCHFILE"
#    sed -i "$SED_ARGS_EXAMPLE_PATCH_6" "$PATCHFILE"
#    sed -i "$SED_ARGS_EXAMPLE_PATCH_7" "$PATCHFILE"
#    sed -i "$SED_ARGS_EXAMPLE_PATCH_8" "$PATCHFILE"
#    sed -i "$SED_ARGS_EXAMPLE_PATCH_9" "$PATCHFILE"
#    sed -i "$SED_ARGS_EXAMPLE_PATCH_10" "$PATCHFILE"
    ;;
  darwin*)
    echo "Fix invalid strings using sed on OSX"
    sed -i '' -e "$SED_ARGS_EXAMPLE_PATCH_1" "$PATCHFILE"
    sed -i '' -e "$SED_ARGS_EXAMPLE_PATCH_2" "$PATCHFILE"
    sed -i '' -e "$SED_ARGS_EXAMPLE_PATCH_3" "$PATCHFILE"
    sed -i '' -e "$SED_ARGS_EXAMPLE_PATCH_4" "$PATCHFILE"
#    sed -i '' -e "$SED_ARGS_EXAMPLE_PATCH_5" "$PATCHFILE"
#    sed -i '' -e "$SED_ARGS_EXAMPLE_PATCH_6" "$PATCHFILE"
#    sed -i '' -e "$SED_ARGS_EXAMPLE_PATCH_7" "$PATCHFILE"
#    sed -i '' -e "$SED_ARGS_EXAMPLE_PATCH_8" "$PATCHFILE"
#    sed -i '' -e "$SED_ARGS_EXAMPLE_PATCH_9" "$PATCHFILE"
#    sed -i '' -e "$SED_ARGS_EXAMPLE_PATCH_10" "$PATCHFILE"
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
diff "$ORIG_FILE" "$PATCHFILE"
set +e
exit 0