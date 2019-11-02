#!/usr/bin/env bash
set -e
LIBRARY_ARG="$1"
OPERATION_ARG="$2"

SNAPSHOT_PREFIX=-SNAPSHOT
FULL_VERSION=$(head -n 1 version.txt)
VERSION="${FULL_VERSION%$SNAPSHOT_PREFIX}"
SNAPSHOT=false
case "$FULL_VERSION" in
*$SNAPSHOT_PREFIX*) SNAPSHOT=true ;;
*) echo SNAPSHOT=false ;;
esac

BUILD_DIR="./build"

echo "Operation: $OPERATION_ARG"

if [[ $OPERATION_ARG == "master" ]]; then
  OPERATION_ARG="publish"
fi

if [[ $OPERATION_ARG == "release" ]]; then
  SNAPSHOT=false
  FULL_VERSION="$VERSION"
  echo "$VERSION" >'version.txt'
fi

echo "Library: $LIBRARY_ARG"
echo "Operation: $OPERATION_ARG"
echo "Full Version: $FULL_VERSION"
echo "Version: $VERSION"
echo "Snapshot: $SNAPSHOT"

export JAVA_OPTS="-Dlog.level=error"

buildJava() {
  OPERATION="$1"
  echo "Build Java runnnig operation $OPERATION"
  echo "./gradlew install"
  ./gradlew install
  if [[ $OPERATION == "publish" || $OPERATION == "release" ]]; then
    echo "./gradlew publish"
    ./gradlew publish
  fi
  if [[ $OPERATION == "release" ]]; then
    echo "./gradlew closeRepository"
    ./gradlew closeRepository
  fi
  if [[ $OPERATION == "publish" || $OPERATION == "release" ]]; then
    echo "./gradlew gitPublishPush"
    ./gradlew gitPublishPush
  fi
}

generateJava() {
  LIBRARY="$1"
  OPERATION="$2"
  ARTIFACT_ID="api-$LIBRARY-client"
  echo "Generating $LIBRARY and running operation $OPERATION"
  rm -rf "$BUILD_DIR/$ARTIFACT_ID"
  openapi-generator generate -g java \
    -o "$BUILD_DIR/$ARTIFACT_ID" \
    -i openapi3-any-of-patch.yaml \
    -Dlog.level=error \
    --additional-properties="apiPackage=io.nem.sdk.openapi.$LIBRARY.api" \
    --additional-properties="invokerPackage=io.nem.sdk.openapi.$LIBRARY.invoker" \
    --additional-properties="modelPackage=io.nem.sdk.openapi.$LIBRARY.model" \
    --additional-properties=library="$LIBRARY" \
    --additional-properties=groupId="io.nem" \
    --additional-properties="artifactId=$ARTIFACT_ID" \
    --additional-properties=artifactVersion="$FULL_VERSION" \
    --type-mappings=x-number-string=java.math.BigInteger
  buildJava $OPERATION
  return 0
}

generateJavascript() {
  LIBRARY="$1"
  OPERATION="$2"
  ARTIFACT_ID="nem2-sdk-openapi-$LIBRARY-client"
  echo "Generating $LIBRARY and running operation $OPERATION"
  rm -rf "$BUILD_DIR/$ARTIFACT_ID"
  openapi-generator generate -g "$LIBRARY" \
    -o "$BUILD_DIR/$ARTIFACT_ID" \
    -t "$LIBRARY-templates/" \
    -i openapi3-any-of-patch.yaml \
    -Dlog.level=error \
    --additional-properties="npmName=$ARTIFACT_ID" \
    --additional-properties="gitUserId=NEMStudios" \
    --additional-properties="gitRepoId=nem2-open-api-generator" \
    --additional-properties="npmVersion=$VERSION" \
    --additional-properties="snapshot=$SNAPSHOT" \
    --type-mappings=x-number-string=string
  cp "$LIBRARY-templates/.npmignore" "$BUILD_DIR/$ARTIFACT_ID/.npmignore"
  sh -c "cd $BUILD_DIR/$ARTIFACT_ID && npm install"
  sh -c "cd $BUILD_DIR/$ARTIFACT_ID && npm run-script build"
  if [[ $OPERATION == "publish" || $OPERATION == "release" ]]; then
    cp "$LIBRARY-templates/.npmrc" "$BUILD_DIR/$ARTIFACT_ID/.npmrc"
    sh -c "cd $BUILD_DIR/$ARTIFACT_ID && npm publish"
  fi
  return 0
}

if [[ $LIBRARY_ARG == "all" ]]; then
  echo "Generating $LIBRARY_ARG and running operation $OPERATION_ARG"
  generateJava "jersey2"
  generateJava "vertx"
  generateJava "okhttp-gson"
  buildJava "$OPERATION_ARG"
  generateJavascript "typescript-node" "$OPERATION_ARG"
fi

if [[ $LIBRARY_ARG == "java" ]]; then
  echo "Generating $LIBRARY_ARG and running operation $OPERATION_ARG"
  generateJava "jersey2"
  generateJava "vertx"
  generateJava "okhttp-gson"
  buildJava "$OPERATION_ARG"
fi

if [[ $LIBRARY_ARG == "jersey2" ]]; then
  generateJava "$LIBRARY_ARG" "$OPERATION_ARG"
fi

if [[ $LIBRARY_ARG == "vertx" ]]; then
  generateJava "$LIBRARY_ARG" "$OPERATION_ARG"
fi

if [[ $LIBRARY_ARG == "okhttp-gson" ]]; then
  generateJava "$LIBRARY_ARG" "$OPERATION_ARG"
fi

if [[ $LIBRARY_ARG == "typescript-node" ]]; then
  generateJavascript "$LIBRARY_ARG" "$OPERATION_ARG"
fi

if [[ $OPERATION_ARG == "release" ]]; then
  bash ./release.sh
fi
