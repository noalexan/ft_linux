#!/bin/bash
set -e

pushd /sources

tar xvf Linux-PAM-1.6.0.tar.xz
pushd Linux-PAM-1.6.0

./configure --prefix=/usr                        \
            --sbindir=/usr/sbin                  \
            --sysconfdir=/etc                    \
            --libdir=/usr/lib                    \
            --enable-securedir=/usr/lib/security \
            --docdir=/usr/share/doc/Linux-PAM-1.6.0
make
install -v -m755 -d /etc/pam.d &&

cat > /etc/pam.d/other << "EOF"
auth     required       pam_deny.so
account  required       pam_deny.so
password required       pam_deny.so
session  required       pam_deny.so
EOF
rm -fv /etc/pam.d/other
make install &&
chmod -v 4755 /usr/sbin/unix_chkpwd

install -vdm755 /etc/pam.d

cat > /etc/pam.d/system-account << "EOF" &&
# Begin /etc/pam.d/system-account

account   required    pam_unix.so

# End /etc/pam.d/system-account
EOF

cat > /etc/pam.d/system-auth << "EOF" &&
# Begin /etc/pam.d/system-auth

auth      required    pam_unix.so

# End /etc/pam.d/system-auth
EOF

cat > /etc/pam.d/system-session << "EOF" &&
# Begin /etc/pam.d/system-session

session   required    pam_unix.so

# End /etc/pam.d/system-session
EOF

cat > /etc/pam.d/system-password << "EOF"
# Begin /etc/pam.d/system-password

# use yescrypt hash for encryption, use shadow, and try to use any
# previously defined authentication token (chosen password) set by any
# prior module.
password  required    pam_unix.so       yescrypt shadow try_first_pass

# End /etc/pam.d/system-password
EOF

cat > /etc/pam.d/other << "EOF"
# Begin /etc/pam.d/other

auth        required        pam_warn.so
auth        required        pam_deny.so
account     required        pam_warn.so
account     required        pam_deny.so
password    required        pam_warn.so
password    required        pam_deny.so
session     required        pam_warn.so
session     required        pam_deny.so

# End /etc/pam.d/other
EOF

popd
rm -rf Linux-PAM-1.6.0

tar xvf cracklib-2.9.11.tar.xz
pushd cracklib-2.9.11

autoreconf -fiv &&

PYTHON=python3               \
./configure --prefix=/usr    \
            --disable-static \
            --with-default-dict=/usr/lib/cracklib/pw_dict &&
make
make install

install -v -m644 -D    ../cracklib-words-2.9.11.xz \
                         /usr/share/dict/cracklib-words.xz    &&

unxz -v                  /usr/share/dict/cracklib-words.xz    &&
ln -v -sf cracklib-words /usr/share/dict/words                &&
echo $(hostname) >>      /usr/share/dict/cracklib-extra-words &&
install -v -m755 -d      /usr/lib/cracklib                    &&

create-cracklib-dict     /usr/share/dict/cracklib-words \
                         /usr/share/dict/cracklib-extra-words

popd
rm -rf cracklib-2.9.11

tar xvf libpwquality-1.4.5.tar.bz2
pushd libpwquality-1.4.5

./configure --prefix=/usr                      \
            --disable-static                   \
            --with-securedir=/usr/lib/security \
            --disable-python-bindings          &&
make &&
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD/python

make install &&
pip3 install --no-index --find-links=dist --no-cache-dir --no-user pwquality

mv /etc/pam.d/system-password{,.orig} &&
cat > /etc/pam.d/system-password << "EOF"
# Begin /etc/pam.d/system-password

# check new passwords for strength (man pam_pwquality)
password  required    pam_pwquality.so   authtok_type=UNIX retry=1 difok=1 \
                                         minlen=8 dcredit=0 ucredit=0 \
                                         lcredit=0 ocredit=0 minclass=1 \
                                         maxrepeat=0 maxsequence=0 \
                                         maxclassrepeat=0 gecoscheck=0 \
                                         dictcheck=1 usercheck=1 \
                                         enforcing=1 badwords="" \
                                         dictpath=/usr/lib/cracklib/pw_dict

# use yescrypt hash for encryption, use shadow, and try to use any
# previously defined authentication token (chosen password) set by any
# prior module.
password  required    pam_unix.so        yescrypt shadow try_first_pass

# End /etc/pam.d/system-password
EOF

popd
rm -rf libpwquality-1.4.5

