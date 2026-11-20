#!/bin/bash
# Build phpredis from a pinned upstream commit.
#
# No phpredis release supports PHP 8.6 yet, and install-php-extensions cannot install the
# GitHub source tarball because it lacks the liblzf git submodule. This uses the same
# configure options install-php-extensions uses for redis. Run it after igbinary is installed.
#
# Usage: install-phpredis.sh <git-ref>
set -euxo pipefail

PHPREDIS_REF="$1"

mapfile -t savedAptMark < <(apt-mark showmanual)

apt-get -y update
apt-get install -y --no-install-recommends liblz4-dev libzstd-dev

git clone --filter=blob:none https://github.com/phpredis/phpredis.git /usr/src/phpredis
cd /usr/src/phpredis
git checkout "$PHPREDIS_REF"
git submodule update --init --depth 1

phpize
./configure \
    --enable-redis-igbinary \
    --enable-redis-lzf \
    --enable-redis-zstd \
    --enable-redis-msgpack=no \
    --enable-redis-lz4 \
    --with-liblz4
make -j"$(nproc)"
make install
strip --strip-unneeded "$(php-config --extension-dir)/redis.so"
docker-php-ext-enable redis

# Remove build dependencies, keeping the runtime libraries the extension links against.
cd /
apt-mark auto '.*' > /dev/null
apt-mark manual "${savedAptMark[@]}" > /dev/null
find "$(php-config --extension-dir)" -name '*.so' -exec ldd '{}' ';' 2>/dev/null \
    | awk '/=> \/(usr\/)?lib\// { print $(NF-1) }' \
    | xargs -r readlink -f \
    | sort -u \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | xargs -r apt-mark manual
apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false
rm -rf /var/lib/apt/lists/* /usr/src/phpredis

php --ri redis
