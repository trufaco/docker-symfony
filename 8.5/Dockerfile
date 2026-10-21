ARG PHP_VERSION=8.5.12
ARG CADDY_VERSION=2

FROM caddy:$CADDY_VERSION AS caddy

FROM php:$PHP_VERSION-fpm-trixie

ARG PORT=9001
ARG PUBLIC_DIR=public

ENV PORT=$PORT
ENV PUBLIC_DIR=$PUBLIC_DIR
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"
ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"

ENV EXTENSIONS="amqp apcu ast bcmath exif ffi gd gettext gmp igbinary imagick intl maxminddb mongodb opcache pcntl pdo_mysql pdo_pgsql redis sockets sysvmsg sysvsem sysvshm uuid xsl zip grpc protobuf opentelemetry zstd symfony/php-ext-deepclone@v0.8.9"

WORKDIR /app

# php extensions installer: https://github.com/mlocati/docker-php-extension-installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        acl \
        ca-certificates \
        curl \
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
        libheif-plugin-x265 \
	&& rm -rf /var/lib/apt/lists/*

# Install nodeJS
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install latest libvips
# @see https://github.com/dooman87/imagemagick-docker/blob/main/Dockerfile.bookworm
ARG VIPS_VERSION=8.18.6
ENV LD_LIBRARY_PATH="/usr/local/lib"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"

COPY --chmod=755 scripts/install-libvips.sh /tmp/install-libvips.sh
RUN /tmp/install-libvips.sh ${VIPS_VERSION} && rm /tmp/install-libvips.sh

# Install PHP extensions
RUN set -eux; install-php-extensions $EXTENSIONS

# Keep frequently changing binaries after dependency installation.
COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
COPY --from=composer/composer:2-bin /composer /usr/bin/composer

# Copying manifest files to host
COPY ./8.5/manifest /

# Copy Imagemagick policy
RUN mv /etc/ImageMagick-7/IM7-policy.xml /etc/ImageMagick-7/policy.xml
