#!/bin/bash

for VERSION in "$@"; do
  mkdir ../dockerfiles/$VERSION
  DOCKERFILE="../dockerfiles/$VERSION/Dockerfile"
  cp ../dockerfiles/template.Dockerfile $DOCKERFILE
  sed -i "s/{{ version }}/$VERSION/g" "$DOCKERFILE"
done
