#!/bin/bash

force_dir() {
    # Traverse up until we find "osm-utilities-docker"
    while [[ "$PWD" != "/" && "$(basename "$PWD")" != "osm-utilities-docker" ]]; do
        cd ..
    done

    # Ensure we're in "osm-utilities-docker", then move into "osm2pgsql/scripts"
    if [[ "$(basename "$PWD")" == "osm-utilities-docker" ]]; then
        cd osm2pgsql/scripts || { echo "Error: scripts directory not found"; exit 1; }
    else
        echo "Error: Not inside osm-utilities-docker or its subdirectories"
        exit 1
    fi

    # Now move up one directory to put us into "osm2qpgsql-utilities-docker/osm2pgsql"
    cd ..

    echo "Now in $(pwd)"
}

# Check if at least one version code is provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <version1> [version2] [...]"
  exit 1
fi

force_dir

# Loop through each version code to build the images
for VERSION in "$@"
do

  echo "Building Docker image for version: $VERSION"

  # Check if VERSION contains a "-"
  if [[ "$VERSION" == *"-"* ]]; then
      # Extract everything before the first "-"
      DOCKERFILE_FOLDER="${VERSION%%-*}"
  else
      DOCKERFILE_FOLDER="$VERSION"
  fi

  # Build the Docker image with the current version tag using the temporary Dockerfile
  docker build \
    --build-arg VERSION=$VERSION \
    --build-arg TAG=$TAG \
    -t osm2pgsql:$VERSION \
    -f "dockerfiles/$DOCKERFILE_FOLDER/Dockerfile" .

  if [ $? -eq 0 ]; then
    echo "Successfully built osm2pgsql:$VERSION"
  else
    echo "Failed to build osm2pgsql:$VERSION"
  fi

done
