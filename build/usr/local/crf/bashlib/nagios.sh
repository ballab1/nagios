#!/bin/sh

function nagios.setPermissionsOnVolumes()
{
    local www_user=${www_user:-"www-data"}
    local www_group=${www_group:-"www-data"}
    local nagios_user=${nagios_user:-"nagios"}
    local nagios_group=${nagios_group:-"nagios"}

    nagios_user='nagios'
    nagios_group='nagios'
    chown "${nagios_user}:${nagios_group}" -R "${NAGIOS_HOME}/var/rrd"
    chown "${nagios_user}:${nagios_group}" -R "${NAGIOS_HOME}/var/archives"

    www_user='nobody'
    www_group='nobody'
    chown "${www_user}:${www_group}" -R /var/log
    chown "${www_user}:${www_group}" -R "${WWW}/nconf/output"
    chmod 777 -R /var/log
}

function nagios.setHtPasswd
{
    sed -i "s|=nagiosadmin|=${DBUSER}|" "${NAGIOS_HOME}/etc/cgi.cfg"
    sed -i \
        -e "s|^.*nagios_user=.*$|nagios_user=${DBUSER}|" \
        -e "s|^.*nagios_group=.*$|nagios_group=${DBUSER}|" \
           "${NAGIOS_HOME}/etc/nagios.cfg"
    rm "${NAGIOS_HOME}/etc/htpasswd.users"
    echo "${DBPASS}" | htpasswd -c "${NAGIOS_HOME}/etc/htpasswd.users" "${DBUSER}"
    chmod 444 "${NAGIOS_HOME}/etc/htpasswd.users"
}
