#!/usr/bin/perl -w
use strict;

my $DEBUG = 0;
#$DEBUG = 1;

=head2

APPLICATION     deploy

PURPOSE

    1. INSTALL KEY AGUA DEPENDENCIES
    
INPUT

    1. MODE OF ACTION, E.G., deploy, bioapps, biorepo, sge, starcluster

OUTPUT

    MYSQL DATABASE CONFIGURATION AND EDITED CONFIG FILE            

USAGE

sudo ./deploy.pl \
 [--mode String] \ 
 [--configfile String] \ 
 [--logfile String] \ 
 [--help]

 --mode      :    deploy | bioapps | biorepo | ... options (see below)
 --configfile:    Location of configfile
 --logfile   :    Location of logfile
 --help      :    Print help info

The 'mode' options are as follows:

aguatest    Install the Agua tests package

bioapps     Install the Bioapps package

biorepo     Install the Biorepository package

sge         Install the SGE (Sun Grid Engine) package

starcluster Install the StarCluster package

deploy      (DEFAULT) Do all of the above


EXAMPLES

Install all dependencies
sudo deploy.pl

Install only the Biorepository package
sudo deploy.pl --mode biorepo

=cut

#### FLUSH BUFFER
$| = 1;

my $whoami = `whoami`;
if ( not $whoami =~/^root\s*$/ ) {
	print "You must be root to run deploy.pl\n";
	exit;
}

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### EXTERNAL MODULES
use Getopt::Long;
use Data::Dumper;

#### INTERNAL MODULES
use Agua::Deploy;
use Agua::DBaseFactory;
use Conf::Agua;

#### GET OPTIONS
my $mode         = "deploy";
my $configfile   = "$Bin/../../conf/default.conf";
my $logfile      = "/tmp/agua-deploy.log";
my $SHOWLOG      =    2;
my $PRINTLOG     =    5;
my $help;
GetOptions (
    'mode=s'        => \$mode,
    'configfile=s'  => \$configfile,
    'logfile=s'     => \$logfile,
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $conf = Conf::Agua->new(
    memory      =>  0,
    inputfile   =>  $configfile,
    backup      =>  1,
    SHOWLOG     =>  2,
    PRINTLOG    =>  2,
    logfile     =>  $logfile
);

my $object = Agua::Deploy->new({
    conf        =>  $conf,
    mode        =>  $mode,
    inputfile  	=>  $configfile,
    logfile     =>  $logfile,
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG
});

#### CHECK MODE
print "mode not supported: $mode\n" and exit if not $object->can($mode);
print "mode not supported (private method): $mode\n" and exit if $mode =~ /^_/;

#### RUN QUERY
no strict;
eval { $object->$mode() };
if ( $@ ){
    print "Error: $mode): $@\n";
}
print "\nCompleted $0\n";

sub usage {
    print `perldoc $0`;
    exit;
}
    
