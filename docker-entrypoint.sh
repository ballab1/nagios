#!/bin/sh

export NAGIOS_HOME='/usr/local/nagios'
export WWW="${NAGIOS_HOME}/share"
export NCONF="${WWW}/nconf"

if [ "$1" = 'nagios' ]; then
    chown nobody:nobody -R /var/log/*
    exec supervisord --nodaemon --configuration="/etc/supervisord.conf" --loglevel=info
else
    exec $@
fi
