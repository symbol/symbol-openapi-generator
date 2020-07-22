#!/bin/bash
set -e

if [ "$1" == "-h" ]; then
  echo "Usage: $(basename $0) [library] [operation]"
  echo "[library] is required: Possible values: "
  echo "   * all: it generates all java and javascripts options"
  echo "   * java: it generates all the java options"
  echo "   * jersey2: it generates jersey2 java version"
  echo "   * vertx: it generates vertx java version"
  echo "   * okhttp-gson: it generates okhttp-gson java version"
  echo "   * typescript: it generates typescript-node and typescript-fetch version"
  echo "   * typescript-node: it generates typescript-node javascript version"
  echo "   * typescript-fetch: it generates typescript-fetch javascript version"
  echo "   * python: it generates python version"
  echo "[operation] is optional. Possible values: "
  echo "   * no value | unknown value: It generates and builds the libraries."
  echo "   * publish | main: It generates, builds, and publish the libraries and documentation to npm, pypi, maven repos and/or github pages. "
  echo "   * release: It generates, builds, and publish the libraries and documentation to npm, pypi, maven repos and/or github pages updating the version to a release."
  exit 0
fi
LIBRARY_ARG="$1"
OPERATION_ARG="$2"

arg1Values=['all','java','jersey2','vertx','okhttp-gson','typescript','typescript-node','typescript-fetch','python']

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
INPUT_PATCHED="openapi3-any-of-patch.yml"
INPUT="openapi3.yml"
BUILD_DIR="./build"

echo "Operation: $OPERATION_ARG"

if [[ $OPERATION_ARG == "main" ]]; then
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
  echo "Build Java running operation $OPERATION"
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
    -t "java-templates/" \
    -i "$INPUT_PATCHED" \
    --additional-properties="apiPackage=io.nem.symbol.sdk.openapi.$LIBRARY.api" \
    --additional-properties="invokerPackage=io.nem.symbol.sdk.openapi.$LIBRARY.invoker" \
    --additional-properties="modelPackage=io.nem.symbol.sdk.openapi.$LIBRARY.model" \
    --additional-properties=library="$LIBRARY" \
    --additional-properties=groupId="io.nem" \
    --additional-properties="artifactId=$ARTIFACT_ID" \
    --additional-properties=artifactVersion="$FULL_VERSION" \
    --additional-properties=dateLibrary=java8 \
    --additional-properties=java8=true \
    --type-mappings=x-number-string=java.math.BigInteger \
    --type-mappings=Timestamp=java.math.BigInteger

  buildJava $OPERATION
  return 0
}

generateTypescript() {
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
    --additional-properties="legacyDiscriminatorBehavior=false" \
    --additional-properties="npmName=$ARTIFACT_ID" \
    --additional-properties=gitUserId=$GIT_USER_ID \
    --additional-properties=gitRepoId=$GIT_REPO_ID \
    --additional-properties="npmVersion=$VERSION" \
    --additional-properties="snapshot=$SNAPSHOT" \
    --additional-properties="useSingleRequestParameter=false" \
    --additional-properties="typescriptThreePlus=true" \
    --type-mappings=x-number-string=string
  cp "$LIBRARY-templates/.npmignore" "$BUILD_DIR/$ARTIFACT_ID"
  cp "$LIBRARY-templates/README.md" "$BUILD_DIR/$ARTIFACT_ID"
  sh -c "cd $BUILD_DIR/$ARTIFACT_ID && npm install"
  sh -c "cd $BUILD_DIR/$ARTIFACT_ID && npm run-script build"
  if [[ $OPERATION == "publish" ]]; then
    cp "$LIBRARY-templates/.npmrc" "$BUILD_DIR/$ARTIFACT_ID/.npmrc"
    sh -c "cd $BUILD_DIR/$ARTIFACT_ID && npm publish --tag snapshot"
  fi
  if [[ $OPERATION == "release" ]]; then
    cp "$LIBRARY-templates/.npmrc" "$BUILD_DIR/$ARTIFACT_ID/.npmrc"
    sh -c "cd $BUILD_DIR/$ARTIFACT_ID && npm publish"
  fi
  return 0
}

