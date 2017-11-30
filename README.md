# docker_alpine_nagios
Nagios 4.3.2 on alpine on docker


e9b5081eef9a80de5bbb7ae6eaf4d47cc7c828b0

-------   use ENV for /usr/local/nagios
-------       NAGIOS_HOME=/usr/local/nagios
-------       WWW=/usr/local/nagios/share
-------       NCONF=/usr/local/nagios/share/nconf

-------   redo deploy
-------       'extract' into /usr/loca/nagois/etc
-------       and 'reload_command' = "nagios -v /usr/local/nagios/etc/nagios.cfg"

-------   mysql dbname, user,password from ENV
              
-------   setup mappable (correct)  uid/gid for each process in each container
-------       - need to keep uniqueness to allow mapping to host system

-------   move config files into container
-------   fixup all logs to go to /dev/stdout
    - issue with:
        nginx: [alert] could not open error log file: open() "/var/lib/nginx/logs/error.log" failed (2: No such file or directory)
      symbolic link:    /var/lib/nginx/logs -> /var/log/nginx
      /var/log is a mount, but permissions do not allow creation of /var/log/nginx
      unable to locate where symlink created
              
    - figure out what to do with the following from usr/local/nagios/etc/cgi.cfg
        #default_user_name=guest
        authorized_for_system_information=bobb
        authorized_for_configuration_information=bobb
        authorized_for_system_commands=bobb
        authorized_for_all_services=bobb
        authorized_for_all_hosts=bobb
        authorized_for_all_service_commands=bobb
        authorized_for_all_host_commands=bobb
        #authorized_for_read_only=user1,user2

-------   50x.html not found for nagios
    - /usr/local/nagios/share/50x.html shows info of 404 error

setup nagios config from DBMS correctly on startup

change build to create container in one pass
    

where/how is htpasswd.users created

nagios params in ENV
    backup_db.sh  ?
    history_cleanup.sh  ?

issue with static_config: 
    cannot put nagios.cfg, cgi.cfg, resource.cfg in folder. currently using dummy nagios.cfg
    config files do not use relative paths
    
    
graphics (mentioned in nagios build)
    also:  https://exchange.nagios.org/directory/Addons/Graphing-and-Trending/nagiosgraph/details


https://oss.oetiker.ch/rrdtool/pub/?M=D

checking required PERL modules
  Carp...1.40
  CGI... ***FAIL***
  Data::Dumper...2.160
  Digest::MD5...2.54
  File::Basename...2.85
  File::Find...1.34
  MIME::Base64...3.15
  POSIX...1.65_01
  RRDs... ***FAIL***
  Time::HiRes...1.9741
checking optional PERL modules
  GD...2.56
  Nagios::Config... ***FAIL***
