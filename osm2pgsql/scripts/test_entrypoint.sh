#!/bin/sh
# Regression test for entrypoint.sh argument handling.
#
# Runs the entrypoint against stub curl / osm2pgsql / osm2pgsql-replication
# commands that record what they receive, so it needs no network or database.
#
# Usage: test_entrypoint.sh [path/to/entrypoint.sh]   (default: /entrypoint.sh)
# In the image: docker compose run --rm --entrypoint sh osm2pgsql /data/test_entrypoint.sh

ENTRYPOINT=${1:-/entrypoint.sh}
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/dl"

# Stubs print one argument per line, so splitting and rewriting are visible.
for cmd in osm2pgsql osm2pgsql-replication; do
  cat > "$WORK/bin/$cmd" <<EOF
#!/bin/sh
echo "CMD $cmd"
for a in "\$@"; do echo "ARG \$a"; done
EOF
done
cat > "$WORK/bin/curl" <<'EOF'
#!/bin/sh
echo "CURL $*"
EOF
chmod +x "$WORK/bin/"*

FAILED=0

# check NAME EXPECTED ARGS...: run the entrypoint and compare its output.
check() {
  name=$1
  expected=$2
  shift 2
  actual=$(PATH="$WORK/bin:$PATH" PBF_DOWNLOAD_DIR="$WORK/dl" sh "$ENTRYPOINT" "$@" 2>&1)
  if [ "$actual" = "$expected" ]; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    echo "--- expected"; echo "$expected"
    echo "--- actual";   echo "$actual"
    FAILED=1
  fi
}

SERVER=https://planet.osm.org/replication/minute/

check "replication --server URL is passed through, not downloaded" \
"CMD osm2pgsql-replication
ARG init
ARG -d
ARG o2p
ARG --server
ARG $SERVER" \
  osm2pgsql-replication init -d o2p --server "$SERVER"

check "replication alias --server URL is passed through" \
"CMD osm2pgsql-replication
ARG init
ARG --server
ARG $SERVER" \
  replication init --server "$SERVER"

check "replication --server=URL is passed through" \
"CMD osm2pgsql-replication
ARG init
ARG --server=$SERVER" \
  osm2pgsql-replication init "--server=$SERVER"

check "osm2pgsql URL input is downloaded and replaced" \
"CURL -fL -o $WORK/dl/andorra.osm.pbf https://example.com/andorra.osm.pbf
CMD osm2pgsql
ARG -d
ARG o2p
ARG $WORK/dl/andorra.osm.pbf" \
  -d o2p https://example.com/andorra.osm.pbf

check "conninfo with spaces stays one argument" \
"CMD osm2pgsql
ARG -d
ARG dbname=o2p host=postgis
ARG /data/data.pbf" \
  osm2pgsql -d "dbname=o2p host=postgis" /data/data.pbf

check "replication conninfo with spaces stays one argument" \
"CMD osm2pgsql-replication
ARG status
ARG -d
ARG dbname=o2p host=postgis" \
  replication status -d "dbname=o2p host=postgis"

exit $FAILED
