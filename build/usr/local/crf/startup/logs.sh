#!/bin/bash

declare logs='error.log nagios.log nginx_access.log  nginx_errors.log php5-fpm.log supervisord.log'

for log in ${logs}; do
    touch /var/log/$log
    chmod 666 /var/log/$log 
done
