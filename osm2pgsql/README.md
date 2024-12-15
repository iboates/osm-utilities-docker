# osm2pgsql-docker

Pre-built, minimalist Docker images for running [osm2pgsql](https://github.com/osm2pgsql-dev/osm2pgsql)

The size might not be as minimal as it could be, work needs to be done to isolate runtime dependencies from build
dependencies to make the final images slimmer.

## Why

There are indeed several osm2pgsql docker images floating around on dockerhub, but I found that they all had at least
one deficiency:

- Version was hardcoded
- Also included other convenience features like built-in databases or other related GIS utilities
- Had not been updated in several years

So at the [OSM Hackathon at Geofabrik in Karlsruhe on 24.02 - 25.02](https://wiki.openstreetmap.org/wiki/Karlsruhe_Hack_Weekend_February_2024),
I resolved to build a comprehensive set of minimal images that contain only osm2pgsql, built with the official
instructions from the source repo.

## Use

### Quick start

The below example will pull the latest image and run it with no command (prints helpdocs).
Change `latest` to specific tag number to get that release version. Release version can be
found at the source repo's [releases page](https://github.com/osm2pgsql-dev/osm2pgsql/releases).

```sh
docker run docker.io/iboates/osm2pgsql:latest
```

The image can be build locally with this command:

```shell
docker build \
  --tag custom-osm2pgsql-image \
  --file dockerfiles/2.0.0/Dockerfile \
  scripts
```

**NOTE:** `osm2pgsql-replication` and `osm2pgsql-gen` are bundled with the image for every version for which these extra
utilities are compatible. For more information about how to invoke those, see
[the relevant section](###Using-extra-utilities)

### Minimal import

The below example assumes you already have a PostGIS instance running on localhost, port 5432.

```sh
wget -O data.pbf https://download.geofabrik.de/europe/andorra-latest.osm.pbf
docker run -v $(pwd):/data -e PGPASSWORD=<your password> --network="host" iboates/osm2pgsql:latest \
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

### Import directly from URL

An extra feature in this image compared to a native install is that you can pass a URL to a .pbf file instead of a file
path. The image will download the file, load it, then delete it afterwards:

```sh
docker run -v $(pwd):/data -e PGPASSWORD=<your password> --network="host" iboates/osm2pgsql:latest \
 -d o2p \
 -U o2p \
 -H 127.0.0.1 \
 -P 5432 \
 https://download.geofabrik.de/europe/andorra-latest.osm.pbf
```

The file will be downloaded to `/tmp` in the c bontainery default. You can change this if necessary by setting an
environment variable:

```
docker run -v $(pwd):/data -e PGPASSWORD=<your password> -e PBF_DOWNLOAD_DIR=<your download path> --network="host" iboates/osm2pgsql:latest \
 -d o2p \
 -U o2p \
 -H 127.0.0.1 \
 -P 5432 \
 https://download.geofabrik.de/europe/andorra-latest.osm.pbf
```

### Import with style file

The below example shows how to do an import with a custom style file

```sh
docker run -v $(pwd):/data -e PGPASSWORD=<your password> --network="host" iboates/osm2pgsql:latest \
 -d o2p \
 -U o2p \
 -H 127.0.0.1 \
 -P 5432 \
 -O flex \
 -S /data/style.lua \
 https://download.geofabrik.de/europe/andorra-latest.osm.pbf
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
docker compose run osm2pgsql \
 -d o2p \
 -U o2p \
 -H postgis \
 -P 5432 \
 https://download.geofabrik.de/europe/andorra-latest.osm.pbf
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

### Using extra utilities

It's important to realize that this image actually bundles `osm2pgsql` (the main application) and the
accompanying utilities (`osm2pgsql-replication`) [(script)](https://github.com/osm2pgsql-dev/osm2pgsql/blob/master/scripts/osm2pgsql-replication)
[(manual)](https://osm2pgsql.org/doc/man/osm2pgsql-replication-1.6.0.html) and `osm2pgsql-gen` [(manual)](https://osm2pgsql.org/doc/manual.html#generalization). Normally, one
would execute these via these identifiers, but since the image is named `osm2pgsql`, it can get unwieldly to have to
use a command like `docker run osm2pgsql:latest osm2pgsql-gen`, so we offer a lot of flexibility on how to access them.
The below table summarizes what combination of keywords will execute which utility:

| **Command**                                                   | **Equivalent in native install**    |
|---------------------------------------------------------------|-------------------------------------|
| `docker run osm2pgsql:latest <args>`                          | `osm2pgsql <args>`                  |
| `docker run osm2pgsql:latest osm2pgsql <args>`                | `osm2pgsql <args>`                  |
| `docker run osm2pgsql:latest replication <args>`              | `osm2pgsql-replication <args>`      |
| `docker run osm2pgsql:latest osm2pgsql-replication <args>`    | `osm2pgsql-replication <args>`      |
| `docker run osm2pgsql:latest gen <args>`                      | `osm2pgsql-gen <args>`              |
| `docker run osm2pgsql:latest generalization <args>`           | `osm2pgsql-gen <args>`              |
| `docker run osm2pgsql:latest osm2pgsql-generalization <args>` | `osm2pgsql-gen <args>`              |
| `docker run osm2pgsql:latest osm2pgsql-gen <args>`            | `osm2pgsql-gen <args>`              |

## Credits

* These images were built by Isaac Boates at the [OSM Hackathon at Geofabrik in Karlsruhe on 24.02 - 25.02](https://wiki.openstreetmap.org/wiki/Karlsruhe_Hack_Weekend_February_2024)
with help from the authors and other attendees
* `osm2pgsql` is primarily maintained by [Jochen Topf](https://www.jochentopf.com/de/)