generatePython() {
  LIBRARY="$1"
  OPERATION="$2"
  ARTIFACT_ID="symbol-openapi-$LIBRARY-client"
  PACKAGE_NAME="symbol_openapi_client"
  LICENSE_INFO="Apache-2.0"
  INFO_NAME="nemtech"
  INFO_EMAIL="contact@nem.foundation"
  # Prerelease and snapshot must follow PEP 440 to upload to PyPI.
  PRERELEASE_VERSION="a1"
  SNAPSHOT_DATETIME=".$(date -u +'%Y%m%d.%H%M%S')"                        # UTC time for snapshots
  # Set the full package version
  PACKAGE_VERSION="${VERSION}${SNAPSHOT_DATETIME}${PRERELEASE_VERSION}"   # alpha publish version
  if [[ $OPERATION == "release" ]]; then
    PACKAGE_VERSION="${VERSION}"                                          # release version
  fi

  # Patch openapi yaml for python test generator
  PY_INPUT=$INPUT_PATCHED
  cp $INPUT $PY_INPUT
  echo "python_openapi3_patch.sh $PY_INPUT $INPUT"
  bash python_openapi3_patch.sh $PY_INPUT $INPUT
  echo "The command \"bash python_openapi3_patch.sh \$PY_INPUT \$INPUT\" exited with $?."

  # Generate the python openapi library
  echo "Generating $LIBRARY"
  rm -rf "$BUILD_DIR/$ARTIFACT_ID"
  openapi-generator generate -g "$LIBRARY" \
    -o "$BUILD_DIR/$ARTIFACT_ID" \
    -t "$LIBRARY-templates/" \
    -i "$PY_INPUT" \
    -p "projectName=$ARTIFACT_ID" \
    -p "packageName=$PACKAGE_NAME" \
    -p "packageVersion=$PACKAGE_VERSION" \
    --additional-properties="licenseInfo=$LICENSE_INFO" \
    --additional-properties="infoName=$INFO_NAME" \
    --additional-properties="infoEmail=$INFO_EMAIL" \
    --additional-properties="snapshot=$SNAPSHOT" \
    --type-mappings=x-number-string=int
  # Build, test, publish/release
  buildPython "$BUILD_DIR" "$ARTIFACT_ID" "$PACKAGE_VERSION" "$OPERATION"
  rm $PY_INPUT
  return 0
}

