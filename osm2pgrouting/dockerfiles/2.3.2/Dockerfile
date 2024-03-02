FROM docker.io/alpine:latest

RUN apk add --no-cache \
    expat \
    expat-dev \
    boost-dev \
    boost-program_options \
    postgresql-dev

RUN git clone -b 2.3.2 https://github.com/pgRouting/osm2pgrouting.git
WORKDIR osm2pgrouting

RUN cmake -H. -Bbuild
WORKDIR build/
RUN make
RUN make install

LABEL org.opencontainers.image.created="{{ created }}" \
      org.opencontainers.image.authors="Isaac Boates <iboates@gmail.com>" \
      org.opencontainers.image.url="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.documentation="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.source="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.version="2.3.2" \
      org.opencontainers.image.licenses="GPL-2.0" \
      org.opencontainers.image.title="osm2pgrouting" \
      org.opencontainers.image.description="Easily import OpenStreetMap data into a pgRouting database using osm2pgrouting tool."

ENTRYPOINT ["osm2pgrouting"]

CMD ["-h"]
