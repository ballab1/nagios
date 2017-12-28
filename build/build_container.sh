#!/bin/bash

#set -o xtrace
set -o errexit
set -o nounset 
#set -o verbose

declare -r CONTAINER='NAGIOS'

declare -r TZ="${TZ:-'America/New_York'}"
declare -r SESSIONS_DIR='/sessions'
declare -r TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  


# Alpine Packages
declare -r BUILDTIME_PKGS="alpine-sdk bash-completion busybox file gd-dev git gnutls-utils jpeg-dev libpng-dev libxml2-dev linux-headers musl-utils rrdtool-dev"
declare -r CORE_PKGS="bash curl findutils libxml2 mysql-client nginx openssh-client shadow sudo supervisor thttpd ttf-dejavu tzdata unzip util-linux zlib"
declare -r PERL_PKGS="perl perl-cgi perl-cgi-session perl-plack perl-dbi perl-dbd-mysql perl-gd perl-rrd"
declare -r PHP_PKGS="php5-fpm php5-ctype php5-cgi php5-common php5-dom php5-iconv php5-json php5-mysql php5-pgsql php5-posix php5-sockets php5-xml php5-xmlreader php5-xmlrpc php5-zip"
declare -r NAGIOS_PKGS="fcgiwrap freetype gd jpeg libpng mrtg mysql nagios-plugins-all rrdtool rrdtool-cgi rrdtool-utils rsync"


# Nagios NConf
declare -r NCONF_VERSION=${NCONF_VERSION:-'1.3.0-0'}
declare -r NCONF_FILE="nconf-${NCONF_VERSION}.tgz"
declare -r NCONF_URL="https://sourceforge.net/projects/nconf/files/nconf/${NCONF_VERSION}/nconf-${NCONF_VERSION}.tgz/download"
declare -r NCONF_SHA256="be83db273332595a0e1dffab504b3b3c5c6107c37fbd03c22390665d830b6d7b"

# Nagios Core
declare -r NCORE_VERSION=${NCORE_VERSION:-'4.3.4'}
declare -r NCORE_FILE="nagios-${NCORE_VERSION}.tar.gz"
declare -r NCORE_URL="https://assets.nagios.com/downloads/nagioscore/releases/nagios-${NCORE_VERSION}.tar.gz"
declare -r NCORE_SHA256="c90b7812d9e343db12be19a572e15c415c5d6353a91c5e226e432c2d4aaa44f1"

# NagiosGraph
declare -r NGRAPH_VERSION=${NGRAPH_VERSION:-'1.5.2'}
declare -r NGRAPH_FILE="nagiosgraph-${NGRAPH_VERSION}.tar.gz"
declare -r NGRAPH_URL="https://sourceforge.net/projects/nagiosgraph/files/nagiosgraph/${NGRAPH_VERSION}/nagiosgraph-${NGRAPH_VERSION}.tar.gz/download"
declare -r NGRAPH_SHA256="c466193233a4affbd32f882d8cb475ef2d1e9bf091a21fbf3fccd1f825d7450e"

# Nagios::Object perl module
declare -r NOBJECT_VERSION=${NOBJECT_VERSION:-'0.21.20'}
declare -r NOBJECT_FILE="Nagios-Object-${NOBJECT_VERSION}.tar.gz"
declare -r NOBJECT_URL="http://search.cpan.org/CPAN/authors/id/D/DU/DUNCS/Nagios-Object-${NOBJECT_VERSION}.tar.gz"
declare -r NOBJECT_SHA256="20555203a13644474476078ff50469902ac4710d6ec487cb46e8594a1001057f"


#directories
declare -r NAGIOS_HOME=/usr/local/nagios
declare -r NGRAPH_HOME=/usr/local/nagiosgraph
declare -r NCONF_HOME=/usr/local/nagios/share/nconf
declare -r WWW=/usr/local/nagios/share 

