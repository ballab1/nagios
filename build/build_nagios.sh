#!/bin/bash

set -o errexit
set -o nounset 
set -o verbose

declare TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  

declare NCORE_VERSION=${NCORE_VERSION:-'4.3.4'}
declare NCONF_VERSION=${NCONF_VERSION:-'1.3.0-0'}
declare NGRAPH_VERSION=${NGRAPH_VERSION:-'1.5.2'}
declare NPLUGIN_VERSION=${NPLUGIN_VERSION:-'2.2.1'}
declare PHP_VERSION=${PHP_VERSION:-'5.6.31'}
declare RRDTOOL_VERSION=${RRDTOOL_VERSION:-'1.7.0'}

declare NAGIOS_HOME=${NAGIOS_HOME:-'/usr/local/nagios'}
declare WWW=${WWW:-"${NAGIOS_HOME}/share"}
declare NCONF=${NCONF:-"${WWW}/nconf"}


declare -r NAGIOS_CORE_URL="https://assets.nagios.com/downloads/nagioscore/releases/nagios-${NCORE_VERSION}.tar.gz"
declare -r NAGIOS_PLUGINS_URL="https://nagios-plugins.org/download/nagios-plugins-${NPLUGIN_VERSION}.tar.gz"
declare -r NAGIOSGRAPH_URL="https://sourceforge.net/projects/nagiosgraph/files/nagiosgraph/${NGRAPH_VERSION}/nagiosgraph-${NGRAPH_VERSION}.tar.gz/download"
declare -r NCONF_URL="https://sourceforge.net/projects/nconf/files/nconf/${NCONF_VERSION}/nconf-${NCONF_VERSION}.tgz/download"
declare -r NCONF_SHA="https://sourceforge.net/projects/nconf/files/nconf/${NCONF_VERSION}/nconf-${NCONF_VERSION}.tgz.sha256/download"
declare -r PHP_URL="http://us2.php.net/get/php-${PHP_VERSION}.tar.gz/from/this/mirror"
declare -r PHP_SHA="http://us2.php.net/get/php-${PHP_VERSION}.tar.gz.asc/from/this/mirror"
declare -r RDDTOOL_URL="https://oss.oetiker.ch/rrdtool/pub/rrdtool-${RRDTOOL_VERSION}.tar.gz"

#  create groups/users
declare user=${user:-'nagios'}
declare group=${group:-'nagios'}
declare uid=${uid:-1001}
declare gid=${gid:-1001}
/usr/sbin/groupadd -g ${gid} ${group}
/usr/sbin/useradd -d "$NAGIOS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}
cd "${TOOLS}"

# fix default log directory for nginx
if [[ -h /var/lib/nginx ]]; then
    rm  /var/lib/nginx
#    ln -s /var/log /var/lib/nginx
    mkdir -p /var/lib/nginx
fi


#  download php
wget -O "php.tar.gz.asc" "${PHP_SHA}"
#for i in {1..3}; do
    wget -O "php-${PHP_VERSION}.tar.gz" --no-check-certificate "${PHP_URL}"
#    sha256sum -c "php.tar.gz.asc" && break
#    [[ i -eq 3 ]] && exit 1
#done


#  download nagios
wget -O "nagios-${NCORE_VERSION}" "${NAGIOS_CORE_URL}"


#  download nagios plugins
wget -O "nagios-plugins-${NPLUGIN_VERSION}.tag.gz" "${NAGIOS_PLUGINS_URL}"


#  download nconf
wget -O "nconf.tgz.sha" "$NCONF_SHA"
for i in {1..3}; do
    wget -O "nconf-${NCONF_VERSION}.tgz" --no-check-certificate "$NCONF_URL"
    sha256sum -c "nconf.tgz.sha" && break
    [[ i -eq 3 ]] && exit 1
done


#  download nagiosgraph
wget -O "nagiosgraph-${NGRAPH_VERSION}.tar.gz" "${NAGIOSGRAPH_URL}"


#  download rddtool
wget -O "rrdtool-${RRDTOOL_VERSION}.tar.gz" "${RDDTOOL_URL}"



#  prepare php
cd ${TOOLS}
tar xvzf "php-${PHP_VERSION}.tar.gz"
cd "php-${PHP_VERSION}"
./configure --enable-fpm --with-mysql --enable-zip --disable-phar --with-libxml-dir=/usr/lib --enable-sockets
make all
make install



#  prepare nagios exeutables
cd ${TOOLS}
tar xvf "nagios-${NCORE_VERSION}"
cd "nagios-${NCORE_VERSION}"
# hack Makefiles to be compatible with alpine
while read -r fl; do
  cat "$fl" | sed 's/unzip -u /unzip /g' >  "${fl}.new"
  mv "${fl}.new" "$fl"
done < <(find . -exec grep -cH 'unzip -u ' '{}' \; | grep -v ':0' | awk 'BEGIN{ FS=":"; }{ print $1 }')

./configure --with-gd-inc --with-gd-lib
make all

make install
make install-init
make install-commandmode
make install-classicui




#  prepare nagios plugins
cd ${TOOLS}
tar xvf "nagios-plugins-${NPLUGIN_VERSION}.tag.gz"
cd "nagios-plugins-${NPLUGIN_VERSION}"
./configure --with-mysql --with-gnutls
make
make install
rm -rf "${NAGIOS_HOME}/etc/*"




#  prepare nconf
mkdir -p "${WWW}"
tar xzvf "${TOOLS}/nconf-${NCONF_VERSION}.tgz" -C "${WWW}"
rm -rf "${NCONF}/ADD-ONS"
rm -rf "${NCONF}/config.orig"
rm -rf "${NCONF}/INSTALL"*
rm -rf "${NCONF}/UPDATE"*
rm -rf "${NCONF}/SUMS"*
mkdir -p "${NCONF}/config"
mkdir -p "${NCONF}/output"
mkdir -p "${NCONF}/static_cfg"
mkdir -p "${NCONF}/temp"




#  prepare rddtool
cd ${TOOLS}
tar xzvf "rrdtool-${RRDTOOL_VERSION}.tar.gz"




#  prepare nagiosgraph plugin
cd ${TOOLS}
tar xzvf "nagiosgraph-${NGRAPH_VERSION}.tar.gz"
cd "nagiosgraph-${NGRAPH_VERSION}"
#./install.pl --check-prereq
#./install.pl --prefix=/usr/local/nagiosgraph




# Add configuration and customizations
cp -r "${TOOLS}/etc"/* /etc
cp -r "${TOOLS}/usr"/* /usr
cp -r "${TOOLS}/var"/* /var


# make sure that ownership & permissions are correct
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
chown root:root /etc/sudoers.d/*
chmod 600 /etc/sudoers.d/*



# clean up
#rm -rf "${TOOLS}"/*
#rm -rf /usr/local/php/man
#rm -rf /usr/local/include
#rm -rf /usr/local/nagios/include
#rm -rf /usr/local/nagios/share/docs