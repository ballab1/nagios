#!/bin/sh


if [ "$1" = 'nagios' ]; then
    [[ -d /var/nginx/client_body_temp ]] || mkdir -p /var/nginx/client_body_temp
    [[ -d /var/log/archives ]] || mkdir -p /var/log/archives
    [[ -d /var/log/other ]] || mkdir -p /var/log/other
    [[ -d /var/log/nagios ]] || mkdir -p /var/log/nagios
    [[ -d /var/log/nginx ]] || mkdir -p /var/log/nginx
    [[ -d /var/run/php ]] || mkdir -p /var/run/php

    touch /var/log/php-fpm.log

    chown nobody:nobody /sessions /var/nginx/client_body_temp /var/run/php
    chown nobody:nobody -R /var/log/*

    [[ -e /etc/myconf/nginx.conf ]] && cp /etc/myconf/nginx.conf /etc/nginx/nginx.conf
    exec supervisord --nodaemon --configuration="/etc/supervisord.conf" --loglevel=info

else
    exec $@
fi