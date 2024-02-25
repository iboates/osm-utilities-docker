# osm2pgsql-docker

Pre-built, minimalist Docker images for running [osm2pgsql](https://github.com/osm2pgsql-dev/osm2pgsql)

## Why

There are indeed several osm2pgsql docker images floating around on dockerhub, but I found that they all had at least
one deficiency:

- Version was hardcoded
- Also included other convenience features like built-in databases or other related GIS utilities
- Had not been updated in several years

So at the [OSM Hackathon at Geofabrik in Karlsruhe on 24.02 - 25.02](https://wiki.openstreetmap.org/wiki/Karlsruhe_Hack_Weekend_February_2024),
I resolved to build a comprehensive set of minimal images that contain only osm2pgsql, built with the official
instructions from the source repo.

I also took the additional step of identifying which dependencies were only necessary at build-time and removing them
from the final image for maximum minimalism.

## Use

### Quick start

The below example will pull the latest image and run it with no command (prints helpdocs).
Change `latest` to specific tag number to get that release version. Release version can be
found at the source repo's [releases page](https://github.com/osm2pgsql-dev/osm2pgsql/releases).

```sh
docker run docker.io/iboates/osm2pgsql:latest
```

### Minimal import

The below example assumes you already have a PostGIS instance running on localhost, port 5432.

```sh
wget -O data.pbf https://download.geofabrik.de/europe/andorra-latest.osm.pbf
docker run -v $(pwd):/data -e PGPASSWORD=<your password> --network="host" osm2pgsql:latest \
 -d o2p \
 -U o2p \
 -H 127.0.0.1 \
 -P 5432 \
 /data/data.pbf
```

Note that in order to access an existing PostGIS instance on the host machine, you must specify `--network="host"`, so
that the container can access the port. A more sensible way of doing this is to include this image in a docker-compose
file which also contains a PostGIS instance, an example of which can be found here. If the PostGIS instance is on an
external IP, however, you should be able to omit this command.

Also note that when specifying locations of files, they must be specified using the mounted path inside the container.
In this example, we have mounted the current working directory as `/data`. So the PBF file we downloaded is accessible
at `/data/data.pbf`.

### Import with style file

The below example shows how to do an import with a custom style file

```sh
wget -O data.pbf https://download.geofabrik.de/europe/andorra-latest.osm.pbf
docker run -v $(pwd):/data -e PGPASSWORD=<your password> --network="host" osm2pgsql:latest \
 -d o2p \
 -U o2p \
 -H 127.0.0.1 \
 -P 5432 \
 -O flex \
 -S /data/style.lua \
 /data/data.pbf
```

As before, note that when specifying locations of files, they must be specified using the mounted path inside the
container. In this example, we have mounted the current working directory as `/data`. So for this example, the PBF file
we downloaded is accessible at `/data/data.pbf`, and the style file must be saved in the current directory as
`style.lua`, and will be accessible at `/data/style.lua`

For more information regarding the `-O` flag and styles in general, please refer to the [manual](https://osm2pgsql.org/doc/manual.html#output-options),
as it is a rather complex topic that is outside of the scope of the docker images.

### Launch directly as docker-compose with PostGIS instance

The below example shows how to launch a more reasonable and ergonomic local deployment of osm2pgsql with an accompanying
PostGIS instance:

```yaml
version: '3.8'

services:
  
  postgis:
    image: postgis/postgis:latest
    environment:
      POSTGRES_DB: o2p
      POSTGRES_USER: o2p
      POSTGRES_PASSWORD: o2p
    volumes:
      - postgis_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
        
  osm2pgsql:
    image: iboates/osm2pgsql:latest
    environment:
      PGPASSWORD: o2p

volumes:
  postgis_data:
```

Run it like this:

```sh
docker compose up -d
```

And perform another minimal import like so:

```sh
wget -O data.pbf https://download.geofabrik.de/europe/andorra-latest.osm.pbf
docker compose run -v $(pwd):/data osm2pgsql \
 -d o2p \
 -U o2p \
 -H 127.0.0.1 \
 -P 5432 \
 /data/data.pbf
```

The benefit here is that the PostGIS instance runs in the same network as where the osm2pgsql container will run, and
we have bound its port 5432 to the host machine's port 5432, so you can connect to it directly as if it were just
running locally:

```sh
export PGPASSWORD=o2p; psql -h 127.0.0.1 -p 5432 -d o2p -U o2p
```

Verify that the import was successful:

```sql
SELECT osm_id FROM planet_osm_point LIMIT 1;
```

## Credits

These images were built by Isaac Boates at the [OSM Hackathon at Geofabrik in Karlsruhe on 24.02 - 25.02](https://wiki.openstreetmap.org/wiki/Karlsruhe_Hack_Weekend_February_2024)
with help from the authors and other attendees
