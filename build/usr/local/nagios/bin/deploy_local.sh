#!/bin/bash

set -o errexit

# ensure this script is run as root
if [[ $EUID != 0 ]]; then
  sudo "$0"
  exit
fi 

declare -r NAGIOS_HOME=${NAGIOS_HOME:-'/usr/local/nagios'}
declare -r WWW=${WWW:-"${NAGIOS_HOME}/share"}
declare -r NCONF=${NCONF:-"${WWW}/nconf"}

declare -r OUTPUT_DIR="${NCONF}/output"
declare -r TEMP_DIR="${NCONF}/temp"

[[ -e "${TEMP_DIR}" ]] || mkdir -p "${TEMP_DIR}"


declare -r outArchive="${OUTPUT_DIR}/NagiosConfig.tgz"
declare -r tmpArchive="${TEMP_DIR}/NagiosConfig.tgz"

# update nagios config if CONF_ARCHIVE is newer than 
if [ -e "$outArchive" ]  && [ "$outArchive" -nt "$tmpArchive" ]; then
    cp "$outArchive" "$tmpArchive"

    # re-deploy: 'extract' into /usr/loca/nagois/etc & 'reload' nagios
    echo removing old config
    rm -rf "${NAGIOS_HOME}/etc/Default_collector"
    rm -rf "${NAGIOS_HOME}/etc/global"
    echo adding new config
    tar -xzf "$tmpArchive" -C "${NAGIOS_HOME}/etc"
    if [ -e /run/nagios.lock ]; then
        echo restartng 'nagios' service
        /etc/init.d/nagios restart
    fi
fi