#!/usr/bin/perl -w

use Test::More  tests => 2; #qw(no_plan);

use FindBin qw($Bin);
use lib "$Bin/../../../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;


#### SET DUMPFILE
my $dumpfile    =   "$Bin/../../../../../dump/agua.dump";

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile    =   "$installdir/conf/default.conf";

use Test::Agua::Common::Package::Insert;
use Getopt::Long;
use FindBin qw($Bin);
use Conf::Agua;

#### SET LOG
my $SHOWLOG     =   2;
my $PRINTLOG    =   5;
my $logfile = "$Bin/outputs/insert.log";

#### GET OPTIONS
my $login;
my $token;
my $keyfile;
my $help;
GetOptions (
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'login=s'       => \$login,
    'token=s'       => \$token,
    'keyfile=s'     => \$keyfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

#### LOAD LOGIN, ETC. FROM ENVIRONMENT VARIABLES
$login = $ENV{'login'} if not defined $login or not $login;
$token = $ENV{'token'} if not defined $token;
$keyfile = $ENV{'keyfile'} if not defined $keyfile;

if ( not defined $login
    or not defined $token
    or not defined $keyfile ) {
    plan 'skip_all' => "Missing login, token or keyfile. Run this script manually and provide GitHub login and token credentials and SSH private keyfile";
}

my $whoami = `whoami`;
$whoami =~ s/\s+//g;
print "Must run as root\n" and exit if $whoami ne "root";

my $conf = Test::Conf::Agua->new(
    memory      =>  1,
    inputfile	=>	$configfile,
    SHOWLOG     =>  2,
    PRINTLOG    =>  2,
    logfile     =>  $logfile
);

#### GET TEST USER
my $username    =   $conf->getKey("database", "TESTUSER");

my $object = new Test::Agua::Common::Package::Insert(
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG,
    logfile     =>  $logfile,
    dumpfile    =>  $dumpfile,
    conf        =>  $conf,

    login       =>  $login,
    token       =>  $token,
    keyfile     =>  $keyfile,
    username    =>  $username
);

#### START LOG AFRESH
$object->startLog($object->logfile());

#### LOAD DATABASE
$object->setUpTestDatabase();

#### SET TEST DATABASEROW
$object->setTestDatabaseRow();

#### TEST INSERT ROW INTO DATABASE
$object->testInsertData();

#### CLEAN UP
`rm -fr $Bin/outputs/*`

