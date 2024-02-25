#!/bin/bash

for VERSION in "$@"; do
  if docker run --pull=never --rm osm2pgsql:$VERSION 2>&1 | grep -q "osm2pgsql" >/dev/null; then
    echo -e "$VERSION: \033[32mPASSED\033[0m"
  else
    echo -e "$VERSION: \033[31mFAILED\033[0m"
  fi
done
