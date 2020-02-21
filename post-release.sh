#!/usr/bin/env bash
set -e

increment_version ()
{
  declare -a part=( ${1//\./ } )
  declare    new
  declare -i carry=1

  for (( CNTR=${#part[@]}-1; CNTR>=0; CNTR-=1 )); do
    len=${#part[CNTR]}
    new=$((part[CNTR]+carry))
    [ ${#new} -gt $len ] && carry=1 || carry=0
    [ $CNTR -gt 0 ] && part[CNTR]=${new: -len} || part[CNTR]=${new}
  done
  new="${part[*]}"
  echo -e "${new// /.}"
}

SNAPSHOT_PREFIX=-SNAPSHOT
FULL_VERSION=$(head -n 1 version.txt)
VERSION="${FULL_VERSION%$SNAPSHOT_PREFIX}"
NEW_VERSION=$(increment_version "$VERSION")$SNAPSHOT_PREFIX

echo "Full Version: $FULL_VERSION"
echo "Version: $VERSION"
echo "New Version: $NEW_VERSION"

echo "Running post release git push"
REMOTE_NAME="origin"
RELEASE_BRANCH=release
POST_RELEASE_BRANCH=master

if [[ "${TRAVIS_REPO_SLUG}" ]]; then
  git remote rm $REMOTE_NAME
  echo "Setting remote url https://github.com/${TRAVIS_REPO_SLUG}.git"
  git remote add $REMOTE_NAME "https://${GRGIT_USER}@github.com/${TRAVIS_REPO_SLUG}.git" >/dev/null 2>&1
  echo "Checking out $RELEASE_BRANCH as travis leaves the head detached."
  git checkout $RELEASE_BRANCH
fi

echo "Current Version"
cat version.txt
echo ""

echo "Releasing version $VERSION"
echo "$VERSION" > 'version.txt'
git add version.txt
git commit -m "Releasing version $VERSION"

echo "Creating tag version v$VERSION"
git tag -fa "v$VERSION" -m "Releasing version $VERSION"

echo "Creating new version $NEW_VERSION"
echo "$NEW_VERSION" > 'version.txt'
git add version.txt
git commit -m "Creating new version $NEW_VERSION"

echo "Pushing code to $REMOTE_NAME $POST_RELEASE_BRANCH"
git push $REMOTE_NAME $RELEASE_BRANCH:$POST_RELEASE_BRANCH
echo "Pushing tags to $REMOTE_NAME"
git push --tags $REMOTE_NAME
