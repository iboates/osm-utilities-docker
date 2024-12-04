FROM docker.io/python:3-alpine AS builder

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
    luajit-dev \
    potrace-dev \
    opencv-dev

RUN git clone -b 2.0.1 https://github.com/osm2pgsql-dev/osm2pgsql.git
WORKDIR osm2pgsql

RUN mkdir build
WORKDIR build
RUN cmake -D WITH_LUAJIT=ON ..
RUN make
RUN make install

RUN apk add --no-cache python3 py3-pip
RUN python3 -m venv /venv
ENV PATH="/venv/bin:$PATH"
RUN pip install osmium psycopg2


FROM alpine/git:v2.45.2 AS themepark-downloader

# Clone osm2pgsql-themepark repo
ARG REPO_URL=https://github.com/osm2pgsql-dev/osm2pgsql-themepark.git
ARG COMMIT_HASH=b26afa5
ARG TARGET_PATH_REPO=/osm2pgsql-themepark
RUN git clone ${REPO_URL} ${TARGET_PATH_REPO} && \
    cd ${TARGET_PATH_REPO} && \
    git checkout ${COMMIT_HASH} && \
    rm -rf .git

ENV LUA_PATH /osm2pgsql-themepark/lua/?.lua;;


FROM docker.io/python:3-alpine

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
    lz4-libs

COPY --from=builder /usr/local/bin/osm2pgsql* /usr/local/bin/
COPY --from=builder /osm2pgsql/scripts/osm2pgsql-replication /usr/local/bin/
COPY --from=builder /usr/local/share/osm2pgsql/* /usr/local/share/osm2pgsql/

COPY --from=builder /venv /venv
ENV PATH="/venv/bin:$PATH"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN sed -i -e 's/\r$//' entrypoint.sh

# osm2pgsql-themepark
ENV LUA_PATH /osm2pgsql-themepark/lua/?.lua;;
COPY --from=themepark-downloader /osm2pgsql-themepark /osm2pgsql-themepark

COPY LICENSE LICENSE

# Fix CVE vulns
RUN pip install --upgrade setuptools certifi

LABEL org.opencontainers.image.created="{{ created }}" \
      org.opencontainers.image.authors="Isaac Boates <iboates@gmail.com>" \
      org.opencontainers.image.url="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.documentation="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.source="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.version="2.0.1" \
      org.opencontainers.image.licenses="GPL-2.0" \
      org.opencontainers.image.title="osm2pgsql" \
      org.opencontainers.image.description="osm2pgsql is a tool for loading OpenStreetMap data into a PostgreSQL / PostGIS database suitable for applications like rendering into a map, geocoding with Nominatim, or general analysis."

ENTRYPOINT ["/entrypoint.sh"]
