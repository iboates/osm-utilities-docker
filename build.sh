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

  echo "Building Docker image for version: $VERSION"

  # Create a temporary Dockerfile with version and timestamp replaced
  TEMP_DOCKERFILE="Dockerfile.$VERSION"
  cp dockerfiles/$VERSION/Dockerfile "$TEMP_DOCKERFILE"
  sed -i "s/{{ created }}/$CREATED/g" "$TEMP_DOCKERFILE"

  # Build the Docker image with the current version tag using the temporary Dockerfile
  docker build --build-arg VERSION=$VERSION --build-arg TAG=$TAG -t osm2pgsql:$VERSION -f "$TEMP_DOCKERFILE" .

  if [ $? -eq 0 ]; then
    echo "Successfully built osm2pgsql:$VERSION"
  else
    echo "Failed to build osm2pgsql:$VERSION"
    rm "$TEMP_DOCKERFILE" # Remove temporary Dockerfile if build fails
    exit 1
  fi

  rm "$TEMP_DOCKERFILE" # Remove temporary Dockerfile after successful build
done

echo "All versions built successfully."
