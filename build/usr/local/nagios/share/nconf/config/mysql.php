<?php
##
## MySQL config
##

#
# Main MySQL connection parameters
#
define('DBHOST', getenv('NCONF_DBHOST'));
define('DBNAME', getenv('NCONF_DBNAME'));
define('DBUSER', getenv('NCONF_DBUSER'));
define('DBPASS', getenv('NCONF_DBPASS'));

?>
