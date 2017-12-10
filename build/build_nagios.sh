#!/bin/bash

#set -o xtrace
set -o errexit
set -o nounset 
#set -o verbose

declare TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  

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

# Nagios Plugins
declare -r NPLUGIN_VERSION=${NPLUGIN_VERSION:-'2.2.1'}
declare -r NPLUGIN_FILE="nagios-plugins-${NPLUGIN_VERSION}.tar.gz"
declare -r NPLUGIN_URL="https://nagios-plugins.org/download/nagios-plugins-${NPLUGIN_VERSION}.tar.gz"
declare -r NPLUGIN_SHA256="647c0ba4583d891c965fc29b77c4ccfeccc21f409fdf259cb8af52cb39c21e18"

# Nagios::Object perl module
declare -r NOBJECT_VERSION=${NOBJECT_VERSION:-'0.21.20'}
declare -r NOBJECT_FILE="Nagios-Object-${NOBJECT_VERSION}.tar.gz"
declare -r NOBJECT_URL="http://search.cpan.org/CPAN/authors/id/D/DU/DUNCS/Nagios-Object-${NOBJECT_VERSION}.tar.gz"
declare -r NOBJECT_SHA256="20555203a13644474476078ff50469902ac4710d6ec487cb46e8594a1001057f"

# PHP
declare -r PHP_VERSION=${PHP_VERSION:-'5.6.31'}    
declare -r PHP_FILE="php-${PHP_VERSION}.tar.gz"
declare -r PHP_URL="http://us2.php.net/get/php-${PHP_VERSION}.tar.gz/from/this/mirror"
declare -r PHP_SHA256="6687ed2f09150b2ad6b3780ff89715891f83a9c331e69c90241ef699dec4c43f"



#directories
declare NAGIOS_HOME=/usr/local/nagios
declare NGRAPH_HOME=/usr/local/nagiosgraph
declare NCONF_HOME=/usr/local/nagios/share/nconf
declare WWW=/usr/local/nagios/share 

#  groups/users
declare www_user=${www_user:-'www-data'}
declare www_uid=${www_uid:-82}
declare www_group=${www_group:-'www-data'}
declare www_gid=${www_gid:-82}
declare nagios_user=${nagios_user:-'nagios'}
declare nagios_uid=${nagios_uid:-1002}
declare nagios_group=${nagios_group:-'nagios'}
declare nagios_gid=${nagios_gid:-1002}

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
set -o verbose
    printf "\nclean up\n"
    rm -rf /usr/local/php/man
    rm -rf /usr/local/include
    rm -rf /usr/local/nagios/include
    rm -rf /usr/local/nagios/share/docs
    rm -rf /usr/include
}


#############################################################################
function createUserAndGroup()
{
set -o verbose
    local -r user=$1
    local -r uid=$2
    local -r group=$3
    local -r gid=$4
    local -r homedir=$5
    local -r shell=$6

    printf "\ncreate group:  %s\n" $group
    if [[ "$(cat /etc/group | grep -E ":${gid}:")" ]]; then
        [[  "$(cat /etc/group | grep -E "^${group}:x:${gid}:")"  ]] || exit 1
    fi
    [[ "$(cat /etc/group | grep -E "^${group}:")" ]] \
       ||  /usr/sbin/groupadd --gid "${gid}" "${group}"

    printf "create user: %s\n" $user
    if [[ "$(cat /etc/passwd | grep -E ":${uid}:")" ]]; then
        [[ "$(cat /etc/passwd | grep -E "^${user}:x:${uid}:${gid}:")" ]] || exit 1
    fi
    [[ "$(cat /etc/passwd | grep -E "^${user}:")" ]] \
       ||  /usr/sbin/useradd --home-dir "$homedir" --uid "${uid}" --gid "${gid}" --no-create-home --shell "${shell}" "${user}"
}

#############################################################################
function downloadFile()
{
set -o verbose
    local -r name=$1
    local -r file="${name}_FILE"
    local -r url="${name}_URL"
    local -r sha="${name}_SHA256"

    printf "\nDownloading  %s, %s, %s\n" "${!file}" "${!url}" "${!sha}" 
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
set -o verbose
    cd ${TOOLS}

    #downloadFile 'PHP'
    downloadFile 'NCORE'
    #downloadFile 'NPLUGIN'
    downloadFile 'NOBJECT'
    downloadFile 'NCONF'
    downloadFile 'NGRAPH' 
}

