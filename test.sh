#!/bin/bash

wget -O data.pbf https://download.geofabrik.de/europe/andorra-latest.osm.pbf > /dev/null 2>&1

for VERSION in "$@"
do
  docker run --rm --name o2p_db -e POSTGRES_USER=o2p -e POSTGRES_PASSWORD=o2p -e POSTGRES_DB=o2p -d -p 0.0.0.0:5432:5432 postgis/postgis  > /dev/null 2>&1
  sleep 10

  docker run -v $(pwd):/data -e PGPASSWORD=o2p --network="host" osm2pgsql:$VERSION -d o2p -U o2p -W -H 127.0.0.1 -P 5432 /data/data.pbf  > /dev/null 2>&1

  OUTPUT=$(docker exec o2p_db psql -qtAX -U o2p -d o2p -c "SELECT COUNT(*) FROM planet_osm_point;")  > /dev/null 2>&1
  # The -q option suppresses welcome messages
  # The -t option prints rows only
  # The -A option disables alignment (removes padding around the columns)
  # The -X option ignores the startup file (to avoid unexpected behavior in scripts)

  # Convert the captured output to an integer
  COUNT=$(echo $OUTPUT | xargs) # xargs trims whitespace

  # Check if count is greater than 0
  if [ "${COUNT:-0}" -eq 0 ]; then
    echo -e "$VERSION: \033[31mFAILED\033[0m"
  else
    echo -e "$VERSION: \033[32mPASSED\033[0m"
  fi

  docker stop o2p_db > /dev/null 2>&1
  sleep 10
done
