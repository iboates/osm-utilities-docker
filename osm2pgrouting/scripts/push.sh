#!/bin/bash

set -e

docker login

for VERSION in "$@"
do
  if docker run --pull=never --rm osm2pgrouting:$VERSION 2>&1 | grep -q "osm2pgrouting" > /dev/null; then
    docker tag osm2pgrouting:$VERSION iboates/osm2pgrouting:$VERSION > /dev/null 2>&1
    docker push iboates/osm2pgrouting:$VERSION > /dev/null
    echo -e "$VERSION: \033[32mPUSHED\033[0m"
  else
    echo -e "$VERSION: \033[31mTEST FAILED, NOT PUSHING\033[0m"
  fi
done

docker logout
