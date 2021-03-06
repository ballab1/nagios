##############################################################################
# "NConf::DB" library
# A collection of shared functions for the NConf Perl scripts.
# General, database related functions.
#
# Version 0.1
# Written by Angelo Gargiulo
#
# Revision history:
# 2009-02-25 v0.1   A. Gargiulo   First release
#
##############################################################################

package NConf::DB;

use strict;
use Exporter;

use DBI 1.38;
use DBD::mysql 2.1;

use NConf;
use NConf::Helpers;
use NConf::Logger;
use Env;

use vars qw($NC_dbh $NC_db_readonly $NC_db_caching);
use vars qw(%NC_dbcache_getAttrId %NC_dbcache_getItemClass %NC_dbcache_getConfigAttrs %NC_dbcache_getNamingAttr %NC_dbcache_getConfigClasses %NC_dbcache_checkLinkAsChild %NC_ctrcache_getUniqueNameCounter);

$NC_dbh = undef;
$NC_db_readonly = 0;
$NC_db_caching  = 1;

##############################################################################
### I N I T ##################################################################
##############################################################################

BEGIN {
    use vars qw(@ISA @EXPORT @EXPORT_OK);

    @ISA         = qw(NConf);
    @EXPORT      = qw(@NConf::EXPORT $NC_dbh $NC_db_readonly $NC_db_caching %NC_dbcache_getAttrId %NC_dbcache_getItemClass %NC_dbcache_getConfigAttrs %NC_dbcache_getNamingAttr %NC_dbcache_getConfigClasses %NC_dbcache_checkLinkAsChild %NC_ctrcache_getUniqueNameCounter dbConnect dbDisconnect dbQuote setDbReadonly);
    @EXPORT_OK   = qw(@NConf::EXPORT_OK);

}

##############################################################################
### S U B S ##################################################################
##############################################################################

sub dbConnect {
    &logger(5,"Entered dbConnect()");

    # SUB use: connect to NConf database, if not yet connected

    # SUB specs: ###################

    # Return values:
    # 0: returns a DBI:mysql database handle

    ################################

    # only connect to database, if not yet connected
    if($NC_dbh){
        &logger(5,"Already connected to the database");
        return $NC_dbh;
    }

#    my $dbhost = &readNConfConfig(NC_CONFDIR."/mysql.php","DBHOST","scalar");
#    my $dbname = &readNConfConfig(NC_CONFDIR."/mysql.php","DBNAME","scalar");
#    my $dbuser = &readNConfConfig(NC_CONFDIR."/mysql.php","DBUSER","scalar");
#    my $dbpass = &readNConfConfig(NC_CONFDIR."/mysql.php","DBPASS","scalar");
    my $dbhost = $ENV{'NCONF_DBHOST'};
    my $dbname = $ENV{'NCONF_DBNAME'};
    my $dbuser = $ENV{'NCONF_DBUSER'};
    my $dbpass = $ENV{'NCONF_DBPASS'};
    if (! defined $dbpass) {
        my $conf_file = $ENV{'NCONF_DBPASS_FILE'};
        if (! defined $conf_file) {
            &logger(4,"No password defined for database");
        }
        else {
            &logger(4,"Reading option NCONF_DBPASS from $conf_file");
            if (! open(CONF,$conf_file)) {
                &logger(1,"Could not open configuration file $conf_file");
            }
            else {
                $dbpass = <CONF>;
                close(CONF);
                chomp $dbpass;
            }
        }
    }

    &logger(4,"Connecting to database '$dbname' on host '$dbhost' as user '$dbuser'");
    my $dsn = "DBI:mysql:database=$dbname;host=$dbhost";

    # allow use of mysql socket connection rather than TCP connection only
    if ($dbhost =~ /^:(.+)/) {
      $dsn = "DBI:mysql:database=$dbname;mysql_socket=$1";
    }


    my $retries = 5;
    while (--$retries >= 0) {

        eval {
            $NC_dbh = DBI->connect($dsn, $dbuser, $dbpass, { PrintError => 1, RaiseError => 1, AutoCommit => 1 });
        };
        if ($@) {
            &logger(1,"waiting for database: $dbname");
            sleep(2);
            next;
        }

        &logger(4,"Connected to database '$dbname' on host '$dbhost' as user '$dbuser'");
        return $NC_dbh;
    }

    &logger(1,"Could not connect to database '$dbname' on host '$dbhost' as user '$dbuser'");
    $NC_dbh->{PrintError} = 1;
    $NC_dbh->{RaiseError} = 1;
    $NC_dbh->{AutoCommit} = 1;

    return $NC_dbh;
}

##############################################################################

sub dbDisconnect {
    &logger(5,"Entered dbDisconnect()");

    # SUB use: disconnect from NConf database, if connected
    if($NC_dbh){
        &logger(4,"Disconnecting from database");
        $NC_dbh->disconnect;
        $NC_dbh = undef;
    }

}

##############################################################################

sub dbQuote {
    &logger(5,"Entered dbQuote()");

    # SUB use: Quote and excape any special chars for safe SQL usage

    # SUB specs: ###################

    # Expected arguments:
    # 0: string to be quoted

    # Return values:
    # 0: quoted string

    ################################

    # read arguments passed
    my $string = shift;

    my $dbh = &dbConnect;
    my $q_string = $dbh->quote($string);

    &logger(5,"Quoted string for safe SQL usage: $q_string");
    return $q_string;
}

##############################################################################

sub setDbReadonly {
    &logger(5,"Entered setDbReadonly()");

    # SUB use: Prevent any actual modifications from being made to the database

    # SUB specs: ###################

    # Expected arguments:
    # 0: 1 = set to read-only, 0 = unset

    ################################

    my $ro = shift;

    if($ro == 0 or $ro == 1){
        &logger(4,"Setting DB read-only to $ro");
        $NC_db_readonly = $ro;

        if($NC_db_readonly == 1){
            &logger(3,"Running in simulation mode. No modifications will be made to the database!");
        }
    }
}

##############################################################################

1;

__END__

}
