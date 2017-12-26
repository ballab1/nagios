#!/bin/sh

export NAGIOS_HOME='/usr/local/nagios'
export WWW="${NAGIOS_HOME}/share"
export NCONF="${WWW}/nconf"

function setPermissionsOnVolumes()
{
    local www_user=${www_user:-'www-data'}
    local www_group=${www_group:-'www-data'}
    local nagios_user=${nagios_user:-'nagios'}
    local nagios_group=${nagios_group:-'nagios'}

    nagios_user='nagios'
    nagios_group='nagios'
    sudo chown "${nagios_user}:${nagios_group}" -R "${NAGIOS_HOME}/var/rrd"
    sudo chown "${nagios_user}:${nagios_group}" -R "${NAGIOS_HOME}/var/archives"

    www_user='nobody'
    www_group='nobody'
    sudo chown "${www_user}:${www_group}" -R /var/log
    sudo chown "${www_user}:${www_group}" -R "${NCONF}/output"
    sudo chmod 777 -R /var/log
}

function setHtPasswd
{
    sudo sed -i "s|nagiosadmin|${DBUSER}|" "${NAGIOS_HOME}/etc/cgi.cfg"
    sudo rm "${NAGIOS_HOME}/etc/htpasswd.users"
    echo "${DBPASS}" | htpasswd -c "${NAGIOS_HOME}/etc/htpasswd.users" "${DBUSER}"
    chmod 444 "${NAGIOS_HOME}/etc/htpasswd.users"
}

if [ "$1" = 'nagios' ]; then
    setHtPasswd
    setPermissionsOnVolumes
    exec supervisord --nodaemon --configuration="/etc/supervisord.conf" --loglevel=info
else
    exec $@
fi
