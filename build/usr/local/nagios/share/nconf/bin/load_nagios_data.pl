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
use Nagios::Config;
use Getopt::Std;
use File::Basename;
use Tie::IxHash;    # preserve hash order


&logger(3,"Started executing $0");
&setLoglevel(5);
&logger(3,"Finished running $0");

exit;
