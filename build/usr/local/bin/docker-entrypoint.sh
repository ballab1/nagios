#!/bin/sh

export NAGIOS_HOME='/usr/local/nagios'
export WWW="${NAGIOS_HOME}/share"
export NCONF="${WWW}/nconf"

declare www_user=${www_user:-'www-data'}
declare www_group=${www_group:-'www-data'}

if [ "$1" = 'nagios' ]; then
    www_user='nobody'
    www_group='nobody'
    chown "${www_user}:${www_group}" -R /var/log
    exec supervisord --nodaemon --configuration="/etc/supervisord.conf" --loglevel=info
else
    exec $@
fi
