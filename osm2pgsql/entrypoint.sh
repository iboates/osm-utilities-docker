#!/bin/sh

# Set the download directory (default: /tmp)
DOWNLOAD_DIR=${PBF_DOWNLOAD_DIR:-/tmp}

# Initialize LAST_ARG
LAST_ARG=""
DELETE_FILE=""
for arg; do
  LAST_ARG=$arg
done

# Check if the last argument starts with "http"
case "$LAST_ARG" in
  http://*|https://*)
    FILENAME=$(basename "$LAST_ARG")
    FILE_PATH="$DOWNLOAD_DIR/$FILENAME"

    curl -o "$FILE_PATH" "$LAST_ARG"

    # Mark the file for deletion later
    DELETE_FILE="$FILE_PATH"

    # Rebuild the argument list, replacing the last argument with the file path
    ARGS=""
    for arg in "$@"; do
      if [ "$arg" = "$LAST_ARG" ]; then
        ARGS="$ARGS $FILE_PATH"
      else
        ARGS="$ARGS $arg"
      fi
    done
    # Update positional parameters
    set -- $ARGS
    ;;
esac

# Function to clean up the downloaded file if marked for deletion
cleanup() {
  if [ -n "$DELETE_FILE" ]; then
    rm -f "$DELETE_FILE"
  fi
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
  *)
    osm2pgsql "$@"
    ;;
esac
