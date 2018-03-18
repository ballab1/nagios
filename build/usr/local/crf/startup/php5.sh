#!/bin/bash

touch /var/run/php/php5-fpm.sock
chmod 777 /var/run/php/php5-fpm.sock

touch /var/run/php/fcgiwrap.sock
chmod 777 /var/run/php/fcgiwrap.sock