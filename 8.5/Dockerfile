ARG PHP_VERSION=8.5
ARG CADDY_VERSION=2
ARG NODE_VERSION=24

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

ENV EXTENSIONS="amqp apcu ast bcmath exif ffi gd gettext gmp igbinary imagick intl maxminddb mongodb opcache pcntl pdo_mysql pdo_pgsql redis sockets sysvmsg sysvsem sysvshm uuid xsl zip"

ENV BUILD_DEPS="make git autoconf wget"

# Caddy
COPY --from=builder /usr/bin/caddy /usr/local/bin/caddy

# Composer install
COPY --from=composer/composer:2-bin /composer /usr/bin/composer

WORKDIR /app

# Copying manifest files to host
COPY ./8.5/manifest /

# php extensions installer: https://github.com/mlocati/docker-php-extension-installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends ${BUILD_DEPS} \
        acl \
        file \
        gettext \
        procps \
        supervisor \
        unzip \
        zip \
        imagemagick \
        webp \
        gifsicle \
        jpegoptim \
        optipng \
        pngquant \
        ffmpeg \
	&& rm -rf /var/lib/apt/lists/*

# Install nodeJS
RUN ARCH=$(dpkg --print-architecture) && \
       if [ "$ARCH" = "amd64" ]; then ARCH="x64"; fi && \
       curl -fsSL "https://nodejs.org/dist/latest-v${NODE_VERSION}.x/node-v$(curl -fsSL https://nodejs.org/dist/latest-v${NODE_VERSION}.x/SHASUMS256.txt | head -1 | grep -oP 'node-v\K[0-9.]+')-linux-${ARCH}.tar.xz" -o /tmp/node.tar.xz && \
       tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 && \
       rm /tmp/node.tar.xz

####################################################################################################
# Install latest libvips
# @see https://github.com/dooman87/imagemagick-docker/blob/main/Dockerfile.bookworm
####################################################################################################
ARG VIPS_VERSION=8.18.0
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

# Imagick version
RUN php -r 'var_dump(Imagick::getVersion());'

# Imagick formats
RUN php -r 'var_dump(Imagick::queryFormats());'

# Update ulimit
RUN ulimit -n 16384
