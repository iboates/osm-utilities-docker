#!/bin/bash

# Function to create a timestamp in RFC 3339 format
create_timestamp() {
    date --utc "+%Y-%m-%dT%H:%M:%SZ"
}


# Parse optional flags before the version list. --suffix appends a suffix to
# every tag pushed to Docker Hub, e.g. --suffix nightly-amd64 ->
# iboates/osm2pgrouting:2.3.8-nightly-amd64
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

# Versions that failed to build, test or push. Each failure is recorded and
# the loop moves on to the next version; the script exits non-zero at the end
# so the workflow run shows the failure instead of passing silently.
FAILED_VERSIONS=""
fail() {
  echo -e "$1: \033[31m$2\033[0m"
  FAILED_VERSIONS="$FAILED_VERSIONS $1"
}

# Check if at least one version code is provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 [--suffix <suffix>] <version1> [version2] [...]"
  exit 1
fi

if ! ./get_test_data.sh; then
  echo "Error: could not prepare the test data (data.osm)." >&2
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
  docker build --build-arg VERSION=$VERSION --build-arg TAG=$TAG -t osm2pgrouting:$VERSION -f "$TEMP_DOCKERFILE" .
  BUILD_STATUS=$?
  rm -f "$TEMP_DOCKERFILE"

  if [ $BUILD_STATUS -ne 0 ]; then
    fail "$VERSION" "BUILD FAILED"
    continue
  fi
  echo "Successfully built osm2pgrouting:$VERSION"

  # Test the image we just built
  cp docker-compose.yaml docker-compose.yaml.tmp
  sed -i "s/{{ version }}/$VERSION/g" docker-compose.yaml.tmp
  docker compose -f docker-compose.yaml.tmp up -d
  # Wait for the database, then create the extensions osm2pgrouting needs:
  # the pgrouting image does not install them in POSTGRES_DB.
  for _ in $(seq 1 30); do
    docker compose -f docker-compose.yaml.tmp exec -T postgis pg_isready -U o2p -h localhost > /dev/null 2>&1 && break
    sleep 2
  done
  docker compose -f docker-compose.yaml.tmp exec -T postgis \
    psql -U o2p -c "CREATE EXTENSION IF NOT EXISTS postgis; CREATE EXTENSION IF NOT EXISTS pgrouting;"
  docker compose -f docker-compose.yaml.tmp run --rm -v "$(pwd)":/data osm2pgrouting \
    -d o2p \
    -U o2p \
    -h postgis \
    -p 5432 \
    -W o2p \
    -f /data/data.osm \
    --clean

  output=$(docker compose -f docker-compose.yaml.tmp exec -T postgis \
          psql \
          -U o2p \
          -c "select count(*) from ways")

  # Extract the count value from the output
  count=$(echo "$output" | grep -o '[0-9]\+' | head -n 1) # Use head -n 1 to ensure we only get the first match
  echo "TEST RESULT: found " $count "features"

  # Assuming the count is always a number or empty. If count is empty, set it to 0
  count=${count:-0}

  # Remove the database volume too, so the next version starts from an empty
  # database instead of finding the rows this one imported.
  docker compose -f docker-compose.yaml.tmp down -v
  rm docker-compose.yaml.tmp

  # Push only if the import produced edges
  if [ "$count" -le 0 ]; then
    fail "$VERSION" "TEST FAILED"
    continue
  fi

  docker tag osm2pgrouting:$VERSION iboates/osm2pgrouting:$VERSION$SUFFIX
  if docker push iboates/osm2pgrouting:$VERSION$SUFFIX; then
    record_pushed_tag "iboates/osm2pgrouting:$VERSION$SUFFIX"
    echo -e "$VERSION$SUFFIX: \033[32mPUSHED\033[0m"
  else
    fail "$VERSION" "PUSH FAILED"
  fi

  if [ "$LARGEST_VERSION" = "$VERSION" ]; then
    docker tag osm2pgrouting:$VERSION iboates/osm2pgrouting:latest$SUFFIX
    if docker push iboates/osm2pgrouting:latest$SUFFIX; then
      record_pushed_tag "iboates/osm2pgrouting:latest$SUFFIX"
      echo -e "latest$SUFFIX: \033[32mPUSHED\033[0m"
    else
      fail "latest" "PUSH FAILED"
    fi
  fi

done

if [ -n "$FAILED_VERSIONS" ]; then
  echo "Failed:$FAILED_VERSIONS"
  exit 1
fi
