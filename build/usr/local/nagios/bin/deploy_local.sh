#!/bin/bash

set -o errexit

declare -r NAGIOS_HOME=${NAGIOS_HOME:-'/usr/local/nagios'}
declare -r WWW=${WWW:-"${NAGIOS_HOME}/share"}
declare -r NCONF=${NCONF:-"${WWW}/nconf"}

declare -r OUTPUT_DIR="${NCONF}/output"
declare -r TEMP_DIR="${NCONF}/temp"

[[ -e "${TEMP_DIR}" ]] || mkdir -p "${TEMP_DIR}"


declare -r outArchive="${OUTPUT_DIR}/NagiosConfig.tgz"
declare -r tmpArchive="${TEMP_DIR}/NagiosConfig.tgz"

# update nagios config if CONF_ARCHIVE is newer than
[ ! -e "$outArchive" ] || [ "$outArchive" -ot "$tmpArchive" ] || cp "$outArchive" "$tmpArchive"

# re-deploy: 'extract' into /usr/loca/nagois/etc & 'reload' nagios
echo removing old config
rm -rf "${NAGIOS_HOME}/etc/Default_collector"
rm -rf "${NAGIOS_HOME}/etc/global"
echo adding new config
tar -xzf "$tmpArchive" -C "${NAGIOS_HOME}/etc"
tar -xzf "$tmpArchive" -C "${NAGIOS_HOME}/etc"
if [ -e /run/nagios.lock ]; then
    echo restartng 'nagios' service
#    /etc/init.d/nagios restart
    wget -qO /tmp/deploy_result.txt  "http://${SUPERVISORD_USER}:${SUPERVISORD_PASS}@nagios:9001/index.html?processname=nagios&action=restart"
fi