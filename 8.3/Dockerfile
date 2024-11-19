ARG PHP_VERSION=8.3
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
FROM php:$PHP_VERSION-fpm-alpine

ARG PORT=9001
ARG PUBLIC_DIR=public

ENV PORT=$PORT
ENV PUBLIC_DIR=$PUBLIC_DIR

ENV REQUIRED_PACKAGES="git make zip curl libpq supervisor gettext acl fcgi python3 ca-certificates pcre rabbitmq-c icu libavif libwebp libpng freetype libjpeg-turbo libacl libheif libde265 imagemagick imagemagick-dev imagemagick-libs jpegoptim optipng pngquant gifsicle linux-headers file nodejs npm ffmpeg"
ENV EXTENSIONS="redis apcu ast maxminddb amqp zip pdo_mysql pdo_pgsql bcmath opcache gettext intl exif pcntl sysvmsg sysvsem sysvshm xsl uuid igbinary bz2 gmp mongodb sockets imagick gd"

ENV DOCKER=true
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 COMPOSER_CACHE_DIR="/tmp"

WORKDIR /app

# Copying manifest files to host
COPY ./8.3-kazza/manifest /

# Caddy
COPY --from=builder /usr/bin/caddy /usr/local/bin/caddy

# Composer install
COPY --from=composer/composer:2-bin /composer /usr/bin/composer

# php extensions installer: https://github.com/mlocati/docker-php-extension-installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions

# Install required packages
RUN apk add --update --no-cache $REQUIRED_PACKAGES

# Install PHP extensions
RUN IPE_ICU_EN_ONLY=1 install-php-extensions $EXTENSIONS

# Update ulimit
RUN ulimit -n 16384
