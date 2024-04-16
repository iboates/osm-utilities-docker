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

wget -O data.osm.bz2 https://download.geofabrik.de/europe/andorra-latest.osm.bz2
bzip2 -d data.osm.bz2

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

  if [ $? -eq 0 ]; then
    echo "Successfully built osm2pgrouting:$VERSION"
  else
    echo "Failed to build osm2pgrouting:$VERSION"
    rm "$TEMP_DOCKERFILE" # Remove temporary Dockerfile if build fails
  fi

  rm "$TEMP_DOCKERFILE" # Remove temporary Dockerfile after successful build

  # Test the image we just built
  cp docker-compose.yaml docker-compose.yaml.tmp
      sed -i "s/{{ version }}/$VERSION/g" docker-compose.yaml.tmp
      docker compose -f docker-compose.yaml.tmp up -d
      sleep 10
      docker compose -f docker-compose.yaml.tmp run -v "$(pwd)":/data multiple primary keys \
        -d o2p \
        -U o2p \
        -h postgis \
        -p 5432 \
        -W o2p \
        -f /data/data.osm

        output=$(docker compose -f docker-compose.yaml.tmp exec postgis \
                psql \
                -U o2p \
                -c "select count(*) from edges limit 1")

        # Extract the count value from the output
        count=$(echo "$output" | grep -o '[0-9]\+' | head -n 1) # Use head -n 1 to ensure we only get the first match
        echo "TEST RESULT: found " $count "features"

        # Assuming the count is always a number or empty. If count is empty, set it to 0
        count=${count:-0}

        # If the count is greater than zero then the test passes
        if [ "$count" -gt 0 ]; then
          docker tag osm2pgrouting:$VERSION iboates/osm2pgrouting:$VERSION-nightly
          docker push iboates/osm2pgrouting:$VERSION-nightly
          echo -e "$VERSION-nightly: \033[32mPUSHED\033[0m"

          if [ "$LARGEST_VERSION" = "$VERSION" ]; then
            docker tag osm2pgrouting:$VERSION iboates/osm2pgrouting:latest-nightly
            docker push iboates/osm2pgrouting:latest-nightly
            echo -e "latest-nightly: \033[32mPUSHED\033[0m"
          fi

        fi

      # Use the -f flag with docker compose down to ensure it uses the correct compose file
      docker compose -f docker-compose.yaml.tmp down
      rm docker-compose.yaml.tmp

done
