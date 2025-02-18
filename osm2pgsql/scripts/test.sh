#!/bin/bash

# Check if at least one version code is provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <version1> [version2] [...]"
  exit 1
fi

force_dir() {
    # Traverse up until we find "osm-utilities-docker"
    while [[ "$PWD" != "/" && "$(basename "$PWD")" != "osm-utilities-docker" ]]; do
        cd ..
    done

    # Ensure we're in "osm-utilities-docker", then move into "osm2pgsql/scripts"
    if [[ "$(basename "$PWD")" == "osm-utilities-docker" ]]; then
        cd osm2pgsql/scripts || { echo "Error: scripts directory not found"; exit 1; }
    else
        # echo "Error: Not inside osm-utilities-docker or its subdirectories"
        exit 1
    fi

    # echo "Now in $(pwd)"
}

force_dir

wget -O data.pbf https://download.geofabrik.de/europe/andorra-latest.osm.pbf &> /dev/null

# Loop through each version code to build the images
for VERSION in "$@"
do

  # Test the image we just built
    export VERSION="$VERSION"
    docker compose -f docker-compose.yaml up -d &> /dev/null
    sleep 10
    docker compose -f docker-compose.yaml run --rm osm2pgsql \
      -d o2p \
      -U o2p \
      -H postgis \
      -P 5432 \
      /data/data.pbf &> /dev/null

      output=$(docker compose -f docker-compose.yaml exec postgis \
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
    docker compose down &> /dev/null

done
