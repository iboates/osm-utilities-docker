#!/bin/bash

deep_mode=false

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --deep) deep_mode=true ;;
    *) break ;;
  esac
  shift
done

# If deep mode is enabled, download the file
if $deep_mode; then
  wget -O data.pbf https://download.geofabrik.de/europe/andorra-latest.osm.bz2  > /dev/null 2>&1
  bzip2 -d data.osm.bz2
fi

# Remaining arguments are considered version numbers
for VERSION in "$@"; do
  if docker run --pull=never --rm osm2pgrouting:$VERSION 2>&1 | grep -q "osm2pgrouting"; then
    if $deep_mode; then
      cp docker-compose.yaml docker-compose.yaml.tmp
      sed -i "s/{{ version }}/$VERSION/g" docker-compose.yaml.tmp
      docker compose -f docker-compose.yaml.tmp up -d > /dev/null 2>&1
      sleep 10
      docker compose -f docker-compose.yaml.tmp run -v "$(pwd)":/data osm2pgrouting \
        -d o2p \
        -U o2p \
        -h postgis \
        -p 5432 \
        -W o2p \
        -f /data/data.osm

                # Correctly capture the output without redirecting it to /dev/null
        output=$(docker compose -f docker-compose.yaml.tmp exec postgis \
                psql \
                -U o2p \
                -c "select count(*) from edges limit 1")

        # Extract the count value from the output
        count=$(echo "$output" | grep -o '[0-9]\+' | head -n 1) # Use head -n 1 to ensure we only get the first match

        # Assuming the count is always a number or empty. If count is empty, set it to 0
        count=${count:-0}

        # Check if the count is less than or equal to 0
        if [ "$count" -le 0 ]; then
           echo -e "$VERSION: \033[31mFAILED (deep)\033[0m"
        fi

      # Use the -f flag with docker compose down to ensure it uses the correct compose file
      docker compose -f docker-compose.yaml.tmp down > /dev/null 2>&1
      rm docker-compose.yaml.tmp

    fi

    echo -e "$VERSION: \033[32mPASSED\033[0m"
  else
    echo -e "$VERSION: \033[31mFAILED\033[0m"
  fi
done
