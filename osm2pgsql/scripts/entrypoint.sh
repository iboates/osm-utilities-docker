#!/bin/sh

# Check the first argument for multiple conditions
case "$1" in
  osm2pgsql*)
    # If the first argument is beginning with "osm2pgsql",
    # call it verbatim
    exec "$@"
    ;;
  replication)
    # If the first argument is "replication", shift it off
    # and pass the remaining arguments to osm2pgsql-replication
    shift
    exec osm2pgsql-replication "$@"
    ;;
  *)
    # If the first argument is anything else or not provided,
    # pass all arguments to osm2pgsql, assuming the user wants to use osm2pgsql directly
    exec osm2pgsql "$@"
    ;;
esac
