#!/bin/bash

set -e

for VERSION in "$@"
do
  docker run --pull=never --rm osm2pgsql:$VERSION 2>&1 | grep -q "osm2pgsql" > /dev/null; then
  docker tag osm2pgsql:$VERSION iboates/osm2pgsql:$VERSION > /dev/null 2>&1
  docker push iboates/osm2pgsql:$VERSION > /dev/null
  echo -e "$VERSION: \033[32mPUSHED\033[0m"
  docker image rm iboates/osm2pgsql:$VERSION
done
