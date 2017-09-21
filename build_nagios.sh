#!/bin/bash

set -o errexit
set -o nounset 
set -o verbose

declare TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  
declare NCORE_VERSION=4.3.4
declare NAGIOS_CORE_URL="https://assets.nagios.com/downloads/nagioscore/releases/nagios-${NCORE_VERSION}.tar.gz"
declare NPLUGIN_VERSION=2.2.1
declare NAGIOS_PLUGINS_URL="https://nagios-plugins.org/download/nagios-plugins-${NPLUGIN_VERSION}.tar.gz"
declare PHP_VERSION=5.6.31
declare PHP_URL="http://us1.php.net/get/php-${PHP_VERSION}.tar.gz/from/this/mirror"
declare PHP_SHA="http://us1.php.net/get/php-${PHP_VERSION}.tar.gz.asc/from/this/mirror"


#  prepare php
cd "${TOOLS}"
[[ -e php.tgz ]] && rm -rf php.tgz
wget -O php-${PHP_VERSION}.tar.gz "${PHP_URL}"
wget -O php.tar.gz.asc "${PHP_SHA}"
#sha256sum -c php.tar.gz.asc
tar xvzf php-${PHP_VERSION}.tar.gz
rm -rf php.tar.gz.asc
rm php-${PHP_VERSION}.tar.gz
cd "php-${PHP_VERSION}"
./configure
make all
#make test
make install
tar cvzf ../php.tgz *
cd ..
rm -rf "php-${PHP_VERSION}"



#  prepare nagios exeutables
cd "${TOOLS}"
[[ -e "nagios-${NCORE_VERSION}" ]] && rm -rf "nagios-${NCORE_VERSION}"
wget -O nagios.tar.gz "${NAGIOS_CORE_URL}"
tar xvf nagios.tar.gz
rm nagios.tar.gz
cd "nagios-${NCORE_VERSION}"
# hack Makefiles to be compatible with alpine
while read -r fl; do
  cat "$fl" | sed 's/unzip -u /unzip /g' >  "${fl}.new"
  mv "${fl}.new" "$fl"
done < <(find . -exec grep -cH 'unzip -u ' '{}' \; | grep -v ':0' | awk 'BEGIN{ FS=":"; }{ print $1 }')

./configure
make all
tar cvzf ../nagios.tgz *
cd ..
rm -rf "nagios-${NCORE_VERSION}"




#  prepare nagios plugins
cd "${TOOLS}"
[[ -e "nagios-plugins-${NPLUGIN_VERSION}" ]] && rm -rf "nagios-plugins-${NPLUGIN_VERSION}"
wget -O nagios_plugins.tag.gz "${NAGIOS_PLUGINS_URL}"
tar xvf nagios_plugins.tag.gz
rm nagios_plugins.tag.gz
cd "nagios-plugins-${NPLUGIN_VERSION}"
./configure
make all
tar cvzf ../nagios-plugins.tgz *
cd ..
rm -rf "nagios-plugins-${NPLUGIN_VERSION}"