#  groups/users
declare www_user=${www_user:-'www-data'}
declare -r www_uid=${www_uid:-82}
declare www_group=${www_group:-'www-data'}
declare -r www_gid=${www_gid:-82}
declare -r nagios_user=${nagios_user:-'nagios'}
declare -r nagios_uid=${nagios_uid:-1002}
declare -r nagios_group=${nagios_group:-'nagios'}
declare -r nagios_gid=${nagios_gid:-1002}

# global exceptions
declare -i dying=0
declare -i pipe_error=0


#----------------------------------------------------------------------------
# Exit on any error
function catch_error() {
    echo "ERROR: an unknown error occurred at $BASH_SOURCE:$BASH_LINENO" >&2
}

#----------------------------------------------------------------------------
# Detect when build is aborted
function catch_int() {
    die "${BASH_SOURCE[0]} has been aborted with SIGINT (Ctrl-C)"
}

#----------------------------------------------------------------------------
function catch_pipe() {
    pipe_error+=1
    [[ $pipe_error -eq 1 ]] || return 0
    [[ $dying -eq 0 ]] || return 0
    die "${BASH_SOURCE[0]} has been aborted with SIGPIPE (broken pipe)"
}

#----------------------------------------------------------------------------
function die() {
    local status=$?
    [[ $status -ne 0 ]] || status=255
    dying+=1

    printf "%s\n" "FATAL ERROR" "$@" >&2
    exit $status
}  

#############################################################################
function cleanup()
{
    printf "\nclean up\n"

    apk del .buildDepedencies 

    rm -rf /usr/local/php/man
    rm -rf /usr/local/include
    rm -rf /usr/local/nagios/include
    rm -rf /usr/local/nagios/share/docs
    rm -rf /usr/include
}


#############################################################################
function createUserAndGroup()
{
    local -r user=$1
    local -r uid=$2
    local -r group=$3
    local -r gid=$4
    local -r homedir=$5
    local -r shell=$6
    local result
    
    local wanted=$( printf '%s:%s' $group $gid )
    local nameMatch=$( getent group "${group}" | awk -F ':' '{ printf "%s:%s",$1,$3 }' )
    local idMatch=$( getent group "${gid}" | awk -F ':' '{ printf "%s:%s",$1,$3 }' )
    printf "\e[1;34mINFO: group/gid (%s):  is currently (%s)/(%s)\e[0m\n" "$wanted" "$nameMatch" "$idMatch"           

    if [[ $wanted != $nameMatch  ||  $wanted != $idMatch ]]; then
        printf "\ncreate group:  %s\n" $group
        [[ "$nameMatch"  &&  $wanted != $nameMatch ]] && groupdel "$( getent group ${group} | awk -F ':' '{ print $1 }' )"
        [[ "$idMatch"    &&  $wanted != $idMatch ]]   && groupdel "$( getent group ${gid} | awk -F ':' '{ print $1 }' )"
        /usr/sbin/groupadd --gid "${gid}" "${group}"
    fi

    
    wanted=$( printf '%s:%s' $user $uid )
    nameMatch=$( getent passwd "${user}" | awk -F ':' '{ printf "%s:%s",$1,$3 }' )
    idMatch=$( getent passwd "${uid}" | awk -F ':' '{ printf "%s:%s",$1,$3 }' )
    printf "\e[1;34mINFO: user/uid (%s):  is currently (%s)/(%s)\e[0m\n" "$wanted" "$nameMatch" "$idMatch"    
    
    if [[ $wanted != $nameMatch  ||  $wanted != $idMatch ]]; then
        printf "create user: %s\n" $user
        [[ "$nameMatch"  &&  $wanted != $nameMatch ]] && userdel "$( getent passwd ${user} | awk -F ':' '{ print $1 }' )"
        [[ "$idMatch"    &&  $wanted != $idMatch ]]   && userdel "$( getent passwd ${uid} | awk -F ':' '{ print $1 }' )"

        /usr/sbin/useradd --home-dir "$homedir" --uid "${uid}" --gid "${gid}" --no-create-home --shell "${shell}" "${user}"
    fi
}

