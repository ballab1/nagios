#!/usr/bin/perl

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";

use NConf;
use NConf::DB;
use NConf::DB::Read;
use NConf::DB::Modify;
use NConf::Logger;
use NConf::ImportNagios;
use Getopt::Std;
use Tie::IxHash;    # preserve hash order

use constant {
   FILES => [ { 'advanced-services.cfg' => 'advanced-service' },
              { 'checkcommands.cfg' => 'checkcommand' },
              { 'contactgroups.cfg' => 'contactgroup' },
              { 'contacts.cfg' => 'contact' },
              { 'host-dependencies.cfg' => 'host-dependency' },
              { 'host-templates.cfg' => 'host-template' },
              { 'host_dependencies.cfg' => 'host-dependency' },
              { 'host_templates.cfg' => 'host-template' },
              { 'hostgroups.cfg' => 'hostgroup' },
              { 'hosts.cfg' => 'host' },
              { 'misccommands.cfg' => 'misccommand' },
              { 'parent-hosts.cfg' => 'host' },
              { 'parent_hosts.cfg' => 'host' },
              { 'service-templates.cfg' => 'service-template' },
              { 'service_dependencies.cfg' => 'service-dependency' },
              { 'service_templates.cfg' => 'service-template' },
              { 'servicegroups.cfg' => 'servicegroup' },
              { 'services.cfg' => 'service' },
              { 'timeperiods.cfg' => 'timeperiod' }
           ]
};

# read commandline arguments
use vars qw($opt_c $opt_f $opt_x $opt_s);
getopts('c:f:x:s');
unless($opt_c && $opt_f){&usage}
if($opt_x){&setLoglevel($opt_x)}
if($opt_s){&setDbReadonly(1)}

$opt_c =~ s/^\s*//;
$opt_c =~ s/\s*$//;

# global vars

#########################
# MAIN

&logger(3,"Started executing $0");

tie my %main_hash, 'Tie::IxHash';
%main_hash = &parseNagiosConfigFile($opt_c, $opt_f);

# loop through all items
foreach my $item (keys(%main_hash)){

    # service-specific formating
    my $item_print = undef;
    if($opt_c eq "service" && $item =~ /;;/){
        $item =~ /(.*);;(.*)/;
        $item_print = "'$2' to host(s) '$1'";
    }else{$item_print = "'$item'"}

    &logger(3,"Adding $opt_c $item_print");

    tie my %item_hash, 'Tie::IxHash';
    %item_hash = %{$main_hash{$item}};

    if( &addItem($opt_c, %item_hash) ){
        logger(3, "Successfully added $opt_c $item_print");
    }else{
        logger(1, "Failed to add $opt_c $item_print. Aborting");
    }
}

&logger(3,"Finished running $0");

#########################
# SUB: display usage information
sub usage {

print <<"EOT";

Script by Angelo Gargiulo, Sunrise Communications AG
This script reads an existing Nagios configuration file and imports any items 
by creating new items in NConf.

Usage:
$0 -c class -f /path/to/file [-x (1-5)] [-s]

Help:

  required

  -c  Specify the class of items that you wish to import. Must correspond to an NConf class
      (e.g. "host", "service, "hostgroup", "checkcommand", "contact", "timeperiod"...)

  -f  The path to the file which is to be imported. CAUTION: Make sure you have
      only items of one class in the same file (e.g. "hosts.cfg", "services.cfg"...)
      Also make sure you import host- or service-templates separately ("host" or 
      "service" items containing a "name" attribute)

  optional

  -x  Set a custom loglevel (1 = lowest, 5 = most verbose)

  -s  Simulate only. Do not make any actual modifications to the database.

EOT
exit;

}
