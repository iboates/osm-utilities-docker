FROM docker.io/alpine:latest as builder

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

RUN git clone -b 1.8.1 https://github.com/osm2pgsql-dev/osm2pgsql.git
WORKDIR osm2pgsql

# for some inscrutable reason, compilation fails due to a missing #include statement in versions 1.8.0 and 1.8.1, and
# ONLY in those versions. Slipping this line in here seems to fix the issue. For a more detailed explanation, see the
# file "about_that_awk_statement.txt".
RUN awk '/^#include/ && !added { print "#include <cstdint>"; added=1 } {print}' src/flex-index.hpp > src/flex-index.hpp.tmp && mv src/flex-index.hpp.tmp src/flex-index.hpp

RUN mkdir build
WORKDIR build
RUN cmake -D WITH_LUAJIT=ON ..
RUN make
RUN make install

LABEL org.opencontainers.image.created="{{ created }}" \
      org.opencontainers.image.authors="Isaac Boates <iboates@gmail.com>" \
      org.opencontainers.image.url="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.documentation="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.source="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.version="1.8.1" \
      org.opencontainers.image.licenses="GPL-2.0" \
      org.opencontainers.image.title="osm2pgsql" \
      org.opencontainers.image.description="osm2pgsql is a tool for loading OpenStreetMap data into a PostgreSQL / PostGIS database suitable for applications like rendering into a map, geocoding with Nominatim, or general analysis."


ENTRYPOINT ["osm2pgsql"]

CMD ["-h"]