#############################################################################
function downloadFile()
{
    local -r name=$1
    local -r file="${name}_FILE"
    local -r url="${name}_URL"
    local -r sha="${name}_SHA256"

    printf "\nDownloading  %s\n" "${!file}"
    for i in {0..3}; do
        [[ i -eq 3 ]] && exit 1
        wget -O "${!file}" --no-check-certificate "${!url}"
        [[ $? -ne 0 ]] && continue
        local result=$(echo "${!sha}  ${!file}" | sha256sum -cw 2>&1)
        printf "%s\n" "$result"
        [[ $result != *' WARNING: '* ]] && return
        printf "Failed to successfully download ${!file}. Retrying....\n"
    done
}

#############################################################################
function downloadFiles()
{
    cd ${TOOLS}

    downloadFile 'NCORE'
    downloadFile 'NOBJECT'
    downloadFile 'NCONF'
    downloadFile 'NGRAPH' 
}

#############################################################################
function fixupNginxLogDirectory()
{
    printf "\nfix default log directory for nginx\n"
    if [[ -h /var/lib/nginx ]]; then
        rm  /var/lib/nginx
    #    ln -s /var/log /var/lib/nginx
        mkdir -p /var/lib/nginx
    fi
}

#############################################################################
function header()
{
    local -r bars='+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
    printf "\n\n\e[1;34m%s\nBuilding container: \e[0m%s\e[1;34m\n%s\e[0m\n" $bars $CONTAINER $bars
}
 
