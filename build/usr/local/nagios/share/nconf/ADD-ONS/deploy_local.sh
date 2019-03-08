#!/bin/bash

set -o errexit

# ensure this script is run as root
if [[ $EUID != 0 ]]; then
  sudo $0
  exit
fi 

declare -r NAGIOS_HOME=${NAGIOS_HOME:-'/usr/local/nagios'}
declare -r WWW=${WWW:-"${NAGIOS_HOME}/share"}
declare -r NCONF_HOME=${NCONF_HOME:-"${WWW}/nconf"}

declare -r OUTPUT_DIR="${NCONF_HOME}/output"
declare -r TEMP_DIR="${NCONF_HOME}/temp"
declare -r CONF_ARCHIVE="NagiosConfig.tgz"

declare -r outArchive="${OUTPUT_DIR}/${CONF_ARCHIVE}"
declare -r tmpArchive="${TEMP_DIR}/${CONF_ARCHIVE}"


[[ -e "${TEMP_DIR}" ]] || mkdir -p "${TEMP_DIR}"

# update nagios config if CONF_ARCHIVE is newer than 
[[ "${outArchive}" -nt "${tmpArchive}" ]] && cp "${outArchive}" "${tmpArchive}"

# re-deploy: 'extract' into /usr/loca/nagois/etc & 'reload' nagios
tar -xzf "${tmpArchive}" -C "${NAGIOS_HOME}/etc"
nagios -v "${NAGIOS_HOME}/etc/nagios.cfg"
