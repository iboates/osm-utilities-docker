#!/bin/sh

# Check the first argument for multiple conditions
if [ "$1" = "replication" ] || [ "$1" = "osm2pgsql-replication" ]; then
    # If the first argument is "replication" or "osm2pgsql-replication", shift it off
    # and pass the remaining arguments to osm2pgsql-replication
    shift
    exec osm2pgsql-replication "$@"
elif [ "$1" = "osm2pgsql" ]; then
    # If the first argument is "osm2pgsql", shift it off
    # and pass the remaining arguments to osm2pgsql
    shift
    exec osm2pgsql "$@"
else
    # If the first argument is anything else or not provided,
    # pass all arguments to osm2pgsql, assuming the user wants to use osm2pgsql directly
    exec osm2pgsql "$@"
fi
