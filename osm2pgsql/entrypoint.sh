#!/bin/sh

# Set the download directory (default: /tmp)
DOWNLOAD_DIR=${PBF_DOWNLOAD_DIR:-/tmp}

DELETE_FILES=""

# Function to clean up the downloaded files
cleanup() {
  for I in $DELETE_FILES ; do
    rm -f "$I"
  done
}

# Ensure cleanup is called on exit
trap cleanup EXIT

# URL arguments are downloaded and replaced with the local file path, but only
# when the command is osm2pgsql itself: its inputs must be local files. The
# helper tools (replication, gen, expire, test-style) take URLs as real values
# (e.g. osm2pgsql-replication --server URL), so their arguments pass through
# untouched.
case "$1" in
  osm2pgsql)
    DOWNLOAD_URLS=yes
    ;;
  osm2pgsql*|replication|generalization|gen|expire|test-style)
    DOWNLOAD_URLS=no
    ;;
  *)
    DOWNLOAD_URLS=yes
    ;;
esac

if [ "$DOWNLOAD_URLS" = yes ]; then
  # Rotate through the arguments, appending each (or its download path) to the
  # end of "$@". This keeps every argument intact, including ones that contain
  # spaces such as a conninfo string passed to -d.
  REMAINING=$#
  while [ "$REMAINING" -gt 0 ]; do
    arg=$1
    shift
    REMAINING=$((REMAINING - 1))
    case $arg in
      http://*|https://*)
        FILE_PATH="$DOWNLOAD_DIR/$(basename "$arg")"
        # Mark the file for deletion before downloading, so a partial file
        # left by a failed download is still cleaned up.
        DELETE_FILES="$DELETE_FILES $FILE_PATH"
        curl -fL -o "$FILE_PATH" "$arg" || exit 1
        set -- "$@" "$FILE_PATH"
        ;;
      *)
        set -- "$@" "$arg"
        ;;
    esac
  done
fi

# Check the first argument for multiple conditions and execute commands
case "$1" in
  osm2pgsql*)
    "$@"
    ;;
  replication)
    shift
    osm2pgsql-replication "$@"
    ;;
  osm2pgsql-replication)
    shift
    osm2pgsql-replication "$@"
    ;;
  osm2pgsql-gen)
    shift
    osm2pgsql-gen "$@"
    ;;
  osm2pgsql-generalization)
    shift
    osm2pgsql-gen "$@"
    ;;
  generalization)
    shift
    osm2pgsql-gen "$@"
    ;;
  gen)
    shift
    osm2pgsql-gen "$@"
    ;;
  osm2pgsql-expire)
    shift
    osm2pgsql-expire "$@"
    ;;
  expire)
    shift
    osm2pgsql-expire "$@"
    ;;
  osm2pgsql-test-style)
    shift
    osm2pgsql-test-style "$@"
    ;;
  test-style)
    shift
    osm2pgsql-test-style "$@"
    ;;
  *)
    osm2pgsql "$@"
    ;;
esac
