#!/bin/bash
set -e

pushd /sources

tar xvf popt-1.19.tar.gz
pushd popt-1.19

./configure --prefix=/usr --disable-static
make
make install

popd
rm -rf popt-1.19

tar xvf mandoc-1.14.6.tar.gz
pushd mandoc-1.14.6

./configure
make mandoc

install -vm755 mandoc   /usr/bin &&
install -vm644 mandoc.1 /usr/share/man/man1

popd
rm -rf mandoc-1.14.6

tar xvf efivar-39.tar.gz
pushd efivar-39

make
make install LIBDIR=/usr/lib

popd
rm -rf efivar-39

tar xvf efibootmgr-18.tar.gz
pushd efibootmgr-18

make EFIDIR=LFS EFI_LOADER=grubx64.efi
make install EFIDIR=LFS

popd
rm -rf efibootmgr-18

tar xvf which-2.21.tar.gz
pushd which-2.21

./configure --prefix=/usr
make
make install

popd
rm -rf which-2.21

tar xvf libpng-1.6.42.tar.xz
pushd libpng-1.6.42

gzip -cd ../libpng-1.6.40-apng.patch.gz | patch -p1
./configure --prefix=/usr --disable-static
make
make install
mkdir -v /usr/share/doc/libpng-1.6.42
cp -v README libpng-manual.txt /usr/share/doc/libpng-1.6.42

popd
rm -rf libpng-1.6.42

tar xvf icu4c-74_2-src.tgz
pushd icu

cd source

./configure --prefix=/usr
make
make install

popd
rm -rf icu

tar xvf freetype-2.13.2.tar.xz
pushd freetype-2.13.2

sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg

sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
    -i include/freetype/config/ftoption.h

./configure --prefix=/usr --enable-freetype-config --disable-static
make
make install

popd
rm -rf freetype-2.13.2

tar xvf libxml2-2.12.5.tar.xz
pushd libxml2-2.12.5

./configure --prefix=/usr           \
            --sysconfdir=/etc       \
            --disable-static        \
            --with-history          \
            --with-icu              \
            PYTHON=/usr/bin/python3 \
            --docdir=/usr/share/doc/libxml2-2.12.5

make
make install

rm -vf /usr/lib/libxml2.la
sed '/libs=/s/xml2.*/xml2"/' -i /usr/bin/xml2-config

popd
rm -rf libxml2-2.12.5

tar xvf nghttp2-1.59.0.tar.xz
pushd nghttp2-1.59.0

./configure --prefix=/usr     \
            --disable-static  \
            --enable-lib-only \
            --docdir=/usr/share/doc/nghttp2-1.59.0

make
make install

popd
rm -rf nghttp2-1.59.0

tar xvf libuv-v1.48.0.tar.gz
pushd libuv-v1.48.0

sh autogen.sh
./configure --prefix=/usr --disable-static
make
make install

popd
rm -rf libuv-v1.48.0

tar xvf libarchive-3.7.2.tar.xz
pushd libarchive-3.7.2

./configure --prefix=/usr --disable-static
make
make install

popd
rm -rf libarchive-3.7.2

tar xvf cmake-3.28.3.tar.gz
pushd cmake-3.28.3

sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake

./bootstrap --prefix=/usr        \
            --system-libs        \
            --mandir=/share/man  \
            --no-system-jsoncpp  \
            --no-system-cppdap   \
            --no-system-librhash \
            --docdir=/share/doc/cmake-3.28.3

make
make install

popd
rm -rf cmake-3.28.3

tar xvf graphite2-1.3.14.tgz
pushd graphite2-1.3.14

sed -i '/cmptest/d' tests/CMakeLists.txt

mkdir build
cd    build

cmake -DCMAKE_INSTALL_PREFIX=/usr ..
make
make install

popd
rm -rf graphite2-1.3.14

tar xvf harfbuzz-8.3.0.tar.xz
pushd harfbuzz-8.3.0

mkdir build
cd    build

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -Dgraphite2=enabled

ninja
ninja install

popd
rm -rf harfbuzz-8.3.0

tar xvf freetype-2.13.2.tar.xz
pushd freetype-2.13.2

sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg

sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
    -i include/freetype/config/ftoption.h

./configure --prefix=/usr --enable-freetype-config --disable-static
make
make install

popd
rm -rf freetype-2.13.2

tar xvf grub-2.12.tar.xz
pushd grub-2.12

mkdir -pv /usr/share/fonts/unifont &&
gunzip -c ../unifont-15.1.04.pcf.gz > /usr/share/fonts/unifont/unifont.pcf

echo depends bli part_gpt > grub-core/extra_deps.lst

./configure --prefix=/usr        \
            --sysconfdir=/etc    \
            --disable-efiemu     \
            --enable-grub-mkfont \
            --with-platform=efi  \
            --target=x86_64      \
            --disable-werror

unset TARGET_CC

make
make install

mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions

popd
rm -rf grub-2.12
