ARG PHP_VERSION=8.4
ARG CADDY_VERSION=2

# -----------------------------------------------------
# Caddy Install
# -----------------------------------------------------
FROM caddy:$CADDY_VERSION-builder AS builder
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH xcaddy build

# -----------------------------------------------------
# App Itself
# -----------------------------------------------------
FROM php:$PHP_VERSION-fpm

ARG PORT=9001
ARG PUBLIC_DIR=public

ENV PORT=$PORT
ENV PUBLIC_DIR=$PUBLIC_DIR
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"
ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"

ENV EXTENSIONS="amqp apcu ast bcmath exif ffi gd gettext gmp igbinary intl maxminddb mongodb opcache pcntl pdo_mysql pdo_pgsql redis sockets sysvmsg sysvsem sysvshm uuid xsl zip"

ENV BUILD_DEPS="make git autoconf wget"

# Caddy
COPY --from=builder /usr/bin/caddy /usr/local/bin/caddy

# Composer install
COPY --from=composer/composer:2-bin /composer /usr/bin/composer

WORKDIR /app

# Copying manifest files to host
COPY ./8.4/manifest /

# php extensions installer: https://github.com/mlocati/docker-php-extension-installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends ${BUILD_DEPS} \
        acl \
        file \
        gettext \
        gifsicle \
        jpegoptim \
        optipng \
        pngquant \
        procps \
        supervisor \
        unzip \
        webp \
        zip \
	&& rm -rf /var/lib/apt/lists/*

####################################################################################################
# Install latest imagemagick
# @see https://github.com/dooman87/imagemagick-docker/blob/main/Dockerfile.bookworm
####################################################################################################
ARG IM_VERSION=7.1.1-43
ARG LIB_HEIF_VERSION=1.19.5
ARG LIB_AOM_VERSION=3.11.0
ARG LIB_WEBP_VERSION=1.4.0
ARG LIBJXL_VERSION=0.11.0

RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get remove --autoremove --purge -y imagemagick && \
    apt-get install -y --no-install-recommends pkg-config cmake clang libomp-dev ca-certificates automake \
    # libaom
    yasm \
    # libheif
    libde265-0 libde265-dev libjpeg62-turbo libjpeg62-turbo-dev x265 libx265-dev libtool \
    # libwebp
    libsdl1.2-dev libgif-dev \
    # libjxl
    libbrotli-dev \
    # IM
    libpng16-16 libpng-dev libjpeg62-turbo libjpeg62-turbo-dev libgomp1 ghostscript libxml2-dev libxml2-utils libtiff-dev libfontconfig1-dev libfreetype6-dev fonts-dejavu liblcms2-2 liblcms2-dev libtcmalloc-minimal4 \
    # Install manually to prevent deleting with -dev packages
    libxext6 libbrotli1 && \
    export CC=clang CXX=clang++ && \
#    # Building libwebp
    git clone -b v${LIB_WEBP_VERSION} --depth 1 https://chromium.googlesource.com/webm/libwebp && \
    cd libwebp && \
    mkdir build && cd build && cmake -DBUILD_SHARED_LIBS=ON ../ && make && make install && \
    ldconfig /usr/local/lib && \
    cd ../../ && rm -rf libwebp && \
    # Building libjxl
    git clone -b v${LIBJXL_VERSION} https://github.com/libjxl/libjxl.git --depth 1 --recursive --shallow-submodules && \
    cd libjxl && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DJPEGXL_FORCE_SYSTEM_BROTLI=ON -DJPEGXL_FORCE_SYSTEM_LCMS2=ON .. && \
    cmake --build . -- -j$(nproc) && \
    cmake --install . && \
    cd ../../ && \
    rm -rf libjxl && \
    ldconfig /usr/local/lib && \
    # Building libaom
    git clone -b v${LIB_AOM_VERSION} --depth 1 https://aomedia.googlesource.com/aom && \
    mkdir build_aom && \
    cd build_aom && \
    cmake ../aom/ -DENABLE_TESTS=0 -DBUILD_SHARED_LIBS=1 && make && make install && \
    ldconfig /usr/local/lib && \
    cd .. && \
    rm -rf aom && \
    rm -rf build_aom && \
    # Building libheif
    git clone -b v${LIB_HEIF_VERSION} --depth 1 https://github.com/strukturag/libheif.git && \
    cd libheif/ && \
    mkdir build && cd build && cmake --preset=release .. && make && make install && cd ../../ && \
    ldconfig /usr/local/lib && \
    rm -rf libheif && \
    # Building ImageMagick
    git clone -b ${IM_VERSION} --depth 1 https://github.com/ImageMagick/ImageMagick.git && \
    cd ImageMagick && \
    LIBS="-lsharpyuv" ./configure --without-magick-plus-plus --disable-docs --disable-static --with-tiff --with-jxl --with-tcmalloc && \
    make && make install && \
    ldconfig /usr/local/lib && \
    apt-get remove --autoremove --purge -y cmake clang clang-14 yasm automake pkg-config libpng-dev libjpeg62-turbo-dev libde265-dev libx265-dev libxml2-dev libtiff-dev libfontconfig1-dev libfreetype6-dev liblcms2-dev libsdl1.2-dev libgif-dev libbrotli-dev && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /ImageMagick

####################################################################################################
# Install latest libvips
# @see https://github.com/dooman87/imagemagick-docker/blob/main/Dockerfile.bookworm
####################################################################################################
ARG VIPS_VERSION=8.16.0
ENV VIPS_BUILD_DEPS="build-essential ninja-build meson pkg-config"
ENV VIPS_DEPS="libvips-dev"
ENV LD_LIBRARY_PATH="/usr/local/lib"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"

RUN apt-get -y update && \
	apt-get -y upgrade && \
	apt-get remove --autoremove --purge -y libvips && \
    apt-get install -y --no-install-recommends ${VIPS_BUILD_DEPS} ${VIPS_DEPS} && \
    cd /usr/local/src && wget https://github.com/libvips/libvips/releases/download/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.xz && \
    xz -d -v vips-${VIPS_VERSION}.tar.xz && tar xf vips-${VIPS_VERSION}.tar && \
    cd vips-${VIPS_VERSION} && \
    meson setup build --libdir lib && meson compile -C build && meson install -C build && \
    apt-get remove --autoremove --purge -y ${VIPS_BUILD_DEPS} && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/local/src/vips-*

# Install PHP extensions
RUN set -eux; install-php-extensions $EXTENSIONS

# Enable Imagemagick extension
RUN apt-get update && apt-get install -y --no-install-recommends libmagickwand-dev && \
    pecl install imagick && \
    docker-php-ext-enable imagick && \
    rm -rf /var/lib/apt/lists/*

# Update ulimit
RUN ulimit -n 16384