#############################################################################
function install_CUSTOMIZATIONS()
{
    printf "\nAdd configuration and customizations\n"

    rm /var/lib/nginx/logs
    ln -s /var/log /var/lib/nginx/logs

    cp -r "${TOOLS}/etc"/* /etc
    cp -r "${TOOLS}/usr"/* /usr
    cp -r "${TOOLS}/var"/* /var

    ln -s /usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh
    
    [[ -f /etc/conf.d/nginx/default.conf ]]  && rm /etc/nginx/conf.d/default.conf
    if [[ -h /var/lib/nginx/logs ]]; then
        rm /var/lib/nginx/logs
        ln -s /var/log /var/lib/nginx/logs
    fi
    [[ -d /var/nginx/client_body_temp ]] || mkdir -p /var/nginx/client_body_temp
    [[ -d "${SESSIONS_DIR}" ]]           || mkdir -p "${SESSIONS_DIR}"
    [[ -d /var/run/php ]]                || mkdir -p /var/run/php
    [[ -d /run/nginx ]]                  || mkdir -p /run/nginx
    
    sed -i "s|^.*date.timezone =.*$|date.timezone = ${TZ}|" '/etc/myconf/php.ini'
    sed -i "s|^.*session.save_path =.*$|session.save_path = \"${SESSIONS_DIR}\"|" '/etc/myconf/php.ini'
}

#############################################################################
function install_NAGIOS()
{
    local -r file="$NCORE_FILE"

    printf "\nprepare and install %s\n" "${file}"
    cd ${TOOLS}
    tar xf "${file}"
    cd "nagios-${NCORE_VERSION}"
    
    # hack Makefiles to be compatible with alpine
    while read -r fl; do
      cat "$fl" | sed 's/unzip -u /unzip /g' >  "${fl}.new"
      mv "${fl}.new" "$fl"
    done < <(find . -exec grep -cH 'unzip -u ' '{}' \; | grep -v ':0' | awk 'BEGIN{ FS=":"; }{ printf $1 }')

    ./configure --with-gd-inc --with-gd-lib --prefix=$NAGIOS_HOME
    make all

    make install
    make install-init
    make install-commandmode
    make install-classicui

    rm -rf "${NAGIOS_HOME}/etc/*"
    ln -s "${NAGIOS_HOME}/etc" /etc/nagios
    ln -s "${NAGIOS_HOME}/bin/nagios" /usr/sbin/nagios
    ln -s "${NAGIOS_HOME}/bin/nagiostats" /usr/sbin/nagiostats

    mkdir -p "${NAGIOS_HOME}/libexec/"
    mv /usr/lib/nagios/plugins/* "${NAGIOS_HOME}/libexec/"
}

#############################################################################
function install_NAGIOS_OBJECT()
{
    local -r file="$NOBJECT_FILE"

    printf "\nprepare and install %s\n" "${file}"
    cd ${TOOLS}
    tar xf "${file}"
    cd "Nagios-Object-${NOBJECT_VERSION}"
    mv lib/Nagios /usr/local/lib/perl5/site_perl/
}


#############################################################################
function install_NCONF()
{
    local -r file="$NCONF_FILE"

    printf "\nprepare and install %s\n" "${file}"
    mkdir -p "${WWW}"
    tar xf "${TOOLS}/${file}" -C "${WWW}" 
    
    rm -rf "${NCONF_HOME}/ADD-ONS"
    rm -rf "${NCONF_HOME}/config.orig"
    rm -rf "${NCONF_HOME}/INSTALL"*
    rm -rf "${NCONF_HOME}/UPDATE"*
    rm -rf "${NCONF_HOME}/SUMS"*
    mkdir -p "${NCONF_HOME}/config"
    mkdir -p "${NCONF_HOME}/output"
    mkdir -p "${NCONF_HOME}/static_cfg"
    mkdir -p "${NCONF_HOME}/temp"
}

#############################################################################
function install_NAGIOS_PLUGINS()
{
    local -r file="$NPLUG_FILE"

    printf "\nprepare and install %s\n" "${file}"
    cd ${TOOLS}
    tar xf "${file}"

    cd "nagios-plugins-${NPLUGIN_VERSION}"
    ./configure --with-mysql --with-gnutls --without-dbi --without-radius  # --with-ldap --with_pgsql=... 
    make
    make install
}

#############################################################################
function install_NAGIOSGRAPH()
{
    local -r file="$NGRAPH_FILE"

    printf "\nprepare and install %s\n" "${file}"
    cd ${TOOLS}
    tar xf "${file}"

    cd "nagiosgraph-${NGRAPH_VERSION}"
    mkdir -p "${NAGIOS_HOME}/etc/nagiosgraph"
    cp etc/*.conf etc/map "${NAGIOS_HOME}/etc/nagiosgraph/"
    cp etc/*.pm "${NAGIOS_HOME}/sbin/"
    cp cgi/*.cgi "${NAGIOS_HOME}/sbin/"

    cp share/nagiosgraph.css "${WWW}"
    cp share/nagiosgraph.js "${WWW}"
    mkdir -p "${WWW}/images"
    cp share/graph.gif "${WWW}/images/"
    mv "${WWW}/images/action.gif" "${WWW}/images/action.org.gif"
    ln -s "${WWW}/images/graph.gif" "${WWW}/images/action.gif"
    mkdir -p "${WWW}/ssi"
    cp share/nagiosgraph.ssi "${WWW}/ssi/common-header.ssi"

    mkdir -p "${NAGIOS_HOME}/var/rrd"   # Directory in which to store RRD files

    ln -s "${NAGIOS_HOME}/etc/nagiosgraph" /etc/nagiosgraph
    ln -s "${NAGIOS_HOME}/etc/nagiosgraph/nagiosgraph.conf" "${NAGIOS_HOME}/sbin/"
}

#############################################################################
function installAlpinePackages()
{
    apk update
    apk add --no-cache $CORE_PKGS $PERL_PKGS $PHP_PKGS $NAGIOS_PKGS
    apk add --no-cache --virtual .buildDepedencies $BUILDTIME_PKGS
}

#############################################################################
function installTimezone()
{
    echo "$TZ" > /etc/TZ
    cp /usr/share/zoneinfo/$TZ /etc/timezone
    cp /usr/share/zoneinfo/$TZ /etc/localtime
}

#############################################################################
function setPermissions()
{
    printf "\nmake sure that ownership & permissions are correct\n"

    chown root:root /etc/sudoers.d/*
    chmod 600 /etc/sudoers.d/*

    chmod u+rwx /usr/local/bin/docker-entrypoint.sh

    chmod 775 "${NAGIOS_HOME}/sbin"/*
    chmod 755 "${NAGIOS_HOME}/bin"/*
    find "${NAGIOS_HOME}/etc" -type d -exec chmod 777 {} \;
    find "${NAGIOS_HOME}/etc" -type f -exec chmod 666 {} \;
    chown "${nagios_user}":"${nagios_user}" -R "${NAGIOS_HOME}/etc"
    chown "${nagios_user}":"${nagios_user}" -R "${NAGIOS_HOME}/sbin"/*
    chown "${nagios_user}":"${nagios_user}" -R "${NAGIOS_HOME}/var"

    sed -i "s|nagiosadmin|${DBUSER}|" "${NAGIOS_HOME}/etc/cgi.cfg"
    [[ -e "${NAGIOS_HOME}/etc/htpasswd.users" ]]  && rm "${NAGIOS_HOME}/etc/htpasswd.users"
    echo "${DBPASS}" | htpasswd -c "${NAGIOS_HOME}/etc/htpasswd.users" "${DBUSER}"
    chmod 444 "${NAGIOS_HOME}/etc/htpasswd.users"


    find "${WWW}" -type d -exec chmod 755 {} \;
    find "${WWW}" -type f -exec chmod 644 {} \;

    chmod 755 -R "${WWW}/nconf/bin"/*
    find "${WWW}/nconf/config" -type d -exec chmod 777 {} \;
    find "${WWW}/nconf/config" -type f -exec chmod 666 {} \;
    find "${WWW}/nconf/output" -type d -exec chmod 777 {} \;
    find "${WWW}/nconf/output" -type f -exec chmod 666 {} \;
    find "${WWW}/nconf/static_cfg" -type d -exec chmod 777 {} \;
    find "${WWW}/nconf/static_cfg" -type f -exec chmod 666 {} \;
    find "${WWW}/nconf/temp" -type d -exec chmod 777 {} \;


www_user='nobody'
www_group='nobody'
    chown "${www_user}:${www_group}" -R /var/nginx/client_body_temp
    chown "${www_user}:${www_group}" -R /sessions
    chown "${www_user}:${www_group}" -R /var/run/php
    chown "${www_user}:${www_group}" -R /var/log
    chown "${www_user}:${www_group}" -R "${WWW}"
}

#############################################################################

trap catch_error ERR
trap catch_int INT
trap catch_pipe PIPE 

set -o verbose

header
declare -r DBUSER="${DBUSER:?'Envorinment variable DBUSER must be defined'}"
declare -r DBPASS="${DBPASS:?'Envorinment variable DBPASS must be defined'}"
declare -r DBHOST="${DBHOST:-'mysql'}" 
declare -r DBNAME="${DBNAME:-'nconf'}" 
installAlpinePackages
installTimezone
createUserAndGroup "${www_user}" "${www_uid}" "${www_group}" "${www_gid}" "${WWW}" /sbin/nologin
createUserAndGroup "${nagios_user}" "${nagios_uid}" "${nagios_group}" "${nagios_gid}" "${NAGIOS_HOME}" /bin/bash
downloadFiles
fixupNginxLogDirectory
install_NAGIOS
install_NAGIOS_OBJECT
install_NCONF
install_NAGIOSGRAPH
install_CUSTOMIZATIONS
setPermissions
cleanup
exit 0
