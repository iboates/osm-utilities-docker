#!/bin/bash

# Remaining arguments are considered version numbers
for VERSION in "$@"; do
  if docker run --pull=never --rm osmium:$VERSION 2>&1 | grep -q "osmium"; then

    echo -e "$VERSION: \033[32mPASSED\033[0m"
  else
    echo -e "$VERSION: \033[31mFAILED\033[0m"
  fi
done
