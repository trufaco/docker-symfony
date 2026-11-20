ARG PHP_VERSION=8.6.0
ARG CADDY_VERSION=2

FROM caddy:$CADDY_VERSION AS caddy

FROM php:$PHP_VERSION-fpm-trixie

ARG PORT=9001
ARG PUBLIC_DIR=public

ENV PORT=$PORT
ENV PUBLIC_DIR=$PUBLIC_DIR
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"
ENV PHP_INI_SCAN_DIR=":$PHP_INI_DIR/app.conf.d"

# PHP 8.6 removed internal C APIs (XtOffsetOf, zval_dtor, INI_STR/INT/FLT, ...). Until PECL releases
# support 8.6: apcu (5.1.29 release commit, not on PECL), igbinary and imagick are built from pinned
# upstream commits, amqp from the sctr/php-amqp fork (php-8.6-support branch, upstream PR
# php-amqp/php-amqp#638), redis by scripts/install-phpredis.sh. protobuf and grpc are left out: their
# releases and default branches do not compile on 8.6 yet (open fixes: protocolbuffers/protobuf#31752,
# grpc/grpc#43991).
ENV EXTENSIONS="sctr/php-amqp@7a4318b41915d8957ab207de43783d94db25aa25 krakjoe/apcu@66300e28647c16fef7672a5add532f4262b23a75 ast bcmath exif ffi gd gettext gmp igbinary/igbinary@2b1f5d62e3037b07c2a46499ac32091cdb41fb40 Imagick/imagick@55ed2e9fda264395636a2e27e51f31673f5566ab intl maxminddb mongodb opcache pcntl pdo_mysql pdo_pgsql sockets sysvmsg sysvsem sysvshm uuid xsl zip opentelemetry zstd symfony/php-ext-deepclone@v0.8.12"

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
ARG VIPS_VERSION=8.18.7
ENV LD_LIBRARY_PATH="/usr/local/lib"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"

COPY --chmod=755 scripts/install-libvips.sh /tmp/install-libvips.sh
RUN /tmp/install-libvips.sh ${VIPS_VERSION} && rm /tmp/install-libvips.sh

# Install PHP extensions
RUN set -eux; install-php-extensions $EXTENSIONS

ARG PHPREDIS_REF=623e8db5a39657ba7218ceea81ab8338d248b036
COPY --chmod=755 scripts/install-phpredis.sh /tmp/install-phpredis.sh
RUN /tmp/install-phpredis.sh ${PHPREDIS_REF} && rm /tmp/install-phpredis.sh

# Keep frequently changing binaries after dependency installation.
COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
COPY --from=composer/composer:2-bin /composer /usr/bin/composer

# Copying manifest files to host
COPY ./8.6/manifest /

# Copy Imagemagick policy
RUN mv /etc/ImageMagick-7/IM7-policy.xml /etc/ImageMagick-7/policy.xml
