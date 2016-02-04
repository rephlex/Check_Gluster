#!/usr/bin/perl

use strict;
use Nagios::Plugin;
use Nagios::Plugin::Functions;
use Nagios::Plugin::Getopt;

#Check_GLuster.pl
#John C. Bertrand <john.bertrand@gmail.com>
#Florian Panzer <rephlex@rephlex.de>
# This nagios plugins checks the status
# and checks to see if the volume has the correct
# number of bricks
# Checked against gluster 3.2.7 and 3.6.2
# Rev 2 2015.03.16

#SET THESE
my $SUDO="/usr/bin/sudo";
my $GLUSTER="/usr/sbin/gluster";

my $opts = Nagios::Plugin::Getopt->new(
        usage   => "Usage: %s  -v --volume Volume_Name -n --numbricks -s --sudo",
        version => Nagios::Plugin::->VERSION,
        blurb   => 'checks the volume state and brick count in gluster fs'
);

$opts->arg(
    spec => 'volume|v=s',
    help => 'Volume name',
    required => 1,
  );

$opts->arg(
    spec => 'numberofbricks|n=i',
    help => 'Target number of bricks',
    required => 1,
);

$opts->arg(
   spec => 'sudo|s',
   help => 'Use sudo',
   required => 0,
   default => 0,
);

$opts->getopts;

my $volume=$opts->get("volume");
my $bricktarget=$opts->get("numberofbricks");
my $use_sudo=$opts->get("sudo");

my $returnCode=UNKNOWN;
my $returnMessage="~";

my $result= undef;

if ($use_sudo == 1) {
    $result=`$SUDO $GLUSTER volume info $volume`;
}else {
    $result=`$GLUSTER volume info $volume`;
}

if ($result =~ m/Status: Started/){
    if ($result =~ m/Number of Bricks: .*(\d+)/){
        my $bricks=$1;

        if ($bricks != $bricktarget){
               $returnCode=CRITICAL;
               $returnMessage="Brick count is $bricks, should be $bricktarget";
        }else{
          $returnCode=OK;
          $returnMessage="Volume $volume is Stable";
        }
    }else{
       $returnCode=CRITICAL;
       $returnMessage="Could not grep bricks";
    }
}elsif($result =~ m/Status: (\S+)/){
 $returnCode=CRITICAL;

 $returnMessage="Volume Status is $1";
}else{
    $returnCode=CRITICAL;
    $returnMessage="Could not grep Status $result for $volume";
}


Nagios::Plugin->new->nagios_exit(return_code => $returnCode,
  message => $returnMessage
);
