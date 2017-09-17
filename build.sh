#!/bin/bash

set -o errexit
set -o nounset 
set -o verbose

declare TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  
declare -r progname="$( basename "${BASH_SOURCE[0]}" )" 

rm *.tgz
 ../alpinefull/builder "$PWD/build_nagios.sh"
[[ -e ../opt/nagios.tgz ]] && mv ../opt/nagios.tgz .
[[ -e ../opt/nagios-plugins.tgz ]] && mv ../opt/nagios-plugins.tgz .

docker-compose build
