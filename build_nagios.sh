#!/bin/bash

set -o errexit
set -o nounset 
set -o verbose

declare NCORE_VERSION=4.3.4
declare NCONF_VERSION=1.3.0-0 
declare NPLUGIN_VERSION=2.2.1
declare PHP_VERSION=5.6.31

declare TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  

declare NAGIOS_CORE_URL="https://assets.nagios.com/downloads/nagioscore/releases/nagios-${NCORE_VERSION}.tar.gz"
declare NAGIOS_PLUGINS_URL="https://nagios-plugins.org/download/nagios-plugins-${NPLUGIN_VERSION}.tar.gz"
declare PHP_URL="http://us2.php.net/get/php-${PHP_VERSION}.tar.gz/from/this/mirror"
declare PHP_SHA="http://us2.php.net/get/php-${PHP_VERSION}.tar.gz.asc/from/this/mirror"
declare NCONF_URL="https://sourceforge.net/projects/nconf/files/nconf/${NCONF_VERSION}/nconf-${NCONF_VERSION}.tgz/download"
declare NCONF_SHA="https://sourceforge.net/projects/nconf/files/nconf/${NCONF_VERSION}/nconf-${NCONF_VERSION}.tgz.sha256/download"
    
declare user=nagios
declare group=nagios
declare uid=1001
declare gid=1001 
declare NAGIOS_HOME=/usr/local/nagios
declare WWW="${NAGIOS_HOME}/share"


#  create groups/users
/usr/sbin/groupadd -g ${gid} ${group}
/usr/sbin/useradd -d "$NAGIOS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}



cd "${TOOLS}"
[[ -d "php-${PHP_VERSION}" ]] && rm -rf "php-${PHP_VERSION}"
[[ -f "php-${PHP_VERSION}" ]] && rm php.tar.gz.asc
[[ -f "php-${PHP_VERSION}.tar.gz" ]] && rm "php-${PHP_VERSION}.tar.gz"
[[ -d "nagios-${NCORE_VERSION}" ]] && rm -rf "nagios-${NCORE_VERSION}"
[[ -d "nagios-plugins-${NPLUGIN_VERSION}" ]] && rm -rf "nagios-plugins-${NPLUGIN_VERSION}"
[[ -f "nagios-plugins-${NPLUGIN_VERSION}.tag.gz" ]] && rm "nagios-plugins-${NPLUGIN_VERSION}.tag.gz"
[[ -f "nconf-${NCONF_VERSION}.tgz" ]] && rm -rf "nconf-${NCONF_VERSION}.tgz"
[[ -d custom ]] && rm -rf custom
[[ -f nconf.tgz.sha ]] && rm nconf.tgz.sha
[[ -d nconf ]] && rm -rf nconf


#  download php
[[ -e php.tar.gz.asc ]] && rm -rf php.tar.gz.asc
[[ -e "php-${PHP_VERSION}.tar.gz" ]] && rm -rf "php-${PHP_VERSION}.tar.gz"
wget -O php.tar.gz.asc "${PHP_SHA}"
#for i in {1..3}; do
    wget -O "php-${PHP_VERSION}.tar.gz" --no-check-certificate "${PHP_URL}"
#    sha256sum -c php.tar.gz.asc && break
#    [[ i -eq 3 ]] && exit 1
#done


#  download nagios
[[ -e "nagios-${NCORE_VERSION}" ]] && rm -rf "nagios-${NCORE_VERSION}"
wget -O "nagios-${NCORE_VERSION}" "${NAGIOS_CORE_URL}"


#  download nagios plugins
[[ -e "nagios-plugins-${NPLUGIN_VERSION}" ]] && rm -rf "nagios-plugins-${NPLUGIN_VERSION}"
wget -O "nagios-plugins-${NPLUGIN_VERSION}.tag.gz" "${NAGIOS_PLUGINS_URL}"


#  download nconf
[[ -e nconf.tgz.sha ]] && rm -rf nconf.tgz.sha
[[ -e "nconf-${NCONF_VERSION}.tgz" ]] && rm -rf "nconf-${NCONF_VERSION}.tgz"
wget -O nconf.tgz.sha "$NCONF_SHA"
for i in {1..3}; do
    wget -O "nconf-${NCONF_VERSION}.tgz" --no-check-certificate "$NCONF_URL"
    sha256sum -c nconf.tgz.sha && break
    [[ i -eq 3 ]] && exit 1
