#!/usr/bin/perl -w
#
# Originally written 2007-03-24 by Wolfgang Wagner (aka wolle)
# Copyright 2007 by Wolfgang Wagner. All rights reserved.
# See original work at: http://www.waggy.at/nagios/capture_plugin.htm
#
# Revised by Jess Portnoy <kernel01@gmail.com> on 2015-09-28, Changes:
# - Exit with 3 [UNKNOWN] if cannot open() or close() file
# - chmod file to 600 since it might contain sensitive info
# - some cleanup
#
# $id: capture_plugin.pl v1.1
#
# Captures stdout and stderr into a file and returns original results to Nagios.
#
#
# This software is licensed under the terms of the GNU General Public License Version 2
# as published by the Free Software Foundation.
# It is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE WARRANTY OF DESIGN,
# MERCHANTABILITY, AND FITNESS FOR A PARTICULAR PURPOSE.
#

use strict;
use constant UNKNOWN => 3;
# This plugin does not need any nagios utils. It just interfaces the original plugin.

my $LogFile = "/var/log/captured-plugins.log";

my ($cmd, $ret_code, $output,$numArgs, $argnum,$LogFile);
# First display all arguments
$numArgs = $#ARGV + 1;

# create the command-line

$cmd = $ARGV[0];
if ( ! -x $cmd ) {
  print LOG_FILE "$cmd is not executable\n";
  exit UNKNOWN;
}
foreach $argnum (1 .. $#ARGV) {
  $cmd = $cmd . " '" . $ARGV[$argnum] . "'"
}

# prepare debug-output
my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset) = localtime(time);
my $year = 1900 + $yearOffset;
my $theTime = " $year-$month-$dayOfMonth $hour:$minute:$second";


# now execute the command
$output = `$cmd 2>&1`;
# right shift 8 bits to get the actual RC:
$ret_code = $?>>8;

# if unsuccessful return UNKNWON to Nagios
open (LOG_FILE, ">>$LogFile") || warn ("Cannot open logfile $LogFile: $!") && exit UNKNOWN;
# log the start, output, retcode & end
print LOG_FILE "$theTime ------ debugging\ncmd=[$cmd]\n  output=[$output]\n  retcode=$ret_code\n  environment:\n";
foreach my $key ( sort keys %ENV ) {
  if ( $key =~ /^(NAGIOS|ICINGA)_(.*)/ ) {
    print LOG_FILE '    ' . $key . ' = ' . $ENV{$key} . "\n";
  }
}
print LOG_FILE "-------\n";

close (LOG_FILE) or warn "$0: close($LogFile) failed: $!" && exit UNKNOWN;
# avoid access problems for others.
chmod(0666,$LogFile);

# now return the original result to Nagios
if ($ret_code > UNKNOWN){
  print "Original RC: $ret_code, $output";
  exit UNKNOWN;
}
print $output;
exit "$ret_code";
