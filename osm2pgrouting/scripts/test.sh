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
  ./get_test_data.sh || { echo "Error: could not prepare the test data (data.osm)." >&2; exit 1; }
fi

# Remaining arguments are considered version numbers
for VERSION in "$@"; do
  if docker run --pull=never --rm osm2pgrouting:$VERSION 2>&1 | grep -q "osm2pgrouting"; then
    deep_failed=false
    if $deep_mode; then
      cp docker-compose.yaml docker-compose.yaml.tmp
      sed -i "s/{{ version }}/$VERSION/g" docker-compose.yaml.tmp
      docker compose -f docker-compose.yaml.tmp up -d > /dev/null 2>&1
      # Wait for the database, then create the extensions osm2pgrouting needs:
      # the pgrouting image does not install them in POSTGRES_DB.
      for _ in $(seq 1 30); do
        docker compose -f docker-compose.yaml.tmp exec -T postgis pg_isready -U o2p -h localhost > /dev/null 2>&1 && break
        sleep 2
      done
      docker compose -f docker-compose.yaml.tmp exec -T postgis \
        psql -U o2p -c "CREATE EXTENSION IF NOT EXISTS postgis; CREATE EXTENSION IF NOT EXISTS pgrouting;" > /dev/null 2>&1
      docker compose -f docker-compose.yaml.tmp run -v "$(pwd)":/data osm2pgrouting \
        -d o2p \
        -U o2p \
        -h postgis \
        -p 5432 \
        -W o2p \
        -f /data/data.osm \
        --clean

                # Correctly capture the output without redirecting it to /dev/null
        output=$(docker compose -f docker-compose.yaml.tmp exec -T postgis \
                psql \
                -U o2p \
                -c "select count(*) from ways")

        # Extract the count value from the output
        count=$(echo "$output" | grep -o '[0-9]\+' | head -n 1) # Use head -n 1 to ensure we only get the first match

        # Assuming the count is always a number or empty. If count is empty, set it to 0
        count=${count:-0}

        # Check if the count is less than or equal to 0
        if [ "$count" -le 0 ]; then
           deep_failed=true
        fi

      # Use the -f flag with docker compose down to ensure it uses the correct compose file
      docker compose -f docker-compose.yaml.tmp down -v > /dev/null 2>&1
      rm docker-compose.yaml.tmp

    fi

    if $deep_failed; then
      echo -e "$VERSION: \033[31mFAILED (deep)\033[0m"
    else
      echo -e "$VERSION: \033[32mPASSED\033[0m"
    fi
  else
    echo -e "$VERSION: \033[31mFAILED\033[0m"
  fi
done