tar xvf zip30.tar.gz
pushd zip30

make -f unix/Makefile generic_gcc
make prefix=/usr MANDIR=/usr/share/man/man1 -f unix/Makefile install

popd
rm -rf zip30

tar xvf docbook-xsl-nons-1.79.2.tar.bz2
pushd docbook-xsl-nons-1.79.2

patch -Np1 -i ../docbook-xsl-nons-1.79.2-stack_fix-1.patch
install -v -m755 -d /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2 &&

cp -v -R VERSION assembly common eclipse epub epub3 extensions fo        \
         highlighting html htmlhelp images javahelp lib manpages params  \
         profiling roundtrip slides template tests tools webhelp website \
         xhtml xhtml-1_1 xhtml5                                          \
    /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2 &&

ln -s VERSION /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2/VERSION.xsl &&

install -v -m644 -D README \
                    /usr/share/doc/docbook-xsl-nons-1.79.2/README.txt &&
install -v -m644    RELEASE-NOTES* NEWS* \
                    /usr/share/doc/docbook-xsl-nons-1.79.2

if [ ! -d /etc/xml ]; then install -v -m755 -d /etc/xml; fi &&
if [ ! -f /etc/xml/catalog ]; then
    xmlcatalog --noout --create /etc/xml/catalog
fi &&

xmlcatalog --noout --add "rewriteSystem" \
           "http://cdn.docbook.org/release/xsl-nons/1.79.2" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteSystem" \
           "https://cdn.docbook.org/release/xsl-nons/1.79.2" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI" \
           "http://cdn.docbook.org/release/xsl-nons/1.79.2" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI" \
           "https://cdn.docbook.org/release/xsl-nons/1.79.2" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteSystem" \
           "http://cdn.docbook.org/release/xsl-nons/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteSystem" \
           "https://cdn.docbook.org/release/xsl-nons/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI" \
           "http://cdn.docbook.org/release/xsl-nons/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI" \
           "https://cdn.docbook.org/release/xsl-nons/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteSystem" \
           "http://docbook.sourceforge.net/release/xsl/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI" \
           "http://docbook.sourceforge.net/release/xsl/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog

xmlcatalog --noout --add "rewriteSystem" \
           "http://docbook.sourceforge.net/release/xsl/<version>" \
           "/usr/share/xml/docbook/xsl-stylesheets-<version>" \
    /etc/xml/catalog &&

xmlcatalog --noout --add "rewriteURI" \
           "http://docbook.sourceforge.net/release/xsl/<version>" \
           "/usr/share/xml/docbook/xsl-stylesheets-<version>" \
    /etc/xml/catalog

popd
rm -rf docbook-xsl-nons-1.79.2

tar xvf unzip60.tar.gz
pushd unzip60

patch -Np1 -i ../unzip-6.0-consolidated_fixes-1.patch
make -f unix/Makefile generic
make prefix=/usr MANDIR=/usr/share/man/man1 \
 -f unix/Makefile install

popd
rm -rf unzip60

tar xvf sgml-common-0.6.3.tgz
pushd sgml-common-0.6.3

patch -Np1 -i ../sgml-common-0.6.3-manpage-1.patch &&
autoreconf -f -i
./configure --prefix=/usr --sysconfdir=/etc &&
make
make docdir=/usr/share/doc install &&

install-catalog --add /etc/sgml/sgml-ent.cat \
    /usr/share/sgml/sgml-iso-entities-8879.1986/catalog &&

install-catalog --add /etc/sgml/sgml-docbook.cat \
    /etc/sgml/sgml-ent.cat

popd
rm -rf sgml-common-0.6.3

mkdir docbook
pushd docbook
unzip ../docbook-xml-4.5.zip

install -v -d -m755 /usr/share/xml/docbook/xml-dtd-4.5 &&
install -v -d -m755 /etc/xml &&
cp -v -af --no-preserve=ownership docbook.cat *.dtd ent/ *.mod \
    /usr/share/xml/docbook/xml-dtd-4.5
if [ ! -e /etc/xml/docbook ]; then
    xmlcatalog --noout --create /etc/xml/docbook
fi &&
xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML V4.5//EN" \
    "http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML CALS Table Model V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/calstblx.dtd" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//DTD XML Exchange Table Model 19990315//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/soextblx.dtd" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML Information Pool V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbpoolx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML Document Hierarchy V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbhierx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML HTML Tables V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/htmltblx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Notations V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbnotnx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Character Entities V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbcentx.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Additional General Entities V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbgenent.mod" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "rewriteSystem" \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook &&
