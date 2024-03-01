# osmium-docker

Pre-built, minimalist Docker images for running [osmium](https://github.com/osm2pgsql-dev/osmium-tool)

The size might not be as minimal as it could be, work needs to be done to isolate runtime dependencies from build
dependencies to make the final images slimmer.

## Why

At the [OSM Hackathon at Geofabrik in Karlsruhe on 24.02 - 25.02](https://wiki.openstreetmap.org/wiki/Karlsruhe_Hack_Weekend_February_2024),
I made docker images for [osm2pgsql](https://github.com/osm2pgsql-dev/osm2pgsql), and this is a continuation of that
work.

## Use

### Quick start

The below example will pull the latest image and run it with no command (prints helpdocs).
Change `latest` to specific tag number to get that release version. Release version can be
found at the source repo's [releases page](https://github.com/osm2pgsql-dev/osmium-tool/releases).

```sh
docker run docker.io/iboates/osmium:latest
```

### Example (count tags)

The below example counts the tags in a PBF file.

```sh
wget -O data.pbf https://download.geofabrik.de/europe/andorra-latest.osm.pbf
docker run -v $(pwd):/data iboates/osmium:latest /data/data.pbf
```

All the same commands as the regular application can be run by passing them to the `docker run` command.
See the [manual](https://osmcode.org/osmium-tool/manual.html).

## Credits

* Images built by Isaac Boates
* `osmium` is primarily maintained by [Jochen Topf](https://www.jochentopf.com/de/)