done



#  prepare php
cd "${TOOLS}"
tar xvzf "php-${PHP_VERSION}.tar.gz"
cd "${TOOLS}/php-${PHP_VERSION}"
./configure --enable-fpm --with-mysql
make all
make install



#  prepare nagios exeutables
cd "${TOOLS}"
tar xvf "nagios-${NCORE_VERSION}"
cd "${TOOLS}/nagios-${NCORE_VERSION}"
# hack Makefiles to be compatible with alpine
while read -r fl; do
  cat "$fl" | sed 's/unzip -u /unzip /g' >  "${fl}.new"
  mv "${fl}.new" "$fl"
done < <(find . -exec grep -cH 'unzip -u ' '{}' \; | grep -v ':0' | awk 'BEGIN{ FS=":"; }{ print $1 }')

./configure
make all
tar xzvf "${TOOLS}/nagios-custom.tgz"
[[ -d "${TOOLS}/custom/etc" ]] || mkdir -p "${TOOLS}/custom/etc"
mv custom/etc/* "${TOOLS}/custom/etc"
mv custom/var "${TOOLS}/custom"
mv custom/nagios.tar.inc "${TOOLS}/custom"
cat custom/Makefile.custom >> Makefile
make install
make install-init
make install-commandmode
make install-classicui
make install-customcontent




#  prepare nagios plugins
cd "${TOOLS}"
tar xvf "nagios-plugins-${NPLUGIN_VERSION}.tag.gz"
cd "${TOOLS}/nagios-plugins-${NPLUGIN_VERSION}"
./configure --with-mysql --with-gnutls
make
make install
mv "${NAGIOS_HOME}/etc" "${NAGIOS_HOME}/etc.bak"
mkdir -p "${NAGIOS_HOME}/etc"
mv ../"nagios-${NCORE_VERSION}"/custom/etc.nagios/*  "${NAGIOS_HOME}/etc"


#  prepare nconf
cd "${TOOLS}"
tar xzvf "nconf-${NCONF_VERSION}.tgz"
mkdir -p "${NAGIOS_HOME}/libexec"
mv "${TOOLS}/nagios-${NCORE_VERSION}/custom/libexec.nagios/"*  "${NAGIOS_HOME}/libexec/"


mkdir -p "${WWW}/nconf/config"
mkdir -p "${WWW}/nconf/output"
mkdir -p "${WWW}/nconf/static_cfg"
mkdir -p "${WWW}/nconf/temp"
mv nconf/ADD-ONS "${NAGIOS_HOME}/nconf/"
mv nconf/config.orig "${NAGIOS_HOME}/nconf/"
mv nconf/INSTALL* "${NAGIOS_HOME}/nconf/"
mv nconf/UPDATE* "${NAGIOS_HOME}/nconf/"
mv nconf/SUMS* "${NAGIOS_HOME}/nconf/"
mv nconf/* "${WWW}/nconf/"
chown -R root:nobody "${WWW}"
find "${WWW}" -type d -exec chmod 755 {} \;
find "${WWW}" -type f -exec chmod 644 {} \;
find "${WWW}/nconf/config" -type d -exec chmod 777 {} \;
find "${WWW}/nconf/config" -type f -exec chmod 666 {} \;
find "${WWW}/nconf/output" -type d -exec chmod 777 {} \;
find "${WWW}/nconf/output" -type f -exec chmod 666 {} \;
find "${WWW}/nconf/static_cfg" -type d -exec chmod 777 {} \;
find "${WWW}/nconf/static_cfg" -type f -exec chmod 666 {} \;
find "${WWW}/nconf/temp" -type d -exec chmod 777 {} \;
chmod 755 "${WWW}/nconf/bin"/*
chmod 755 "${NAGIOS_HOME}/bin"/*


cd "${TOOLS}"
#rm -rf "php-${PHP_VERSION}" php.tar.gz.asc "php-${PHP_VERSION}.tar.gz"
#rm -rf "nagios-${NCORE_VERSION}"
#rm -rf "nagios-plugins-${NPLUGIN_VERSION}" "nagios-plugins-${NPLUGIN_VERSION}.tag.gz"
#rm -rf "nconf-${NCONF_VERSION}.tgz" nconf.tgz.sha nconf
cp -r custom/etc/* /etc
cp -r custom/var/* /var
    
tar cvzf nagios.tgz -T custom/nagios.tar.inc