xmlcatalog --noout --add "rewriteURI" \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook

if [ ! -e /etc/xml/catalog ]; then
    xmlcatalog --noout --create /etc/xml/catalog
fi &&
xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//ENTITIES DocBook XML" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog &&
xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//DTD DocBook XML" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog &&
xmlcatalog --noout --add "delegateSystem" \
    "http://www.oasis-open.org/docbook/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog &&
xmlcatalog --noout --add "delegateURI" \
    "http://www.oasis-open.org/docbook/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog

for DTDVERSION in 4.1.2 4.2 4.3 4.4
do
  xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML V$DTDVERSION//EN" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/docbookx.dtd" \
    /etc/xml/docbook
  xmlcatalog --noout --add "rewriteSystem" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook
  xmlcatalog --noout --add "rewriteURI" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook
  xmlcatalog --noout --add "delegateSystem" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog
  xmlcatalog --noout --add "delegateURI" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog
done

popd
rm -rf docbook

tar xvf libgpg-error-1.47.tar.bz2
pushd libgpg-error-1.47

./configure --prefix=/usr &&
make
make install &&
install -v -m644 -D README /usr/share/doc/libgpg-error-1.47/README

popd
rm -rf libgpg-error-1.47

tar xvf libgcrypt-1.10.3.tar.bz2
pushd libgcrypt-1.10.3

./configure --prefix=/usr &&
make                      &&

make -C doc html                                                       &&
makeinfo --html --no-split -o doc/gcrypt_nochunks.html doc/gcrypt.texi &&
makeinfo --plaintext       -o doc/gcrypt.txt           doc/gcrypt.texi
make install &&
install -v -dm755   /usr/share/doc/libgcrypt-1.10.3 &&
install -v -m644    README doc/{README.apichanges,fips*,libgcrypt*} \
                    /usr/share/doc/libgcrypt-1.10.3 &&

