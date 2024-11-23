#!/bin/sh

# Check the first argument for multiple conditions
case "$1" in
  osm2pgsql*)
    exec "$@"
    ;;
  replication)
    shift
    exec osm2pgsql-replication "$@"
    ;;
  osm2pgsql-replication)
    shift
    exec osm2pgsql-replication "$@"
    ;;
  osm2pgsql-gen)
    shift
    exec osm2pgsql-gen "$@"
    ;;
  osm2pgsql-generalization)
    shift
    exec osm2pgsql-gen "$@"
    ;;
  generalization)
    shift
    exec osm2pgsql-gen "$@"
    ;;
  gen)
    shift
    exec osm2pgsql-gen "$@"
    ;;
  *)
    exec osm2pgsql "$@"
    ;;
esac