#############################################################################
function fixupNginxLogDirecory()
{
set -o verbose
    printf "\nfix default log directory for nginx\n"
    if [[ -h /var/lib/nginx ]]; then
        rm  /var/lib/nginx
    #    ln -s /var/log /var/lib/nginx
        mkdir -p /var/lib/nginx
    fi
}


#############################################################################
function installCUSTOMIZATIONS()
{
set -o verbose
    printf "\nAdd configuration and customizations\n"
    cp -r "${TOOLS}/etc"/* /etc
    cp -r "${TOOLS}/usr"/* /usr
    cp -r "${TOOLS}/var"/* /var
    mkdir /sessions
}


#############################################################################
function installNAGIOS()
{
set -o verbose
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
    rm /var/lib/nginx/logs
    ln -s /var/log /var/lib/nginx/logs
}


#############################################################################
function installNAGIOS_OBJECT()
{
set -o verbose
    local -r file="$NOBJECT_FILE"

    printf "\nprepare and install %s\n" "${file}"
    cd ${TOOLS}
    tar xf "${file}"
    cd "Nagios-Object-${NOBJECT_VERSION}"
    mv lib/Nagios /usr/local/lib/perl5/site_perl/
}


#############################################################################
function installNCONF()
{
set -o verbose
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
function installNAGIOS_PLUGINS()
{
set -o verbose
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
function installNAGIOSGRAPH()
{
set -o verbose
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

    mkdir -p "${NAGIOS_HOME}/var/rrd"   # Directory in which to store RRD files

    ln -s "${NAGIOS_HOME}/etc/nagiosgraph" /etc/nagiosgraph
    ln -s "${NAGIOS_HOME}/etc/nagiosgraph/nagiosgraph.conf" "${NAGIOS_HOME}/sbin/"
}


#############################################################################
function installPHP()
{
set -o verbose
    local -r file="$PHP_FILE"

    printf "\nprepare and install %s\n" "${file}"
    cd ${TOOLS}
    tar xf "${file}"

    cd "php-${PHP_VERSION}"
    ./configure --enable-fpm --with-mysql --enable-zip --disable-phar --with-libxml-dir=/usr/lib --enable-sockets
    make all
    make install
}


#############################################################################
function setPermissions()
{
set -o verbose
    printf "\nmake sure that ownership & permissions are correct\n"

    chown root:root /etc/sudoers.d/*
    chmod 600 /etc/sudoers.d/*

    mkdir -p /var/run/php
    chown nobody:nobody /var/run/php
#    chown -R "${www_user}:${www_user}" /var/run/php

    chmod 775 "${NAGIOS_HOME}/sbin"/*
    chmod 755 "${NAGIOS_HOME}/bin"/*
    find "${NAGIOS_HOME}/etc" -type d -exec chmod 777 {} \;
    find "${NAGIOS_HOME}/etc" -type f -exec chmod 666 {} \;
    chown nagios:nagios -R "${NAGIOS_HOME}/etc"
    chown nagios:nagios "${NAGIOS_HOME}/sbin"/*
    chown nagios:nagios -R "${NAGIOS_HOME}/var"

    find "${WWW}" -type d -exec chmod 755 {} \;
    find "${WWW}" -type f -exec chmod 644 {} \;
    chown -R nobody:nobody "${WWW}"

    chmod 755 -R "${WWW}/nconf/bin"/*
    find "${WWW}/nconf/config" -type d -exec chmod 777 {} \;
    find "${WWW}/nconf/config" -type f -exec chmod 666 {} \;
    find "${WWW}/nconf/output" -type d -exec chmod 777 {} \;
    find "${WWW}/nconf/output" -type f -exec chmod 666 {} \;
    find "${WWW}/nconf/static_cfg" -type d -exec chmod 777 {} \;
    find "${WWW}/nconf/static_cfg" -type f -exec chmod 666 {} \;
    find "${WWW}/nconf/temp" -type d -exec chmod 777 {} \;
#    chown -R "${www_user}:${www_user}" "${WWW}"
}


#############################################################################

trap catch_error ERR
trap catch_int INT
trap catch_pipe PIPE 

set -o verbose

createUserAndGroup "${www_user}" "${www_uid}" "${www_group}" "${www_gid}" "${WWW}" /sbin/nologin
createUserAndGroup "${nagios_user}" "${nagios_uid}" "${nagios_group}" "${nagios_gid}" "${NAGIOS_HOME}" /bin/bash

downloadFiles
fixupNginxLogDirecory
#installPHP
installNAGIOS
#installNAGIOS_PLUGINS
#installNAGIOS_OBJECT
installNCONF
installNAGIOSGRAPH
installCUSTOMIZATIONS
setPermissions
cleanup
exit 0
