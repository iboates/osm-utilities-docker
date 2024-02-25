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
    luajit-dev \
    potrace-dev \
    opencv-dev

RUN git clone -b master https://github.com/osm2pgsql-dev/osm2pgsql.git
WORKDIR osm2pgsql

RUN mkdir build
WORKDIR build
RUN cmake -D WITH_LUAJIT=ON ..
RUN make
# RUN make man
RUN make install
RUN make install-gen


# FROM alpine:latest
#
# # Set the working directory
# WORKDIR /app
#
# # Copy only the built artifacts and necessary files from the builder stage
# COPY --from=builder /usr/local/bin/osm2pgsql /usr/local/bin/osm2pgsql
# COPY --from=builder /usr/local/share/osm2pgsql /usr/local/bin
#
# RUN apk update
# RUN apk --update-cache add \
# # START PUNCHOUT
# #    ca-certificates \
# #    brotli-libs \
# #    c-ares \
# #    libunistring \
# #    libidn2 \
# #    nghttp2-libs \
# #    libcurl \
#     libexpat \
# ##    pcre2 \
#     git \
# #    libacl \
#     libbz2 \
# #    lz4-libs \
#     xz-libs \
# #    zstd-libs \
#     libarchive \
# #    libgcc \
#     rhash-libs \
# #    libstdc++ \
#     libuv \
# #    cmake \
#     make \
# #    libstdc++-dev \
#     jansson \
# #    binutils \
#     libgomp \
# #    libatomic \
#     gmp \
# #    isl26 \
#     mpfr4 \
# #    mpc1 \
#     gcc \
# #    musl-dev \
#     libc-dev \
# #    g++ \
#     pkgconf \
# #    nlohmann-json \
#     libpq \
#     openssl-dev \
#     libpq-dev \
#     libecpg \
#     libecpg-dev \
#     fortify-headers \
#     clang15-headers \
#     libffi \
#     libxml2 \
#     llvm15-libs \
#     clang15-libs \
#     clang15-libclang \
#     clang15 \
#     icu-data-full \
#     icu-libs \
#     icu \
#     icu-dev \
#     llvm15 \
#     lz4-dev \
#     zstd \
#     zstd-dev \
#     postgresql16-dev \
#     boost1.82-atomic \
#     boost1.82-chrono \
#     boost1.82-container \
#     boost1.82-context \
#     boost1.82-contract \
#     boost1.82-coroutine \
#     boost1.82-date_time \
#     boost1.82-fiber \
#     boost1.82-filesystem \
#     boost1.82-graph \
#     boost1.82-iostreams \
#     boost1.82-thread \
#     boost1.82-locale \
#     boost1.82-log \
#     boost1.82-log_setup \
#     boost1.82-math \
#     boost1.82-prg_exec_monitor \
#     boost1.82-program_options \
#     gdbm \
#     mpdecimal \
#     ncurses-terminfo-base \
#     libncursesw \
#     libpanelw \
#     readline \
#     sqlite-libs \
#     python3 \
#     python3-pycache-pyc0 \
#     pyc \
#     python3-pyc \
#     boost1.82-python3 \
#     boost1.82-random \
#     boost1.82-regex \
#     boost1.82-serialization \
#     boost1.82-stacktrace_basic \
#     boost1.82-stacktrace_noop \
#     boost1.82-system \
#     boost1.82-timer \
#     boost1.82-type_erasure \
#     boost1.82-unit_test_framework \
#     boost1.82-url \
#     boost1.82-wave \
#     boost1.82-wserialization \
#     boost1.82-json \
#     boost1.82-nowide \
#     boost1.82-libs \
#     boost1.82 \
#     linux-headers \
#     bzip2-dev \
#     xz \
#     xz-dev \
#     zlib-dev \
#     boost1.82-dev \
#     boost-dev \
#     expat \
#     expat-dev \
#     brotli \
#     brotli-dev \
#     c-ares-dev \
#     libidn2-dev \
#     nghttp2-dev \
#     curl-dev \
#     libjpeg-turbo \
#     libsharpyuv \
#     libwebp \
#     tiff \
#     libtiffxx \
#     libturbojpeg \
#     libjpeg-turbo-dev \
#     libwebpdecoder \
#     libwebpdemux \
#     libwebpmux \
#     libwebp-dev \
#     tiff-dev \
#     sqlite \
#     sqlite-dev \
#     proj \
#     proj-dev \
#     linenoise \
#     lua5.3-libs \
#     lua5.3 \
#     lua5.3-dev \
#     luajit \
#     luajit-dev \
#     potrace \
#     potrace-dev \
#     libquadmath \
#     libgfortran \
#     gfortran \
#     openblas \
#     liblapack \
#     liblapacke \
#     openblas-ilp64 \
#     openblas-dev \
#     eigen-dev \
#     libSvtAv1Enc \
#     aom-libs \
#     libxau \
#     libmd \
#     libbsd \
#     libxdmcp \
#     libxcb \
#     libx11 \
#     hwdata-pci \
#     libpciaccess \
#     libdrm \
#     libxext \
#     libxfixes \
#     wayland-libs-client \
#     libva \
#     libvdpau \
#     onevpl-libs \
#     ffmpeg-libavutil \
#     libdav1d \
#     libhwy \
#     lcms2 \
#     libjxl \
#     lame-libs \
#     opus \
#     rav1e-libs \
#     soxr \
#     ffmpeg-libswresample \
#     libogg \
#     libtheora \
#     libvorbis \
#     libvpx \
#     x264-libs \
#     numactl \
#     x265-libs \
#     xvidcore \
#     ffmpeg-libavcodec \
#     sdl2 \
#     alsa-lib \
#     libpng \
#     freetype \
#     fontconfig \
#     fribidi \
#     libintl \
#     libblkid \
#     libmount \
#     glib \
#     graphite2 \
#     harfbuzz \
#     libunibreak \
#     libass \
#     libbluray \
#     mpg123-libs \
#     libopenmpt \
#     cjson \
#     mbedtls \
#     librist \
#     libsrt \
#     libssh \
#     libsodium \
#     libzmq \
#     ffmpeg-libavformat \
#     serd-libs \
#     zix-libs \
#     sord-libs \
#     sratom \
#     lilv-libs \
#     glslang-libs \
#     libdovi \
#     spirv-tools \
#     shaderc \
#     vulkan-loader \
#     libplacebo \
#     ffmpeg-libpostproc \
#     ffmpeg-libswscale \
#     vidstab \
#     zimg \
#     ffmpeg-libavfilter \
#     libasyncns \
#     dbus-libs \
#     libltdl \
#     orc \
#     libflac \
#     libsndfile \
#     speexdsp \
#     tdb-libs \
#     libpulse \
#     v4l-utils-libs \
#     ffmpeg-libavdevice \
#     ffmpeg-dev \
#     libpng-dev \
#     freetype-dev \
#     libuuid \
#     libfdisk \
#     libsmartcols \
#     util-linux-dev \
#     libice \
#     libsm \
#     libxt \
#     libxmu \
#     xorgproto \
#     libxau-dev \
#     xcb-proto \
#     xcb-proto-pyc \
#     libxdmcp-dev \
#     libxcb-dev \
#     xtrans \
#     libx11-dev \
#     libxext-dev \
#     libice-dev \
#     libsm-dev \
#     libxt-dev \
#     libxmu-dev \
#     libxi \
#     libxfixes-dev \
#     libxi-dev \
#     libpciaccess-dev \
#     libdrm-dev \
#     libxdamage \
#     libxdamage-dev \
#     libxshmfence \
#     libxshmfence-dev \
#     mesa \
#     wayland-libs-server \
#     mesa-gbm \
#     mesa-glapi \
#     mesa-egl \
#     libxxf86vm \
#     mesa-gl \
#     mesa-gles \
#     llvm17-libs \
#     mesa-osmesa \
#     clang17-headers \
#     libclc \
#     spirv-llvm-translator-libs \
#     clang17-libs \
#     libelf \
#     mesa-rusticl \
#     mesa-xatracker \
#     libxxf86vm-dev \
#     mesa-dev \
#     glu \
#     glu-dev \
#     glew \
#     glew-dev \
#     libffi-dev \
#     wayland-libs-cursor \
#     wayland-libs-egl \
#     wayland-dev \
#     libxv \
#     libxrender \
#     pixman \
#     cairo \
#     cdparanoia-libs \
#     graphene \
#     libcap2 \
#     gstreamer \
#     libxft \
#     pango \
#     gst-plugins-base \
#     libxml2-utils \
#     docbook-xml \
#     libgpg-error \
#     libgcrypt \
#     libxslt \
#     docbook-xsl \
#     gettext-asprintf \
#     gettext-libs \
#     gettext-envsubst \
#     gettext \
#     gettext-dev \
#     bsd-compat-headers \
#     libformw \
#     libmenuw \
#     libncurses++ \
#     ncurses-dev \
#     libedit \
#     libedit-dev \
#     libpcre2-16 \
#     libpcre2-32 \
#     pcre2-dev \
#     glib-dev \
#     libxml2-dev \
#     gstreamer-dev \
#     orc-compiler \
#     orc-dev \
#     gst-plugins-base-dev \
#     harfbuzz-cairo \
#     harfbuzz-gobject \
#     harfbuzz-icu \
#     harfbuzz-subset \
#     cairo-tools \
#     fontconfig-dev \
#     libxrender-dev \
#     pixman-dev \
#     util-macros \
#     xcb-util \
#     xcb-util-dev \
#     cairo-gobject \
#     cairo-dev \
#     graphite2-dev \
#     harfbuzz-dev \
#     libsz \
#     hdf5 \
#     hdf5-cpp \
#     hdf5-fortran \
#     hdf5-hl \
#     hdf5-hl-cpp \
#     hdf5-hl-fortran \
#     hdf5-dev \
#     libusb \
#     libusb-dev \
#     libraw1394 \
#     libraw1394-dev \
#     libdc1394 \
#     libdc1394-dev \
#     libexif \
#     libexif-dev \
#     libgphoto2 \
#     libgphoto2-dev \
#     libva-dev \
#     libva-glx \
#     libva-glx-dev \
#     eudev-libs \
#     hwloc \
#     onetbb \
#     onetbb-dev \
#     openexr-libiex \
#     openexr-libilmthread \
#     imath \
#     openexr-libopenexr \
#     openexr-libopenexrcore \
#     openexr-libopenexrutil \
#     imath-dev \
#     openexr-dev \
#     openjpeg \
#     openjpeg-tools \
#     openjpeg-dev \
#     py3-parsing \
#     py3-parsing-pyc \
#     py3-packaging \
#     py3-packaging-pyc \
#     py3-setuptools \
#     py3-setuptools-pyc \
#     libb2 \
#     double-conversion \
#     duktape \
#     libproxy \
#     qt6-qtbase \
#     mariadb-connector-c \
#     qt6-qtbase-mysql \
#     unixodbc \
#     qt6-qtbase-odbc \
#     qt6-qtbase-postgresql \
#     qt6-qtbase-sqlite \
#     hicolor-icon-theme \
#     libmagic \
#     file \
#     xset \
#     xprop \
#     xdg-utils \
#     avahi-libs \
#     nettle \
#     libtasn1 \
#     p11-kit \
#     gnutls \
#     cups-libs \
#     shared-mime-info \
#     gdk-pixbuf \
#     gtk-update-icon-cache \
#     libxcomposite \
#     libxcursor \
#     libxinerama \
#     libxrandr \
#     libatk-1.0 \
#     libxtst \
#     at-spi2-core \
#     libatk-bridge-2.0 \
#     libepoxy \
#     xkeyboard-config \
#     libxkbcommon \
#     gtk+3.0 \
#     libevdev \
#     mtdev \
#     libinput-libs \
#     tslib \
#     xcb-util-image \
#     xcb-util-renderutil \
#     xcb-util-cursor \
#     xcb-util-wm \
#     xcb-util-keysyms \
#     libxkbcommon-x11 \
#     qt6-qtbase-x11 \
#     qt6-qtdeclarative \
#     qt6-qtwayland \
#     libgpg-error-dev \
#     libgcrypt-dev \
#     gnutls-c++ \
#     libgmpxx \
#     gmp-dev \
#     nettle-dev \
#     libtasn1-progs \
#     libtasn1-dev \
#     p11-kit-dev \
#     gnutls-dev \
#     gdbm-tools \
#     gdbm-dev \
#     avahi-compat-howl \
#     avahi-compat-libdns_sd \
#     avahi-glib \
#     libdaemon \
#     libevent \
#     avahi \
#     avahi-dev \
#     cups-dev \
#     dbus-dev \
#     double-conversion-dev \
#     udev-init-scripts \
#     kmod-libs \
#     eudev \
#     libinput-udev \
#     eudev-dev \
#     gdk-pixbuf-dev \
#     libepoxy-dev \
#     libxinerama-dev \
#     libxkbcommon-dev \
#     wayland-protocols \
#     libxtst-dev \
#     at-spi2-core-dev \
#     fribidi-dev \
#     pango-tools \
#     libxft-dev \
#     pango-dev \
#     libxcomposite-dev \
#     libxcursor-dev \
#     libxrandr-dev \
#     gtk+3.0-dev \
#     libb2-dev \
#     libinput-dev \
#     libproxy-dev \
#     fmt \
#     fmt-dev \
#     mariadb-connector-c-dev \
#     mariadb-common \
#     libaio \
#     mariadb-embedded \
#     mariadb-dev \
#     tslib-dev \
#     unixodbc-dev \
#     vulkan-headers \
#     vulkan-loader-dev \
#     xcb-util-image-dev \
#     xcb-util-renderutil-dev \
#     xcb-util-cursor-dev \
#     xcb-util-keysyms-dev \
#     xcb-util-wm-dev \
#     qt6-qtbase-dev \
#     doxygen \
#     lerc \
#     sfcgal \
#     libaec \
#     arpack \
#     superlu \
#     armadillo \
#     blosc \
#     brunsli-libs \
#     libdeflate \
#     geos \
#     giflib \
#     gnu-libiconv-libs \
#     json-c \
#     qhull \
#     libgeotiff \
#     minizip \
#     librttopo \
#     libspatialite \
#     librasterlite2 \
#     xerces-c \
#     gdal \
#     gdal-dev \
#     jpeg-dev \
#     libaec-dev \
#     netcdf \
#     netcdf-dev \
#     openmpi \
#     openmpi-dev \
#     pdal \
#     fgt \
#     cpd \
#     openscenegraph \
#     aws-c-common \
#     aws-c-cal \
#     s2n-tls \
#     aws-c-io \
#     aws-checksums \
#     aws-c-event-stream \
#     aws-c-compression \
#     aws-c-http \
#     aws-c-sdkutils \
#     aws-c-auth \
#     aws-c-mqtt \
#     aws-c-s3 \
#     aws-crt-cpp \
#     aws-sdk-cpp-core \
#     aws-sdk-cpp-cognito-identity \
#     aws-sdk-cpp-sts \
#     aws-sdk-cpp-identity-management \
#     aws-sdk-cpp-s3 \
#     libucontext \
#     capnproto \
#     abseil-cpp-raw-logging-internal \
#     abseil-cpp-strings-internal \
#     abseil-cpp-strings \
#     abseil-cpp-int128 \
#     abseil-cpp-time-zone \
#     abseil-cpp-time \
#     google-cloud-cpp \
#     abseil-cpp-crc-internal \
#     abseil-cpp-crc32c \
#     abseil-cpp-str-format-internal \
#     crc32c \
#     google-cloud-cpp-rest-internal \
#     google-cloud-cpp-storage \
#     spdlog \
#     tiledb \
#     libpdal-plugins \
#     pdal-dev \
#     qt5-qtbase \
#     qt5-qtbase-sqlite \
#     qt5-qtbase-odbc \
#     qt5-qtbase-postgresql \
#     qt5-qtbase-mysql \
#     freetds \
#     qt5-qtbase-tds \
#     qt5-qtbase-x11 \
#     qt5-qtdeclarative \
#     qt5-qtwayland \
#     perl \
#     perl-error \
#     perl-git \
#     git-perl \
#     qt5-qtbase-dev \
#     qt5-qttools \
#     libqt5designer \
#     libqt5designercomponents \
#     libqt5help \
#     clang17-libclang \
#     qt5-qttools-dev \
#     qt5-qtx11extras \
#     qt5-qtx11extras-dev \
#     tzdata \
#     tcl \
#     tcl-dev \
#     tk \
#     tk-dev \
#     vtk \
#     vtk-dev \
#     libopencv_core \
#     libopencv_flann \
#     libopencv_imgproc \
#     libopencv_features2d \
#     libopencv_calib3d \
#     libopencv_dnn \
#     libopencv_objdetect \
#     libopencv_aruco \
#     libopencv_face \
#     libopencv_highgui \
#     libopencv_imgcodecs \
#     libopencv_ml \
#     libopencv_video \
#     libopencv_ximgproc \
#     libopencv_optflow \
#     libopencv_photo \
#     libopencv_plot \
#     libopencv_shape \
#     libopencv_stitching \
#     libopencv_videoio \
#     libopencv_superres \
#     libopencv_tracking \
#     libopencv_videostab \
#     opencv-dev #PUNCHOUT
# # END PUNCHOUT

LABEL org.opencontainers.image.created="asdasfes" \
      org.opencontainers.image.authors="Isaac Boates <iboates@gmail.com>" \
      org.opencontainers.image.url="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.documentation="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.source="https://github.com/iboates/osm2pgsql-docker" \
      org.opencontainers.image.version="sdfsefsfe" \
      org.opencontainers.image.licenses="GPL-2.0" \
      org.opencontainers.image.title="osm2pgsql" \
      org.opencontainers.image.description="osm2pgsql is a tool for loading OpenStreetMap data into a PostgreSQL / PostGIS database suitable for applications like rendering into a map, geocoding with Nominatim, or general analysis."


ENTRYPOINT ["osm2pgsql"]

CMD ["-h"]
