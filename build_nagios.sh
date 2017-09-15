#!/bin/bash -x

set -e

declare TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  
declare NCORE_VERSION=4.3.4
declare NAGIOS_CORE_URL="https://assets.nagios.com/downloads/nagioscore/releases/nagios-${NCORE_VERSION}.tar.gz" \
declare NPLUGIN_VERSION=2.2.1
declare NAGIOS_PLUGINS_URL="https://nagios-plugins.org/download/nagios-plugins-${NPLUGIN_VERSION}.tar.gz" \


wget -O nagios.tar.gz "${NAGIOS_CORE_URL}"
tar -xvf nagios.tar.gz
rm nagios.tar.gz
cd "nagios-${NCORE_VERSION}"

# change Makefiles to be compatible with alpine
while read -r fl; do
  cat "$fl" | sed 's/unzip -u /unzip /g' >  "${fl}.new"
  mv "${fl}.new" "$fl"
done < <(find . -exec grep -cH 'unzip -u ' '{}' \; | grep -v ':0' | awk 'BEGIN{ FS=":"; }{ print $1 }')

./configure
make all

cd "$TOOLS"
wget -O nagios_plugins.tag.gz "${NAGIOS_PLUGINS_URL}"
tar -xvf nagios_plugins.tag.gz
rm nagios_plugins.tag.gz
cd "nagios-plugins-${NPLUGIN_VERSION}"
./configure
make all


#make install
#make install-init
#make install-commandmode
#make install-config
#make install-webconf
#make install-classicui

#cd /
#tar cvzf /opt/nagioscore.tar.gz /usr/local/nagios  /etc/init.d/nagios
