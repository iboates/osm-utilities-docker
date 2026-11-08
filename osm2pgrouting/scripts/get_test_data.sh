#!/bin/bash
#
# Fetch the test fixture into the current directory as data.osm.
#
# osm2pgrouting only reads OSM XML. Geofabrik no longer publishes .osm.bz2
# extracts, so download the .pbf and convert it with this repo's osmium image.

set -euo pipefail

PBF_URL="https://download.geofabrik.de/europe/andorra-latest.osm.pbf"

wget -q -O data.osm.pbf "$PBF_URL"

docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/data -w /data \
  iboates/osmium:latest cat --overwrite data.osm.pbf -o data.osm

rm -f data.osm.pbf

# Fail loudly rather than letting every version's import test find 0 rows.
[ -s data.osm ]
