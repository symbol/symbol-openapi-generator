SNAPSHOT_PREFIX=-SNAPSHOT
FULL_VERSION=$(head -n 1 version.txt)
VERSION="${FULL_VERSION%$SNAPSHOT_PREFIX}"
SNAPSHOT=false
case "$FULL_VERSION" in
*$SNAPSHOT_PREFIX*) SNAPSHOT=true ;;
*) echo SNAPSHOT=false ;;
esac


INPUT="openapi3.yml"
BUILD_DIR="./build"


# dtsgen -o build/symbol-openapi-server/symbol-rest.ts openapi3.yml
LIBRARY="nodejs-express-server"
ARTIFACT_ID="symbol-openapi-$LIBRARY"
openapi-generator generate -g $LIBRARY -i "$INPUT"  -o "$BUILD_DIR/$ARTIFACT_ID"
