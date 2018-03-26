#!/bin/bash

touch "${RUN_DIR}/fcgiwrap.sock"
#touch "${RUN_DIR}/php5-fpm.sock"

find "$SESSIONS_DIR" -type d -exec chmod 777 '{}' \;
find "$SESSIONS_DIR" -type f -exec chmod 666 '{}' \;

find "$RUN_DIR" -type d -exec chmod 777 '{}' \;
find "$RUN_DIR" -type f -exec chmod 666 '{}' \;
