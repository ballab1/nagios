#!/bin/bash

set -o errexit
set -o nounset 
set -o verbose

declare TOOLS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  
declare -r progname="$( basename "${BASH_SOURCE[0]}" )" 

[[ -e nagios.tgz ]] && rm  nagios.tgz
[[ -e  nagios-plugins.tgz ]] && rm nagios-plugins.tgz
[[ -e  php.tgz ]] && rm php.tgz
 ../alpinefull/builder "$PWD/build_nagios.sh"
[[ -e ../opt/nagios.tgz ]] && mv ../opt/nagios.tgz .
[[ -e ../opt/nagios-plugins.tgz ]] && mv ../opt/nagios-plugins.tgz .
[[ -e ../opt/php.tgz ]] && mv ../opt/php.tgz .

docker-compose build
