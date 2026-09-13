#!/bin/bash
#
# Merge architecture-specific tags into multi-arch manifest lists.
#
# Reads every file under the directory given as $1 -- the downloaded
# pushed-tags-<arch> artifacts -- each holding one fully qualified tag per line:
#
#     iboates/osm2pgsql:2.3.1-amd64
#     iboates/osm2pgsql:latest-amd64
#
# Tags are grouped by target tag (the tag with a trailing -amd64 / -arm64
# removed) and merged with `docker buildx imagetools create`, which writes only
# the index -- no layers are moved.
#
# A target with just one architecture is still published, as a single-arch
# manifest. That is deliberate: a version that fails to build on one
# architecture ends up exactly where it is today rather than losing its tag.

set -uo pipefail

ARTIFACT_DIR="${1:?usage: merge_manifests.sh <artifact-dir>}"

if [ ! -d "$ARTIFACT_DIR" ]; then
  echo "No artifact directory '$ARTIFACT_DIR'; nothing to merge."
  exit 0
fi

ALL_TAGS=$(find "$ARTIFACT_DIR" -type f -exec cat {} + 2>/dev/null \
           | sed '/^[[:space:]]*$/d' | sort -u)

if [ -z "$ALL_TAGS" ]; then
  echo "No pushed tags were recorded; nothing to merge."
  exit 0
fi

TARGETS=$(echo "$ALL_TAGS" | sed -E 's/-(amd64|arm64)$//' | sort -u)

FAILED=""

for TARGET in $TARGETS; do

  SOURCES=""
  for ARCH in amd64 arm64; do
    if echo "$ALL_TAGS" | grep -qx -- "$TARGET-$ARCH"; then
      SOURCES="$SOURCES $TARGET-$ARCH"
    fi
  done

  if [ -z "$SOURCES" ]; then
    continue
  fi

  echo "Merging ->$SOURCES into $TARGET"

  if docker buildx imagetools create -t "$TARGET" $SOURCES; then
    echo -e "$TARGET: \033[32mMERGED\033[0m"
  else
    echo -e "$TARGET: \033[31mMERGE FAILED\033[0m"
    FAILED="$FAILED $TARGET"
  fi

done

if [ -n "$FAILED" ]; then
  echo "Failed to merge:$FAILED"
  exit 1
fi
