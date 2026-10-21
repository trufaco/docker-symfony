#!/bin/bash
set -euxo pipefail

VIPS_VERSION="${1:-8.18.0}"

mapfile -t savedAptMark < <(apt-mark showmanual)

apt-get -y update
apt-get install -y --no-install-recommends build-essential ninja-build meson wget pkg-config libvips-dev

cd /usr/local/src
wget "https://github.com/libvips/libvips/releases/download/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.xz"
xz -d -v "vips-${VIPS_VERSION}.tar.xz"
tar xf "vips-${VIPS_VERSION}.tar"
cd "vips-${VIPS_VERSION}"

meson setup build --libdir lib --buildtype release
meson compile -C build
meson install -C build
ldconfig

# Preserve existing packages and the runtime libraries used by local binaries,
# including libvips' dynamically loaded modules, before removing build dependencies.
apt-mark auto '.*' > /dev/null
apt-mark manual "${savedAptMark[@]}" > /dev/null
find /usr/local -type f \( -name '*.so*' -o -executable \) -exec ldd '{}' ';' 2>/dev/null \
    | awk '/=> \/(usr\/)?lib\// { print $(NF-1) }' \
    | xargs -r readlink -f \
    | sort -u \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | xargs -r apt-mark manual
apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false
rm -rf /var/lib/apt/lists/*
rm -rf /usr/local/src/vips-*

vips --version
