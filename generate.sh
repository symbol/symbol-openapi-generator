#!/usr/bin/env bash
set -e

if [ "$1" == "-h" ]; then
  echo "Usage: $(basename $0) [library] [operation]"
  echo "[library] is required: Possible values: "
  echo "   * all: it generates all java and javascripts options"
  echo "   * java: it generates all the java options"
  echo "   * jersey2: it generates jersey2 java version"
  echo "   * vertx: it generates vertx java version"
  echo "   * okhttp-gson: it generates okhttp-gson java version"
  echo "   * typescript-node: it generates typescript-node javascript version"
  echo "[operation] is optional. Possible values: "
  echo "   * no value | unknown value: It generates and builds the libraries."
  echo "   * publish | master: It generates, builds, and publish the libraries and documentation to npm, maven repos and/or github pages. "
  echo "   * release: It generates, builds, and publish the libraries and documentation to npm, maven repos and/or github pages updating the version to a release."
  exit 0
fi
LIBRARY_ARG="$1"
OPERATION_ARG="$2"

arg1Values=['all','java','jersey2','vertx','okhttp-gson','typescript-node']

if [[ " ${arg1Values[*]} " != *"$LIBRARY_ARG"* || "" == "$LIBRARY_ARG" ]]; then
  echo "Usage: $(basename $0) [library] [operation]"
  echo "Invalid library argument '$LIBRARY_ARG'. Possible values are ${arg1Values[*]} "
  exit 1
fi

SNAPSHOT_PREFIX=-SNAPSHOT
FULL_VERSION=$(head -n 1 version.txt)
VERSION="${FULL_VERSION%$SNAPSHOT_PREFIX}"
SNAPSHOT=false
case "$FULL_VERSION" in
*$SNAPSHOT_PREFIX*) SNAPSHOT=true ;;
*) echo SNAPSHOT=false ;;
esac

TRAVIS_REPO_SLUG="${TRAVIS_REPO_SLUG:-nemtech/symbol-openapi-generator}"

GIT_USER_ID="$(cut -d'/' -f1 <<<"$TRAVIS_REPO_SLUG")"
GIT_REPO_ID="$(cut -d'/' -f2 <<<"$TRAVIS_REPO_SLUG")"
INPUT="openapi3-any-of-patch.yml"
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
echo "Travis Repo Slug: $TRAVIS_REPO_SLUG"
echo "Git User ID: $GIT_USER_ID"
echo "Git Repo ID: $GIT_REPO_ID"
echo "Open Api generator version: $(openapi-generator version)"

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
    echo "./gradlew closeAndReleaseRepository"
    ./gradlew closeAndReleaseRepository
  fi
  if [[ $OPERATION == "publish" || $OPERATION == "release" ]]; then
    echo "./gradlew gitPublishPush"
    ./gradlew gitPublishPush
  fi
}

generateJava() {
  LIBRARY="$1"
  OPERATION="$2"
  ARTIFACT_ID="symbol-openapi-$LIBRARY-client"
  echo "Generating $LIBRARY"
  rm -rf "$BUILD_DIR/$ARTIFACT_ID"
  openapi-generator generate -g java \
    -o "$BUILD_DIR/$ARTIFACT_ID" \
    -i "$INPUT" \
    --additional-properties="apiPackage=io.nem.symbol.sdk.openapi.$LIBRARY.api" \
    --additional-properties="invokerPackage=io.nem.symbol.sdk.openapi.$LIBRARY.invoker" \
    --additional-properties="modelPackage=io.nem.symbol.sdk.openapi.$LIBRARY.model" \
    --additional-properties=library="$LIBRARY" \
    --additional-properties=groupId="io.nem" \
    --additional-properties="artifactId=$ARTIFACT_ID" \
    --additional-properties=artifactVersion="$FULL_VERSION" \
    --additional-properties=dateLibrary=java8 \
    --additional-properties=java8=true \
    --type-mappings=x-number-string=java.math.BigInteger
  buildJava $OPERATION
  return 0
}

generateJavascript() {
  LIBRARY="$1"
  OPERATION="$2"
  ARTIFACT_ID="symbol-openapi-$LIBRARY-client"
  echo "Generating $LIBRARY"
  rm -rf "$BUILD_DIR/$ARTIFACT_ID"
  openapi-generator generate -g "$LIBRARY" \
    -o "$BUILD_DIR/$ARTIFACT_ID" \
    -t "$LIBRARY-templates/" \
    -i "$INPUT" \
    --git-user-id "$GIT_USER_ID" \
    --git-repo-id "$GIT_REPO_ID" \
    --additional-properties="supportsES6=true" \
    --additional-properties="npmName=$ARTIFACT_ID" \
    --additional-properties=gitUserId=$GIT_USER_ID \
    --additional-properties=gitRepoId=$GIT_REPO_ID \
    --additional-properties="npmVersion=$VERSION" \
    --additional-properties="snapshot=$SNAPSHOT" \
    --type-mappings=x-number-string=string
  cp "$LIBRARY-templates/.npmignore" "$BUILD_DIR/$ARTIFACT_ID"
  cp "$LIBRARY-templates/README.md" "$BUILD_DIR/$ARTIFACT_ID"
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
  generateJava "jersey2" "build"
  generateJava "vertx" "build"
  generateJava "okhttp-gson" "build"
  buildJava "$OPERATION_ARG" "build"
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
