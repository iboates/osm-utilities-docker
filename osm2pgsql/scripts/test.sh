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

wget -O data.pbf https://download.geofabrik.de/europe/andorra-latest.osm.pbf

LARGEST_VERSION=$(basename $(ls -d ../dockerfiles/*/ | sort -V | tail -n 1))

# Loop through each version code to build the images
for VERSION in "$@"
do

  # Test the image we just built
  cp docker-compose.yaml docker-compose.yaml.tmp
      sed -i "s/{{ version }}/$VERSION/g" docker-compose.yaml.tmp
      docker compose -f docker-compose.yaml.tmp up -d
      sleep 10
      docker compose -f docker-compose.yaml.tmp run -v "$(pwd)":/data osm2pgsql \
        -d o2p \
        -U o2p \
        -H postgis \
        -P 5432 \
        /data/data.pbf

        output=$(docker compose -f docker-compose.yaml.tmp exec postgis \
                psql \
                -U o2p \
                -c "select count(*) from planet_osm_point limit 1")

        # Extract the count value from the output
        count=$(echo "$output" | grep -o '[0-9]\+' | head -n 1) # Use head -n 1 to ensure we only get the first match

        # Assuming the count is always a number or empty. If count is empty, set it to 0
        count=${count:-0}

        # If the count is greater than zero then the test passes
        if [ "$count" -gt 0 ]; then
          echo -e "$VERSION \033[32mPASSED\033[0m"
        else
          echo -e "$VERSION \033[31mFAILED\033[0m"
        fi

      # Use the -f flag with docker compose down to ensure it uses the correct compose file
      docker compose -f docker-compose.yaml.tmp down
      rm docker-compose.yaml.tmp

done
