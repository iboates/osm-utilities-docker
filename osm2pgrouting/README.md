# osm2pgrouting-docker

Pre-built, minimalist Docker images for running [osm2pgrouting](https://github.com/pgRouting/osm2pgrouting)

## Why

There are indeed several osm2pgrouting docker images floating around on dockerhub, but I found that they all had at least
one deficiency:

- Version was hardcoded
- Also included other convenience features like built-in databases or other related GIS utilities
- Had not been updated in several years

## Use

### Quick start

The below example will pull the latest image and run it with no command (prints helpdocs).
Change `latest` to specific tag number to get that release version. Release version can be
found at the source repo's [releases page](https://github.com/pgRouting/osm2pgrouting/releases).

```sh
docker run docker.io/iboates/osm2pgrouting:latest
```

### Minimal import

The below example assumes you already have a PostGIS instance running on localhost, port 5432, and that it has the
pgRouting extension installed.

```sh
wget -O data.pbf https://download.geofabrik.de/europe/andorra-latest.osm
docker run -v $(pwd):/data -e PGPASSWORD=<your password> --network="host" iboates/osm2pgrouting:latest \
  --dbname o2p \
  --username o2p \
  --host 127.0.0.1 \
  --port 5432 \
  --clean \
  --f /data/data.osm
```

Note that in order to access an existing PostGIS instance on the host machine, you must specify `--network="host"`, so
that the container can access the port. A more sensible way of doing this is to include this image in a docker-compose
file which also contains a PostGIS instance, an example of which can be found here. If the PostGIS instance is on an
external IP, however, you should be able to omit this command.

Also note that when specifying locations of files, they must be specified using the mounted path inside the container.
In this example, we have mounted the current working directory as `/data`. So the PBF file we downloaded is accessible
at `/data/data.pbf`.

### Launch directly as docker-compose with PostGIS instance

The below example shows how to launch a more reasonable and ergonomic local deployment of osm2pgrouting with an accompanying
PostGIS instance:

```yaml
version: '3.8'

services:
  
  postgis:
    image: pgrouting/pgrouting:latest
    environment:
      POSTGRES_DB: o2p
      POSTGRES_USER: o2p
      POSTGRES_PASSWORD: o2p
    volumes:
      - postgis_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
        
  osm2pgrouting:
    image: iboates/osm2pgrouting:latest

volumes:
  postgis_data:
```

Run it like this:

```sh
docker compose up -d
```

And perform another minimal import like so:

```sh
wget -O data.osm.bz2 https://download.geofabrik.de/europe/andorra-latest.osm.bz2
bzip2 -d data.osm.bz2
docker compose run --rm -v $(pwd):/data osm2pgrouting \
  --dbname o2p \
  --username o2p \
  --password o2p \
  --host postgis \
  --port 5432 \
  --clean \
  --f /data/data.osm.bz2
```

The benefit here is that the PostGIS instance runs in the same network as where the osm2pgrouting container will run, and
we have bound its port 5432 to the host machine's port 5432, so you can connect to it directly as if it were just
running locally:

```sh
export PGPASSWORD=o2p; psql -h 127.0.0.1 -p 5432 -d o2p -U o2p -c "SELECT * FROM edges LIMIT 1;"
```

Verify that the import was successful:

```sql
SELECT * FROM edges LIMIT 1;
```

## Credits

* Images were built by Isaac Boates
* [`osm2pgrouting`](https://github.com/pgRouting/osm2pgrouting)
