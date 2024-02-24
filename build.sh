#!/bin/bash

# Function to create a timestamp in RFC 3339 format
create_timestamp() {
    date --utc "+%Y-%m-%dT%H:%M:%SZ"
}

# Check if at least one version code is provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <version1> [version2] [...]"
  exit 1
fi

# Loop through each version code to build the images
for VERSION in "$@"
do

  if [ "$VERSION" == "latest" ]; then TAG="master"; else TAG="$VERSION"; fi

  echo "Building Docker image for version: $VERSION"

  # Create a timestamp for this build
  CREATED=$(create_timestamp)

  # Create a temporary Dockerfile with version and timestamp replaced
  TEMP_DOCKERFILE="Dockerfile.$VERSION"
  cp dockerfiles/Dockerfile "$TEMP_DOCKERFILE"
  sed -i "s/{{ version }}/$VERSION/g" "$TEMP_DOCKERFILE"
  sed -i "s/{{ tag }}/$TAG/g" "$TEMP_DOCKERFILE"
  sed -i "s/{{ created }}/$CREATED/g" "$TEMP_DOCKERFILE"

  # Build the Docker image with the current version tag using the temporary Dockerfile
  dockerfiles build --build-arg VERSION=$VERSION --build-arg TAG=$TAG -t osm2pgsql:$VERSION -f "$TEMP_DOCKERFILE" .

  if [ $? -eq 0 ]; then
    echo "Successfully built osm2pgsql:$VERSION"
  else
    echo "Failed to build osm2pgsql:$VERSION"
    rm "$TEMP_DOCKERFILE" # Remove temporary Dockerfile if build fails
    exit 1
  fi

  rm "$TEMP_DOCKERFILE" # Remove temporary Dockerfile after successful build
done

# If "latest" was specified, tag the highest version as latest
if [ ! -z "$LATEST_TAG" ]; then
  echo "Tagging highest version $HIGHEST_VERSION as latest..."
  dockerfiles tag osm2pgsql:$HIGHEST_VERSION osm2pgsql:latest
fi

echo "All versions built successfully."
