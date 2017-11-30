#!/bin/bash

set -o errexit

declare -r NAGIOS_HOME=${NAGIOS_HOME:-'/usr/local/nagios'}
declare -r WWW=${WWW:-"${NAGIOS_HOME}/share"}
declare -r NCONF=${NCONF:-"${WWW}/nconf"}

rm -rf "${NCONF}"/output/*
rm -rf "${NCONF}"/temp/*
perl "${NCONF}/bin/generate_config.pl"
nagios -v "${NCONF}/temp/test/Default_collector.cfg"
