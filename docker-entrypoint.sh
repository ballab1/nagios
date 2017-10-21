#!/bin/sh

[[ -d /var/log/archives ]] || mkdir -p /var/log/archives
[[ -d /var/log/nagios ]] || mkdir -p /var/log/nagios
[[ -d /var/log/nginx ]] || mkdir -p /var/log/nginx
[[ -d /var/run/php ]] || mkdir -p /var/run/php
[[ -d /var/nginx/client_body_temp ]] || mkdir -p /var/nginx/client_body_temp
touch /var/run/php-fpm.log
touch /var/log/php-fpm.log
chown nobody:nobody /sessions /var/nginx/client_body_temp /var/run/php
chown nobody:nobody -R /var/log/*
[[ -e /etc/myconf/nginx.conf ]] && cp /etc/myconf/nginx.conf /etc/nginx/nginx.conf

if [ "$1" = 'nagios' ]; then
    exec supervisord --nodaemon --configuration="/etc/supervisord.conf" --loglevel=info
fi
