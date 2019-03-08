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

if (getenv('NCONF_DBPASS') != NULL) {
    define('DBPASS', getenv('NCONF_DBPASS'));
}
elseif (getenv('NCONF_DBPASS_FILE') != NULL) {
    require(NCONFDIR.'/config/mysql.password.inc.php');
}

?>
