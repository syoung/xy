#!/usr/bin/perl -w

use Test::More  tests => 1;

use FindBin qw($Bin);
use lib "$Bin/../../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
}

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile    =   "$installdir/conf/default.conf";

use Test::Agua::Uml::Role;
use Getopt::Long;
use FindBin qw($Bin);
use Conf::Agua;

#### GET OPTIONS
my $SHOWLOG     =   2;
my $PRINTLOG    =   5;
my $help;
GetOptions (
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

#### SET LOG
my $logfile = "$Bin/outputs/defaults.log";

#### SET CONF
my $conf = Conf::Agua->new(
    memory      =>  1,
    inputfile	=>	$configfile,
    SHOWLOG     =>  2,
    PRINTLOG    =>  2,
    logfile     =>  $logfile
);

my $object = new Test::Agua::Uml::Role (
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG,
    logfile     =>  $logfile,
    conf        =>  $conf
);

#### TO DO:
#### TEST
$object->testSetRoles();
#$object->testSetCalls();
#$object->testSetRoleName();
#$object->testSetMethods();

##### CLEAN UP
#`rm -fr $Bin/outputs/*`
