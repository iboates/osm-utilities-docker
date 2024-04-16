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

LARGEST_VERSION=$(basename $(ls -d ../dockerfiles/*/ | sort -V | tail -n 1))

# Loop through each version code to build the images
for VERSION in "$@"
do

  echo "Building Docker image for version: $VERSION"
  CREATED=$(create_timestamp)

  # Create a temporary Dockerfile with version and timestamp replaced
  TEMP_DOCKERFILE="Dockerfile.$VERSION"
  cp ../dockerfiles/$VERSION/Dockerfile "$TEMP_DOCKERFILE"
  sed -i "s/{{ created }}/$CREATED/g" "$TEMP_DOCKERFILE"

  # Build the Docker image with the current version tag using the temporary Dockerfile
  docker build --build-arg VERSION=$VERSION --build-arg TAG=$TAG -t osmium:$VERSION -f "$TEMP_DOCKERFILE" .

  if [ $? -eq 0 ]; then
    echo "Successfully built osmium:$VERSION"
  else
    echo "Failed to build osmium:$VERSION"
    rm "$TEMP_DOCKERFILE" # Remove temporary Dockerfile if build fails
  fi

  rm "$TEMP_DOCKERFILE" # Remove temporary Dockerfile after successful build

  # Test the image we just built
  if docker run --pull=never --rm osmium:$VERSION 2>&1 | grep -q "osmium"; then

    # Test successful, push
    docker tag osmium:$VERSION iboates/osmium:$VERSION-nightly
    docker push iboates/osmium:$VERSION-nightly
    echo -e "$VERSION-nightly: \033[32mPUSHED\033[0m"

    if [ "$LARGEST_VERSION" = "$VERSION" ]; then
      docker tag osmium:$VERSION iboates/osmium:latest-nightly
      docker push iboates/osmium:latest-nightly
      echo -e "latest-nightly: \033[32mPUSHED\033[0m"
    fi

  fi

done
