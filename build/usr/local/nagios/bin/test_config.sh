#!/bin/bash

set -o errexit

source /usr/local/crf/bin/init.runtime

rm -rf "${NCONF['home']}"/output/*
rm -rf "${NCONF['home']}"/temp/*
perl "${NCONF['home']}/bin/generate_config.pl"
nagios -v "${NCONF['home']}/temp/test/Default_collector.cfg"
