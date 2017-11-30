#!/bin/bash

set -o errexit

# ensure this script is run as root
if [[ $EUID != 0 ]]; then
  sudo $0
  exit
fi 

declare -r NAGIOS_HOME=${NAGIOS_HOME:-'/usr/local/nagios'}
declare -r WWW=${WWW:-"${NAGIOS_HOME}/share"}
declare -r NCONF=${NCONF:-"${WWW}/nconf"}

declare -r OUTPUT_DIR="${NCONF}/output"
declare -r TEMP_DIR="${NCONF}/temp"
declare -r CONF_ARCHIVE="NagiosConfig.tgz"

declare -r outArchive="${OUTPUT_DIR}/${CONF_ARCHIVE}"
declare -r tmpArchive="${TEMP_DIR}/${CONF_ARCHIVE}"


[[ -e "${TEMP_DIR}" ]] || mkdir -p "${TEMP_DIR}"

# update nagios config if CONF_ARCHIVE is newer than 
[[ "${outArchive}" -nt "${tmpArchive}" ]] && cp "${outArchive}" "${tmpArchive}"

# re-deploy: 'extract' into /usr/loca/nagois/etc & 'reload' nagios
echo removing old config
rm -rf "${NAGIOS_HOME}/etc/Default_collector"
rm -rf "${NAGIOS_HOME}/etc/global"
echo adding new config
tar -xzf "${tmpArchive}" -C "${NAGIOS_HOME}/etc"
echo restartng 'nagios' service
nagios -v "${NAGIOS_HOME}/etc/nagios.cfg"
