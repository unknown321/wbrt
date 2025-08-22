# https://github.com/mmozeiko/docker-mingw-w64/blob/6d4ffdba1435373cd3be700fb114b9485543e381

FROM ubuntu:24.04

WORKDIR /mnt

ENV MINGW=/mingw

ARG PKG_CONFIG_VERSION=0.29.2
ARG CMAKE_VERSION=4.1.0
ARG BINUTILS_VERSION=2.45
ARG MINGW_VERSION=13.0.0
ARG GCC_VERSION=15.2.0
ARG GNU_MIRROR=https://mirror.checkdomain.de

SHELL [ "/bin/bash", "-c" ]

RUN set -ex \
    \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade --no-install-recommends -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        ca-certificates \
        gcc \
        g++ \
        zlib1g-dev \
        libssl-dev \
        libgmp-dev \
        libmpfr-dev \
        libmpc-dev \
        libisl-dev \
        libssl3 \
        libgmp10 \
        libmpfr6 \
        libmpc3 \
        libisl23 \
        xz-utils \
        ninja-build \
        texinfo \
        meson \
        gnupg \
        bzip2 \
        patch \
        gperf \
        bison \
        file \
        flex \
        make \
        yasm \
        wget \
        zip \
        git \
        libudev-dev \
        libudev1 \
    \
    && wget -q https://pkg-config.freedesktop.org/releases/pkg-config-${PKG_CONFIG_VERSION}.tar.gz -O - | tar -xz \
    && wget -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz -O - | tar -xz \
    && wget -q ${GNU_MIRROR}/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz -O - | tar -xJ \
    && wget -q https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v${MINGW_VERSION}.tar.bz2 -O - | tar -xj \
    && wget -q ${GNU_MIRROR}/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz -O - | tar -xJ \
    \
    && mkdir -p ${MINGW}/include ${MINGW}/lib/pkgconfig \
    && chmod 0777 -R /mnt ${MINGW} \
    \
    && cd pkg-config-${PKG_CONFIG_VERSION} \
    && ./configure \
        --prefix=/usr/local \
        --with-pc-path=${MINGW}/lib/pkgconfig \
        --with-internal-glib \
        --disable-shared \
        --disable-nls \
    && make -j`nproc` \
    && make install \
    && cd .. \
    \
    && cd cmake-${CMAKE_VERSION} \
    && ./configure \
        --prefix=/usr/local \
        --parallel=`nproc` \
    && make -j`nproc` \
    && make install \
    && cd .. \
    \
    && cd binutils-${BINUTILS_VERSION} \
    && ./configure \
        --prefix=/usr/local \
        --target=x86_64-w64-mingw32 \
        --disable-shared \
        --enable-static \
        --disable-lto \
        --disable-plugins \
        --disable-multilib \
        --disable-nls \
        --disable-werror \
        --with-system-zlib \
    && make -j`nproc` \
    && make install \
    && cd .. \
    \
    && mkdir mingw-w64 \
    && cd mingw-w64 \
    && ../mingw-w64-v${MINGW_VERSION}/mingw-w64-headers/configure \
        --prefix=/usr/local/x86_64-w64-mingw32 \
        --host=x86_64-w64-mingw32 \
        --enable-sdk=all \
    && make install \
    && cd .. \
    \
    && mkdir gcc \
    && cd gcc \
    && ../gcc-${GCC_VERSION}/configure \
        --prefix=/usr/local \
        --target=x86_64-w64-mingw32 \
        --enable-languages=c,c++ \
        --disable-shared \
        --enable-static \
        --enable-threads=posix \
        --with-system-zlib \
        --enable-libgomp \
        --enable-libatomic \
        --enable-graphite \
        --disable-libstdcxx-pch \
        --disable-libstdcxx-debug \
        --disable-multilib \
        --disable-lto \
        --disable-nls \
        --disable-werror \
    && make -j`nproc` all-gcc \
    && make install-gcc \
    && cd .. \
    \
    && cd mingw-w64 \
    && ../mingw-w64-v${MINGW_VERSION}/mingw-w64-crt/configure \
        --prefix=/usr/local/x86_64-w64-mingw32 \
        --host=x86_64-w64-mingw32 \
        --enable-wildcard \
        --disable-lib32 \
        --enable-lib64 \
    && (make || make || make || make) \
    && make install \
    && cd .. \
    \
    && cd mingw-w64 \
    && ../mingw-w64-v${MINGW_VERSION}/mingw-w64-libraries/winpthreads/configure \
        --prefix=/usr/local/x86_64-w64-mingw32 \
        --host=x86_64-w64-mingw32 \
        --enable-static \
        --disable-shared \
    && make -j`nproc` \
    && make install \
    && cd .. \
    \
    && cd gcc \
    && make -j`nproc` \
    && make install \
    && cd .. \
    \
    && rm -r pkg-config-${PKG_CONFIG_VERSION} \
    && rm -r cmake-${CMAKE_VERSION} \
    && rm -r binutils-${BINUTILS_VERSION} \
    && rm -r mingw-w64 mingw-w64-v${MINGW_VERSION} \
    && rm -r gcc gcc-${GCC_VERSION} \
    \
    && apt-get remove --purge -y file gcc g++ zlib1g-dev libssl-dev libgmp-dev libmpfr-dev libmpc-dev libisl-dev \
    && apt-get autoremove --purge -y \
    && apt-get clean \
    && apt-get install msitools nsis dos2unix libtool automake build-essential texinfo autoconf -y