#!/bin/bash

set -e

docker login

for VERSION in "$@"
do
  docker tag osm2pgsql:latest iboates/osm2pgsql:latest > /dev/null 2>&1
  docker push iboates/osm2pgsql:latest
done

docker logout
