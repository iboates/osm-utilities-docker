FROM docker.io/alpine:latest AS builder

RUN apk --no-cache add \
    git \
    cmake \
    make \
    g++ \
    nlohmann-json \
    postgresql-dev \
    boost-dev \
    expat-dev \
    bzip2-dev \
    zlib-dev \
    libpq \
    proj-dev \
    lua5.3-dev \
    luajit-dev

RUN git clone -b 1.3.0 https://github.com/osm2pgsql-dev/osm2pgsql.git
WORKDIR osm2pgsql

RUN mkdir build
WORKDIR build
RUN cmake -D WITH_LUAJIT=ON ..
RUN make
RUN make install

FROM docker.io/python:3.8-alpine

RUN apk --no-cache add \
    nlohmann-json \
    boost \
    expat \
    bzip2 \
    zlib \
    libpq \
    proj \
    lua5.3 \
    luajit \
    potrace \
    opencv \
    lz4-libs \
    curl

COPY --from=builder /usr/local/bin/osm2pgsql* /usr/local/bin/
COPY --from=builder /usr/local/share/osm2pgsql/*.style /usr/local/share/osm2pgsql/
# Fix CVE vulns
RUN pip install --upgrade setuptools certifi

# Where pbfs will get downloaded to if specified via URL
ENV PBF_DOWNLOAD_DIR /tmp

COPY LICENSE LICENSE

LABEL org.opencontainers.image.created="{{ created }}" \
      org.opencontainers.image.authors="Isaac Boates <iboates@gmail.com>" \
      org.opencontainers.image.url="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.documentation="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.source="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.version="1.3.0" \
      org.opencontainers.image.licenses="GPL-2.0" \
      org.opencontainers.image.title="osm2pgsql" \
      org.opencontainers.image.description="osm2pgsql is a tool for loading OpenStreetMap data into a PostgreSQL / PostGIS database suitable for applications like rendering into a map, geocoding with Nominatim, or general analysis."


ENTRYPOINT ["osm2pgsql"]

CMD ["-h"]
