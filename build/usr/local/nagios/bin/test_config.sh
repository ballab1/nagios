#!/bin/bash

set -o errexit

declare -r NAGIOS_HOME=${NAGIOS_HOME:-'/usr/local/nagios'}
declare -r WWW=${WWW:-"${NAGIOS_HOME}/share"}
declare -r NCONF_HOME=${NCONF_HOME:-"${WWW}/nconf"}

rm -rf "${NCONF_HOME}"/output/*
rm -rf "${NCONF_HOME}"/temp/*
perl "${NCONF_HOME}/bin/generate_config.pl"
nagios -v "${NCONF_HOME}/temp/test/Default_collector.cfg"
