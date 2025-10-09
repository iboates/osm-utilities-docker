#!/bin/sh

# Set the download directory (default: /tmp)
DOWNLOAD_DIR=${PBF_DOWNLOAD_DIR:-/tmp}

POSITIONAL_ARGS=""
DELETE_FILES=""

for arg in "$@" ; do
    case $arg in
    http://*|https://*)
        FILENAME=$(basename "$arg")
        FILE_PATH="$DOWNLOAD_DIR/$FILENAME"

        curl -L -o "$FILE_PATH" "$arg"

        POSITIONAL_ARGS="$POSITIONAL_ARGS $FILE_PATH"
        # Mark the file for deletion later
        DELETE_FILES="$DELETE_FILES $FILE_PATH"
        shift
        ;;
    *)
        POSITIONAL_ARGS="$POSITIONAL_ARGS $arg"
        shift
        ;;
  esac
done

set -- $POSITIONAL_ARGS # restore positional parameters

# Function to clean up the downloaded file if marked for deletion
cleanup() {
  for I in $DELETE_FILES ; do
    rm -f "$I"
  done
}

# Ensure cleanup is called on exit
trap cleanup EXIT

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
  *)
    osm2pgsql "$@"
    ;;
esac
