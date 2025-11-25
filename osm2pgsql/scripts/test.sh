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
        exit 1
    fi
}

force_dir

wget -O data.pbf https://download.geofabrik.de/europe/andorra-latest.osm.pbf &> /dev/null

############################################
# Function that runs the whole version test
############################################
run_test() {
    VERSION="$1"
    export VERSION

    # Bring up containers
    docker compose -f docker-compose.yaml up -d &> /dev/null || return 1
    sleep 30

    # Import the PBF
    docker compose -f docker-compose.yaml run --rm osm2pgsql \
      -d o2p \
      -U o2p \
      -H postgis \
      -P 5432 \
      /data/data.pbf &> /dev/null || return 1

    # Query PostGIS for a known table count
    output=$(docker compose -f docker-compose.yaml exec postgis \
        psql \
        -U o2p \
        -c "select count(*) from planet_osm_point limit 1" 2>/dev/null) || return 1

    # Extract the count
    count=$(echo "$output" | grep -o '[0-9]\+' | head -n 1)
    count=${count:-0}

    # Shut down containers
    docker compose down &> /dev/null || true

    # Clean up old volumes because it might be stopping the publish pipeline from working
    docker volume prune --all --force

    # Return success only if count > 0
    [ "$count" -gt 0 ]
}

############################################
# Main loop with retry logic
############################################
for VERSION in "$@"; do
    attempts=0
    max_attempts=3
    success=false

    while [ $attempts -lt $max_attempts ]; do
        if run_test "$VERSION"; then
            echo -e "$VERSION \033[32mPASSED\033[0m"
            success=true
            break
        else
            attempts=$((attempts+1))
            if [ $attempts -lt $max_attempts ]; then
                echo "Attempt $attempts for $VERSION failed, retrying in 30 seconds..."
                sleep 30
            fi
        fi
    done

    if [ "$success" = false ]; then
        echo -e "$VERSION \033[31mFAILED\033[0m after $max_attempts attempts"
    fi
done