install -v -dm755   /usr/share/doc/libgcrypt-1.10.3/html &&
install -v -m644 doc/gcrypt.html/* \
                    /usr/share/doc/libgcrypt-1.10.3/html &&
install -v -m644 doc/gcrypt_nochunks.html \
                    /usr/share/doc/libgcrypt-1.10.3      &&
install -v -m644 doc/gcrypt.{txt,texi} \
                    /usr/share/doc/libgcrypt-1.10.3

popd
rm -rf libgcrypt-1.10.3

tar xvf libxslt-1.1.39.tar.xz
pushd libxslt-1.1.39

./configure --prefix=/usr                          \
            --disable-static                       \
            --docdir=/usr/share/doc/libxslt-1.1.39 \
            PYTHON=/usr/bin/python3 &&
make
make install

popd
rm -rf libxslt-1.1.39

tar xvf pcre2-10.42.tar.bz2
pushd pcre2-10.42

./configure --prefix=/usr                       \
            --docdir=/usr/share/doc/pcre2-10.42 \
            --enable-unicode                    \
            --enable-jit                        \
            --enable-pcre2-16                   \
            --enable-pcre2-32                   \
            --enable-pcre2grep-libz             \
            --enable-pcre2grep-libbz2           \
            --enable-pcre2test-libreadline      \
            --disable-static                    &&
make
make install

popd
rm -rf pcre2-10.42

tar xvf glib-2.78.4.tar.xz
pushd glib-2.78.4

patch -Np1 -i ../glib-skip_warnings-1.patch
mkdir build &&
cd    build &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -Dman=true          &&
ninja
ninja install &&

mkdir -p /usr/share/doc/glib-2.78.4 &&
cp -r ../docs/reference/{gio,glib,gobject} /usr/share/doc/glib-2.78.4

popd
rm -rf glib-2.78.4

tar xvf gobject-introspection-1.78.1.tar.xz
pushd gobject-introspection-1.78.1

mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja
ninja install

popd
rm -rf gobject-introspection-1.78.1

tar xvf duktape-2.7.0.tar.xz
pushd duktape-2.7.0

sed -i 's/-Os/-O2/' Makefile.sharedlibrary
make -f Makefile.sharedlibrary INSTALL_PREFIX=/usr
make -f Makefile.sharedlibrary INSTALL_PREFIX=/usr install

popd
rm -rf duktape-2.7.0

tar xvf polkit-124.tar.gz
pushd polkit-124

groupadd -fg 27 polkitd &&
useradd -c "PolicyKit Daemon Owner" -d /etc/polkit-1 -u 27 \
        -g polkitd -s /bin/false polkitd

mkdir build &&
cd    build &&

meson setup ..                            \
      --prefix=/usr                       \
      --buildtype=release                 \
      -Dman=true                          \
      -Dsession_tracking=libsystemd-login \
      -Dtests=true                        &&
ninja
ninja install

popd
rm -rf polkit-124

tar xvf systemd-255.tar.gz
pushd systemd-255

sed -i -e 's/GROUP="render"/GROUP="video"/' \
       -e 's/GROUP="sgx", //' rules.d/50-udev-default.rules.in

patch -Np1 -i ../systemd-255-upstream_fixes-1.patch

mkdir build &&
cd    build &&

meson setup ..                \
      --prefix=/usr           \
      --buildtype=release     \
      -Ddefault-dnssec=no     \
      -Dfirstboot=false       \
      -Dinstall-tests=false   \
      -Dldconfig=false        \
      -Dman=auto              \
      -Dsysusers=false        \
      -Drpmmacrosdir=no       \
      -Dhomed=disabled        \
      -Duserdb=false          \
      -Dmode=release          \
      -Dpam=enabled           \
      -Dpamconfdir=/etc/pam.d \
      -Ddev-kvm-mode=0660     \
      -Dnobody-group=nogroup  \
      -Dsysupdate=disabled    \
      -Dukify=disabled        \
      -Ddocdir=/usr/share/doc/systemd-255 &&

ninja
ninja install

grep 'pam_systemd' /etc/pam.d/system-session ||
cat >> /etc/pam.d/system-session << "EOF"
# Begin Systemd addition

session  required    pam_loginuid.so
session  optional    pam_systemd.so

# End Systemd addition
EOF

cat > /etc/pam.d/systemd-user << "EOF"
# Begin /etc/pam.d/systemd-user

account  required    pam_access.so
account  include     system-account

session  required    pam_env.so
session  required    pam_limits.so
session  required    pam_loginuid.so
session  optional    pam_keyinit.so force revoke
session  optional    pam_systemd.so

auth     required    pam_deny.so
password required    pam_deny.so

# End /etc/pam.d/systemd-user
EOF

systemctl daemon-reexec

popd
rm -rf systemd-255

tar xvf shadow-4.14.5.tar.xz
pushd shadow-4.14.5

sed -i 's/groups$(EXEEXT) //' src/Makefile.in          &&

find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \; &&
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \; &&
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \; &&

sed -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD YESCRYPT@' \
    -e 's@/var/spool/mail@/var/mail@'                   \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    -i etc/login.defs                                   &&

./configure --sysconfdir=/etc   \
            --disable-static    \
            --without-libbsd    \
            --with-{b,yes}crypt &&
make
make exec_prefix=/usr pamddir= install
make -C man install-man

install -v -m644 /etc/login.defs /etc/login.defs.orig &&
for FUNCTION in FAIL_DELAY               \
                FAILLOG_ENAB             \
                LASTLOG_ENAB             \
                MAIL_CHECK_ENAB          \
                OBSCURE_CHECKS_ENAB      \
                PORTTIME_CHECKS_ENAB     \
                QUOTAS_ENAB              \
                CONSOLE MOTD_FILE        \
                FTMP_FILE NOLOGINS_FILE  \
                ENV_HZ PASS_MIN_LEN      \
                SU_WHEEL_ONLY            \
                CRACKLIB_DICTPATH        \
                PASS_CHANGE_TRIES        \
                PASS_ALWAYS_WARN         \
                CHFN_AUTH ENCRYPT_METHOD \
                ENVIRON_FILE
do
    sed -i "s/^${FUNCTION}/# &/" /etc/login.defs
done

cat > /etc/pam.d/login << "EOF"
# Begin /etc/pam.d/login

# Set failure delay before next prompt to 3 seconds
auth      optional    pam_faildelay.so  delay=3000000

# Check to make sure that the user is allowed to login
auth      requisite   pam_nologin.so

# Check to make sure that root is allowed to login
# Disabled by default. You will need to create /etc/securetty
# file for this module to function. See man 5 securetty.
#auth      required    pam_securetty.so

# Additional group memberships - disabled by default
#auth      optional    pam_group.so

# include system auth settings
auth      include     system-auth

# check access for the user
account   required    pam_access.so

# include system account settings
account   include     system-account

# Set default environment variables for the user
session   required    pam_env.so

# Set resource limits for the user
session   required    pam_limits.so

# Display the message of the day - Disabled by default
#session   optional    pam_motd.so

# Check user's mail - Disabled by default
#session   optional    pam_mail.so      standard quiet

# include system session and password settings
session   include     system-session
password  include     system-password

# End /etc/pam.d/login
EOF

cat > /etc/pam.d/passwd << "EOF"
# Begin /etc/pam.d/passwd

password  include     system-password

# End /etc/pam.d/passwd
EOF

cat > /etc/pam.d/su << "EOF"
# Begin /etc/pam.d/su

# always allow root
auth      sufficient  pam_rootok.so

# Allow users in the wheel group to execute su without a password
# disabled by default
#auth      sufficient  pam_wheel.so trust use_uid

# include system auth settings
auth      include     system-auth

# limit su to users in the wheel group
# disabled by default
#auth      required    pam_wheel.so use_uid

# include system account settings
account   include     system-account

# Set default environment variables for the service user
session   required    pam_env.so

# include system session settings
session   include     system-session

# End /etc/pam.d/su
EOF

cat > /etc/pam.d/chpasswd << "EOF"
# Begin /etc/pam.d/chpasswd

# always allow root
auth      sufficient  pam_rootok.so

# include system auth and account settings
auth      include     system-auth
account   include     system-account
password  include     system-password

# End /etc/pam.d/chpasswd
EOF

sed -e s/chpasswd/newusers/ /etc/pam.d/chpasswd >/etc/pam.d/newusers

cat > /etc/pam.d/chage << "EOF"
# Begin /etc/pam.d/chage

# always allow root
auth      sufficient  pam_rootok.so

# include system auth and account settings
auth      include     system-auth
account   include     system-account

# End /etc/pam.d/chage
EOF

for PROGRAM in chfn chgpasswd chsh groupadd groupdel \
               groupmems groupmod useradd userdel usermod
do
    install -v -m644 /etc/pam.d/chage /etc/pam.d/${PROGRAM}
    sed -i "s/chage/$PROGRAM/" /etc/pam.d/${PROGRAM}
done

if [ -f /etc/login.access ]; then mv -v /etc/login.access{,.NOUSE}; fi
if [ -f /etc/limits ]; then mv -v /etc/limits{,.NOUSE}; fi

popd
rm -rf shadow-4.14.5

tar xvf six-1.16.0.tar.gz
pushd six-1.16.0

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links=dist --no-cache-dir --no-user six

popd
rm -rf six-1.16.0

tar xvf gdb-14.1.tar.xz
pushd gdb-14.1

mkdir build &&
cd    build &&

../configure --prefix=/usr          \
             --with-system-readline \
             --with-python=/usr/bin/python3 &&
make

make -C gdb install &&
make -C gdbserver install

popd
rm -rf gdb-14.1

tar xvf openssh-9.6p1.tar.gz
pushd openssh-9.6p1

install -v -g sys -m700 -d /var/lib/sshd &&

groupadd -g 50 sshd        &&
useradd  -c 'sshd PrivSep' \
         -d /var/lib/sshd  \
         -g sshd           \
         -s /bin/false     \
         -u 50 sshd

./configure --prefix=/usr                            \
            --sysconfdir=/etc/ssh                    \
            --with-privsep-path=/var/lib/sshd        \
            --with-default-path=/usr/bin             \
            --with-superuser-path=/usr/sbin:/usr/bin \
            --with-pid-dir=/run                      &&
make

make install &&
install -v -m755    contrib/ssh-copy-id /usr/bin     &&

install -v -m644    contrib/ssh-copy-id.1 \
                    /usr/share/man/man1              &&
install -v -m755 -d /usr/share/doc/openssh-9.6p1     &&
install -v -m644    INSTALL LICENCE OVERVIEW README* \
                    /usr/share/doc/openssh-9.6p1

echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "KbdInteractiveAuthentication no" >> /etc/ssh/sshd_config

sed 's@d/login@d/sshd@g' /etc/pam.d/login > /etc/pam.d/sshd &&
chmod 644 /etc/pam.d/sshd &&
echo "UsePAM yes" >> /etc/ssh/sshd_config

popd
rm -rf openssh-9.6p1

tar xvf blfs-systemd-units-20240205.tar.xz
pushd blfs-systemd-units-20240205

make install-sshd

popd
rm -rf blfs-systemd-units-20240205

popd
