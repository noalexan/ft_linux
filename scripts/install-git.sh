#!/bin/bash
set -e

pushd /sources

tar xvf make-ca-1.13.tar.xz
pushd make-ca-1.13

make install
install -vdm755 /etc/ssl/local

/usr/sbin/make-ca -g
systemctl enable update-pki.timer

export _PIP_STANDALONE_CERT=/etc/pki/tls/certs/ca-bundle.crt
mkdir -pv /etc/profile.d &&
cat > /etc/profile.d/pythoncerts.sh << "EOF"
# Begin /etc/profile.d/pythoncerts.sh

export _PIP_STANDALONE_CERT=/etc/pki/tls/certs/ca-bundle.crt

# End /etc/profile.d/pythoncerts.sh
EOF

popd
rm -rf make-ca-1.13

tar xvf libunistring-1.1.tar.xz
pushd libunistring-1.1

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/libunistring-1.1

make
make install

popd
rm -rf libunistring-1.1

tar xvf libidn2-2.3.7.tar.gz
pushd libidn2-2.3.7

./configure --prefix=/usr --disable-static
make
make install

popd
rm -rf libidn2-2.3.7

tar xvf libpsl-0.21.5.tar.gz
pushd libpsl-0.21.5

mkdir build
cd    build

meson setup --prefix=/usr --buildtype=release

ninja
ninja install

popd
rm -rf libpsl-0.21.5

tar xvf libtasn1-4.19.0.tar.gz
pushd libtasn1-4.19.0

./configure --prefix=/usr --disable-static
make
make install

popd
rm -rf libtasn1-4.19.0

tar xvf p11-kit-0.25.3.tar.xz
pushd p11-kit-0.25.3

sed '20,$ d' -i trust/trust-extract-compat &&

cat >> trust/trust-extract-compat << "EOF"
# Copy existing anchor modifications to /etc/ssl/local
/usr/libexec/make-ca/copy-trust-modifications

# Update trust stores
/usr/sbin/make-ca -r
EOF

mkdir p11-build &&
cd    p11-build &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -Dtrust_paths=/etc/pki/anchors &&
ninja

ninja install &&
ln -sfv /usr/libexec/p11-kit/trust-extract-compat \
        /usr/bin/update-ca-certificates

ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so

popd
rm -rf p11-kit-0.25.3

tar xvf nettle-3.9.1.tar.gz
pushd nettle-3.9.1

./configure --prefix=/usr --disable-static &&
make

make install &&
chmod   -v   755 /usr/lib/lib{hogweed,nettle}.so &&
install -v -m755 -d /usr/share/doc/nettle-3.9.1 &&
install -v -m644 nettle.{html,pdf} /usr/share/doc/nettle-3.9.1

popd
rm -rf nettle-3.9.1

tar xvf gnutls-3.8.3.tar.xz
pushd gnutls-3.8.3

./configure --prefix=/usr \
            --docdir=/usr/share/doc/gnutls-3.8.3 \
            --with-default-trust-store-pkcs11="pkcs11:" &&
make
make install

popd
rm -rf gnutls-3.8.3

tar xvf curl-8.6.0.tar.xz
pushd curl-8.6.0

./configure --prefix=/usr                           \
            --disable-static                        \
            --with-openssl                          \
            --enable-threaded-resolver              \
            --with-ca-path=/etc/ssl/certs &&
make

make install &&

rm -rf docs/examples/.deps &&

find docs \( -name Makefile\* -o  \
             -name \*.1       -o  \
             -name \*.3       -o  \
             -name CMakeLists.txt \) -delete &&

cp -v -R docs -T /usr/share/doc/curl-8.6.0

popd
rm -rf curl-8.6.0

tar xvf git-2.44.0.tar.xz
pushd git-2.44.0

./configure --prefix=/usr \
            --with-gitconfig=/etc/gitconfig \
            --with-python=python3 &&
make
make perllibdir=/usr/lib/perl5/5.38/site_perl install

popd
rm -rf git-2.44.0

popd
