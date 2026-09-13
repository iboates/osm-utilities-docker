#!/bin/bash

# Function to create a timestamp in RFC 3339 format
create_timestamp() {
    date --utc "+%Y-%m-%dT%H:%M:%SZ"
}


# Parse optional flags before the version list. --suffix appends a suffix to
# every tag pushed to Docker Hub, e.g. --suffix amd64 -> iboates/osmium:1.2.3-amd64
SUFFIX="-nightly"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --suffix)
      if [[ -n "${2:-}" ]]; then
        SUFFIX="-$2"
        shift 2
      else
        echo "Error: --suffix requires a value." >&2
        exit 1
      fi
      ;;
    *)
      break
      ;;
  esac
done

# Record a tag that was successfully pushed, so the manifest job knows which
# architectures exist for it. No-op when PUSHED_TAGS_FILE is unset (local runs).
record_pushed_tag() {
  if [ -n "${PUSHED_TAGS_FILE:-}" ]; then
    echo "$1" >> "$PUSHED_TAGS_FILE"
  fi
}

# Check if at least one version code is provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 [--suffix <suffix>] <version1> [version2] [...]"
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

    # Test successful. Only the largest version is published nightly, and only
    # as the latest-nightly tag (no per-version nightly tags).
    if [ "$LARGEST_VERSION" = "$VERSION" ]; then
      docker tag osmium:$VERSION iboates/osmium:latest$SUFFIX
      if docker push iboates/osmium:latest$SUFFIX; then
        record_pushed_tag "iboates/osmium:latest$SUFFIX"
        echo -e "latest$SUFFIX: \033[32mPUSHED\033[0m"
      else
        echo -e "latest$SUFFIX: \033[31mPUSH FAILED\033[0m"
      fi
    fi

  fi

done
