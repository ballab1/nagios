#!/bin/bash

# ensure this script is run as root
if [[ $EUID != 0 ]]; then
    sudo $0
    exit
fi

set -o errexit
set -o nounset 
set -o verbose

declare TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  
declare -r progname="$( basename "${BASH_SOURCE[0]}" )" 

cd "${TOOLS}"
[[ -e nagios.tgz ]] && rm  nagios.tgz
 ../alpinefull/builder "$PWD/build_nagios.sh" "$PWD/nagios-custom.tgz"
[[ -e ../opt/nagios.tgz ]] && mv ../opt/nagios.tgz .

#docker-compose build
