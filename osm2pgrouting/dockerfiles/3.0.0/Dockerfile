FROM docker.io/alpine:latest

# Packages inherited from the base image are frozen at whatever version it
# shipped -- `apk add` installs new packages but never upgrades existing ones.
# Upgrade first so base-image packages pick up published security fixes.
RUN apk --no-cache upgrade

RUN apk add --no-cache \
    git \
    expat \
    expat-dev \
    boost-dev \
    boost-program_options \
    postgresql-dev \
    cmake \
    make \
    g++

# libqxx is not available on apk, must build from source
# Pin libpqxx: its default branch is now 8.x, whose API osm2pgrouting does
# not build against.
RUN git clone -b 7.10.7 https://github.com/jtv/libpqxx.git
WORKDIR libpqxx
RUN cmake . -DCMAKE_INSTALL_PREFIX=/usr -DSKIP_BUILD_TEST=ON
RUN make
RUN make install
WORKDIR ..

RUN git clone -b v3.0.0 https://github.com/pgRouting/osm2pgrouting.git
WORKDIR osm2pgrouting

# osm2pgrouting declares a CMake minimum below 3.5, which CMake 4 rejects.
RUN cmake -H. -Bbuild -DCMAKE_POLICY_VERSION_MINIMUM=3.5
WORKDIR build/
RUN make
RUN make install

# expected location of default map config XML files
RUN mkdir /usr/share/osm2pgrouting
RUN cp ../*.xml /usr/share/osm2pgrouting

LABEL org.opencontainers.image.created="{{ created }}" \
      org.opencontainers.image.authors="Isaac Boates <iboates@gmail.com>" \
      org.opencontainers.image.url="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.documentation="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.source="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.version="3.0.0" \
      org.opencontainers.image.licenses="GPL-2.0" \
      org.opencontainers.image.title="osm2pgrouting" \
      org.opencontainers.image.description="Easily import OpenStreetMap data into a pgRouting database using osm2pgrouting tool."

ENTRYPOINT ["osm2pgrouting"]

CMD ["--help"]
