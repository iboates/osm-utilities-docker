FROM docker.io/alpine:latest as builder

RUN apk --no-cache add \
    git \
    cmake \
    make \
    g++ \
    nlohmann-json \
    libosmium-dev \
    protozero-dev \
    rapidjson-dev \
    boost-dev \
    bzip2-dev \
    zlib-dev \
    lz4-dev \
    expat-dev

RUN git clone -b v1.17.0 https://github.com/osmcode/osmium-tool.git

WORKDIR osmium-tool
RUN mkdir build
WORKDIR build
RUN cmake ..
RUN make
RUN make install

LABEL org.opencontainers.image.created="{{ created }}" \
      org.opencontainers.image.authors="Isaac Boates <iboates@gmail.com>" \
      org.opencontainers.image.url="https://github.com/iboates/osm-utilities-docker/tree/master/osm-utilities-docker" \
      org.opencontainers.image.documentation="https://github.com/iboates/osm-utilities-docker/tree/master/osm-utilities-docker" \
      org.opencontainers.image.source="https://github.com/iboates/osm-utilities-docker/tree/master/osm-utilities-docker" \
      org.opencontainers.image.version="1.17.0" \
      org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.title="osmium" \
      org.opencontainers.image.description="A multipurpose command line tool for working with OpenStreetMap data based on the Osmium library."


ENTRYPOINT ["osmium"]

CMD ["-h"]
