#!/usr/bin/perl -w
use strict;

my $DEBUG = 0;
#$DEBUG = 1;

=head2

APPLICATION     config

PURPOSE

    1. CONFIGURE THE DATABASE AND LOAD TABLES AND SKELETON DATA
    
    2. CONFIGURE CRON JOB TO CHECK LOAD BALANCER
    
    3. ADD 'admin' USER TO AGUA DATABASE
    
    4. FIX /etc/fstab TO ALLOW EC2 MICRO INSTANCES TO REBOOT PROPERLY
        
INPUT

    1. MODE OF ACTION, E.G., admin, config, cron

OUTPUT

    MYSQL DATABASE CONFIGURATION AND EDITED CONFIG FILE            

USAGE

sudo ./config.pl <--mode String> \ 
 [--key String] \ 
 [--value String] \ 
 [--help]

 --mode      :    admin | config | cron | ... (see below)
 --database  :    Name of database
 --inputfile:    Location of inputfile
 --logfile   :    Location of logfile
 --help      :    Print help info

The 'mode' options are as follows:

adminUser       Create the Linux user account for the admin user 

cron            Configure a cron job to monitor the StarCluster
                load balancer

disableSsh      Disable SSH password login

enableSsh       Enable SSH password login

fixFstab        Edit /etc/fstab to enable reboot for micro instances

mysql           Create mysql users (root, Agua user and Agua Test user) and linux
				accounts. I.e., run following: setMysqlRoot, setMysqlUser,
                setTestUser

loadDatabase	Reload mysql database - recreate tables and load data
				(Prompt for optional backup dump of existing database.)
				
				
reloadDatabase  Reload MySQL database from dump file (backs up
                existing data)

setMysqlUser    Set MySQL user name and password

setMysqlRoot    Set MySQL root user password

setTestUser     Set test MySQL user name and password


The config option is the default:

config          Do all of the above (default)


EXAMPLES

sudo config.pl --mode mysql --database xy

=cut

#### FLUSH BUFFER
$| = 1;

#my $whoami = `whoami`;
#if ( not $whoami =~/^root\s*$/ ) {
#	print "You must be root to run config.pl\n";
#	exit;
#}

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### EXTERNAL MODULES
use Getopt::Long;
use Data::Dumper;

#### INTERNAL MODULES
use Xy::Configure;
use Xy::DBaseFactory;
use Conf::Yaml;

#### GET OPTIONS
my $dumpfile    = 	"$Bin/../../db/dump/default.dump";
my $sqldir    	= 	"$Bin/../../db/sql";
my $mode        = 	"config";
my $dbtype		=	"MySQL";
my $database;
my $tableorder  =   "experiment,dataseries,slider";  #### FIRST FILES IN REVERSE ORDER
my $inputfile  = 	"$Bin/../../conf/config.yaml";
my $logfile     = 	"$Bin/../../log/xy-config.log";
my $SHOWLOG     =    2;
my $PRINTLOG    =    5;
my $help;
GetOptions (
    'mode=s'        => \$mode,
    'database=s'    => \$database,
    'inputfile=s'  => \$inputfile,
    'sqldir=s'    	=> \$sqldir,
    'dumpfile=s'    => \$dumpfile,
    'tableorder=s'  => \$tableorder,
    'logfile=s'     => \$logfile,
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $conf = Conf::Yaml->new({
    memory      =>  1,
    inputfile  =>  $inputfile,
    backup      =>  1,
    SHOWLOG     =>  2,
    PRINTLOG    =>  2,
    logfile     =>  $logfile
});

#### SET TABLES WHICH MUST BE LOADED FIRST DUE TO DEPENDENCIES (CONSTRAINT/FOREIGN KEY)
my $firsttables;
@$firsttables = split ",", $tableorder;

my $object = Xy::Configure->new({
    conf        =>  $conf,
    mode        =>  $mode,
    dbtype    	=>  $dbtype,
    database    =>  $database,
    inputfile  =>  $inputfile,
    logfile     =>  $logfile,
    sqldir    	=>  $sqldir,
    firsttables => $firsttables,
    dumpfile    =>  $dumpfile,
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG,
	errortype	=>	"text"
});

#### CHECK MODE
print "mode not supported: $mode\n" and exit if not $object->can($mode);
print "mode not supported (private method): $mode\n" and exit if $mode =~ /^_/;
print "database cannot be 'mysql'\n" and exit if defined $database and $database eq "mysql";

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
    