buildPython() {
  BUILD_DIR="$1"
  ARTIFACT_ID="$2"
  PACKAGE_VERSION="$3"
  OPERATION="$4"

  # Go to artifact build dir
  ORIGINAL_DIR="$(pwd)"  # we'll return to this directory after the build
  cd "$BUILD_DIR/$ARTIFACT_ID"
  echo "Build Python running operation '$OPERATION'"

  # Build
  echo "python3 setup.py sdist bdist_wheel build"
  PYTHONPATH=".:${PYTHONPATH}" python3 setup.py sdist bdist_wheel build

  # Patch openapi generated test files
#  TEST_DIR="$ORIGINAL_DIR/build/$ARTIFACT_ID/test"
#  echo "bash $ORIGINAL_DIR/python_test_files_patch.sh $TEST_DIR"
#  bash "$ORIGINAL_DIR/python_test_files_patch.sh" "$TEST_DIR"
#  echo "The command \"bash \$ORIGINAL_DIR/python_test_files_patch.sh \$TEST_DIR\" exited with $?."

  # Tests
#  Commented out pytest as the openapi generated test files have many errors that can't be easily patched.
#  echo "python3 -m pytest -v --color=yes --showlocals --maxfail=100"
#  PYTHONPATH=".:${PYTHONPATH}" python3 -m pytest -v --color=yes --showlocals --maxfail=100

  # Publish/Release
  UPLOAD=false   # default to disable upload to artifact repo
  if [[ $OPERATION == "publish" ]]|| [[ $OPERATION == "release" ]]; then
    UPLOAD=true
    REPO="pypi"
    echo "Enabled upload to $REPO"
  fi
  if [[ $OPERATION == "test" ]] || { [[ -n ${TEST_PYPI_USER} ]] && [[ -n ${TEST_PYPI_PASS} ]]; }; then
    UPLOAD=true
    REPO="testpypi"
    REPO_URL="https://test.pypi.org/legacy/"
    echo "Enabled upload to $REPO url $REPO_URL"
  fi

  if [[ $UPLOAD == true ]]; then
    # Log intention
    if [[ $OPERATION == "release" ]]; then
      echo "Releasing python artifact[$ARTIFACT_ID $PACKAGE_VERSION] to $REPO"
    else
      echo "Publishing python artifact[$ARTIFACT_ID $PACKAGE_VERSION] to $REPO"
    fi
    # Upload
    if [[ $REPO == "pypi" ]]; then
      if [[ -n ${PYPI_USER} ]] && [[ -n ${PYPI_PASS} ]]; then
        echo "PYPI_USER and PYPI_PASS already set: Uploading to PyPI"
        PYTHONPATH=".:${PYTHONPATH}" python3 -m twine upload -u "$PYPI_USER" -p "$PYPI_PASS" dist/*
      else
        echo "PYPI_USER and/or PYPI_PASS not set: Cancelled upload to PyPI"
      fi
    else
      if [[ -n ${TEST_PYPI_USER} ]] && [[ -n ${TEST_PYPI_PASS} ]]; then
        echo "TEST_PYPI_USER and TEST_PYPI_PASS already set: Uploading to Test PyPI"
        PYTHONPATH=".:${PYTHONPATH}" python3 -m twine upload --repository-url "$REPO_URL" -u "$TEST_PYPI_USER" -p "$TEST_PYPI_PASS" dist/*
      elif [[ $OPERATION == "test" ]]; then
        echo "OPERATION=test -> Initiate manual upload"
        PYTHONPATH=".:${PYTHONPATH}" python3 -m twine upload --repository "$REPO" dist/*
      fi
    fi
  else
    echo "REPO=${REPO:-N/A} ARTIFACT_ID=$ARTIFACT_ID PACKAGE_VERSION=$PACKAGE_VERSION"
  fi

  cd "$ORIGINAL_DIR"  # return to original directory
}

if [[ $LIBRARY_ARG == "all" ]]; then
  echo "Generating $LIBRARY_ARG and running operation $OPERATION_ARG"
  generateJava "jersey2" "build"
  generateJava "vertx" "build"
  generateJava "okhttp-gson" "build"
  buildJava "$OPERATION_ARG"
  generateTypescript "typescript-node" "$OPERATION_ARG"
  generateTypescript "typescript-fetch" "$OPERATION_ARG"
  generatePython "python" "$OPERATION_ARG"
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

if [[ $LIBRARY_ARG == "typescript" ]]; then
  echo "Generating $LIBRARY_ARG and running operation $OPERATION_ARG"
  generateTypescript "typescript-node" "$OPERATION_ARG"
  generateTypescript "typescript-fetch" "$OPERATION_ARG"

fi

if [[ $LIBRARY_ARG == "typescript-node" ]]; then
  generateTypescript "$LIBRARY_ARG" "$OPERATION_ARG"
fi

if [[ $LIBRARY_ARG == "typescript-fetch" ]]; then
  generateTypescript "$LIBRARY_ARG" "$OPERATION_ARG"
fi

if [[ $LIBRARY_ARG == "python" ]]; then
  generatePython "$LIBRARY_ARG" "$OPERATION_ARG"
fi
