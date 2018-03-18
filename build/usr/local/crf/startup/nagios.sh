#!/bin/bash

nagios.setHtPasswd
nagios.setPermissionsOnVolumes

nagios -v ${NAGIOS_HOME}/etc/nagios.cfg
[ ! -e /run/nagios.lock ] || rm /run/nagios.lock

declare -r TEMP_DIR="${NCONF}/temp"
declare -r tmpArchive="${TEMP_DIR}/NagiosConfig.tgz"
[ ! -e "$tmpArchive" ] || rm "$tmpArchive"

${NAGIOS_HOME}/bin/deploy_local.sh

find "${NAGIOS_HOME}/var" ! -user nagios -delete