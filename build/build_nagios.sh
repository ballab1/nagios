#!/bin/bash

set -o errexit
set -o nounset 
set -o verbose

declare TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  

# versions
declare NCORE_VERSION=${NCORE_VERSION:-'4.3.4'}
declare NCONF_VERSION=${NCONF_VERSION:-'1.3.0-0'}
declare NGRAPH_VERSION=${NGRAPH_VERSION:-'1.5.2'}
declare NPLUGIN_VERSION=${NPLUGIN_VERSION:-'2.2.1'}
declare PHP_VERSION=${PHP_VERSION:-'5.6.31'}

# URLs
declare -r NAGIOS_CORE_URL="https://assets.nagios.com/downloads/nagioscore/releases/nagios-${NCORE_VERSION}.tar.gz"
declare -r NAGIOS_PLUGINS_URL="https://nagios-plugins.org/download/nagios-plugins-${NPLUGIN_VERSION}.tar.gz"
declare -r NAGIOSGRAPH_URL="https://sourceforge.net/projects/nagiosgraph/files/nagiosgraph/${NGRAPH_VERSION}/nagiosgraph-${NGRAPH_VERSION}.tar.gz/download"
declare -r NCONF_URL="https://sourceforge.net/projects/nconf/files/nconf/${NCONF_VERSION}/nconf-${NCONF_VERSION}.tgz/download"
declare -r NCONF_SHA="https://sourceforge.net/projects/nconf/files/nconf/${NCONF_VERSION}/nconf-${NCONF_VERSION}.tgz.sha256/download"
declare -r PHP_URL="http://us2.php.net/get/php-${PHP_VERSION}.tar.gz/from/this/mirror"
declare -r PHP_SHA="http://us2.php.net/get/php-${PHP_VERSION}.tar.gz.asc/from/this/mirror"

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
    # clean up
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

    #  create groups
    if [[ "$(cat /etc/group | grep -E ":${gid}:")" ]]; then
        [[  "$(cat /etc/group | grep -E "^${group}:x:${gid}:")"  ]] || exit 1
    fi
    [[ "$(cat /etc/group | grep -E "^${group}:")" ]] \
       ||  /usr/sbin/groupadd --gid "${gid}" "${group}"

    #  create user
    if [[ "$(cat /etc/passwd | grep -E ":${uid}:")" ]]; then
        [[ "$(cat /etc/passwd | grep -E "^${user}:x:${uid}:${gid}:")" ]] || exit 1
    fi
    [[ "$(cat /etc/passwd | grep -E "^${user}:")" ]] \
       ||  /usr/sbin/useradd --home-dir "$homedir" --uid "${uid}" --gid "${gid}" --no-create-home --shell "${shell}" "${user}"
}


#############################################################################
function downloadFiles()
{
    cd ${TOOLS}

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
}


#############################################################################
function fixupNginxLogDirecory()
{
    # fix default log directory for nginx
    if [[ -h /var/lib/nginx ]]; then
        rm  /var/lib/nginx
    #    ln -s /var/log /var/lib/nginx
        mkdir -p /var/lib/nginx
    fi
}


#############################################################################
function installCUSTOMIZATIONS()
{
    # Add configuration and customizations
    cp -r "${TOOLS}/etc"/* /etc
    cp -r "${TOOLS}/usr"/* /usr
    cp -r "${TOOLS}/var"/* /var
    mkdir /sessions
}


#############################################################################
function installNCONF()
{
    #  prepare nconf
    mkdir -p "${WWW}"
    tar xzvf "${TOOLS}/nconf-${NCONF_VERSION}.tgz" -C "${WWW}"
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
function installNAGIOS()
{
    cd ${TOOLS}

    #  prepare nagios exeutables
    tar xvf "nagios-${NCORE_VERSION}"
    cd "nagios-${NCORE_VERSION}"
    
    # hack Makefiles to be compatible with alpine
    while read -r fl; do
      cat "$fl" | sed 's/unzip -u /unzip /g' >  "${fl}.new"
      mv "${fl}.new" "$fl"
    done < <(find . -exec grep -cH 'unzip -u ' '{}' \; | grep -v ':0' | awk 'BEGIN{ FS=":"; }{ print $1 }')

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
}


#############################################################################
function installNAGIOS_PLUGINS()
{
    cd ${TOOLS}

    #  prepare nagios plugins
    tar xvf "nagios-plugins-${NPLUGIN_VERSION}.tag.gz"
    cd "nagios-plugins-${NPLUGIN_VERSION}"
    ./configure --with-mysql --with-gnutls --without-dbi --without-radius  # --with-ldap --with_pgsql=... 
    make
    make install
}


#############################################################################
function installNAGIOSGRAPH()
{
    cd ${TOOLS}
    
    #  prepare nagiosgraph plugin
    tar xzvf "nagiosgraph-${NGRAPH_VERSION}.tar.gz"
    cd "nagiosgraph-${NGRAPH_VERSION}"

    mkdir -p "${NGRAPH_HOME}/etc"
    cp etc/* "${NGRAPH_HOME}/etc"

    #mkdir -p "${NGRAPH_HOME}/cgi-bin"
    cp cgi/*.cgi "${NAGIOS_HOME}/sbin"

    mkdir -p "${NGRAPH_HOME}/share"
    cp share/nagiosgraph.css "${WWW}"
    cp share/nagiosgraph.js "${WWW}"

    mkdir -p "${NAGIOS_HOME}/var/rrd"   # Directory in which to store RRD files
    #mkdir -p "${NGRAPH_HOME}/bin"

    ln -s "${NGRAPH_HOME}/etc" /etc/nagiosgraph
}


#############################################################################
function installPHP()
{
    cd ${TOOLS}

    #  prepare php
    tar xvzf "php-${PHP_VERSION}.tar.gz"
    cd "php-${PHP_VERSION}"
    ./configure --enable-fpm --with-mysql --enable-zip --disable-phar --with-libxml-dir=/usr/lib --enable-sockets
    make all
    make install
}


#############################################################################
function main()
{
    createUserAndGroup "${www_user}" "${www_uid}" "${www_group}" "${www_gid}" "${WWW}" /sbin/nologin
    createUserAndGroup "${nagios_user}" "${nagios_uid}" "${nagios_group}" "${nagios_gid}" "${NAGIOS_HOME}" /bin/bash

    downloadFiles
    fixupNginxLogDirecory
    installPHP
    installNAGIOS
    installNAGIOS_PLUGINS
    installNCONF
    installNAGIOSGRAPH
    installCUSTOMIZATIONS
    setPermissions
    cleanup
}


#############################################################################
function setPermissions()
{
    # make sure that ownership & permissions are correct
    chown -R "${www_user}:${www_user}" "${WWW}"
    find "${WWW}" -type d -exec chmod 755 {} \;
    find "${WWW}" -type f -exec chmod 644 {} \;
    find "${NGRAPH_HOME}/share" -type d -exec chmod a+rx '{}' \;
    find "${NGRAPH_HOME}/share" -type f -exec chmod a+r '{}' \;
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
}


#############################################################################

trap catch_error ERR
trap catch_int INT
trap catch_pipe PIPE 

main $@
exit 0
