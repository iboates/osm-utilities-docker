FROM alpine:latest

RUN apk update
RUN apk --update-cache add \
    git \
    cmake \
    make \
    g++ \
    boost-dev \
    expat-dev \
    bzip2-dev \
    zlib-dev \
    libpq \
    nlohmann-json \
    proj-dev \
    lua5.3-dev \
    postgresql-dev \
    luajit-dev

RUN git clone -b {{ tag }} https://github.com/osm2pgsql-dev/osm2pgsql.git
WORKDIR osm2pgsql

RUN mkdir build
WORKDIR build
RUN cmake -D WITH_LUAJIT=ON ..
RUN make
# RUN make man
RUN make install
# RUN make install-gen

LABEL org.opencontainers.image.created="{{ created }}" \
      org.opencontainers.image.authors="Isaac Boates <iboates@gmail.com>" \
      org.opencontainers.image.url="TODO" \
      org.opencontainers.image.documentation="TODO" \
      org.opencontainers.image.source="TODO" \
      org.opencontainers.image.version="{{ version }}" \
      org.opencontainers.image.licenses="GPL-2.0" \
      org.opencontainers.image.title="osm2pgsql" \
      org.opencontainers.image.description="osm2pgsql is a tool for loading OpenStreetMap data into a PostgreSQL / PostGIS database suitable for applications like rendering into a map, geocoding with Nominatim, or general analysis."


ENTRYPOINT ["osm2pgsql"]

CMD ["-h"]
