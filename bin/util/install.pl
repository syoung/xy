#!/usr/bin/perl -w
use strict;

my $DEBUG = 0;
$DEBUG = 1;

=pod

APPLICATION     install

PURPOSE

    1. INSTALL THE DEPENDENCIES FOR xy
    
    2. CREATE THE REQUIRED DIRECTORY STRUCTURE
    
INPUT

    1. INSTALLATION DIRECTORY (DEFAULT: /xy)
    
    2. www DIRECTORY (DEFAULT: /var/www)
        
OUTPUT

    1. REQUIRED DIRECTORY STRUCTURE AND PERMISSIONS
    
        FOR PROPER RUNNING OF Agua
        
    2. RUNNING APACHE INSTALLATION CONFIGURED FOR Agua
    
    3. RUNNING MYSQL INSTALLATION AWAITING MYSQL DATABASE
    
        CONFIGURATION WITH CONFIG

USAGE

sudo ./install.pl <--mode String]
 <--installdir String> [--apachedir String]
 [--userdir String] [--wwwdir String] [--wwwuser String] \
 [--domainname String] [--logfile String] [--newlog] [--help]

 --mode          :   Installation option (see ./install.pl -h for options)
 --target        :   Target directory to install repository to (e.g., /myDir)
 --urlprefix     :   Prefix to URL
                     (e.g., http://myhost.com/urlprefix/xy.html)
                     (default: xy)
 --userdir       :    Path to users home directory (default: /home)
 --wwwdir        :    Path to 'WWW' directory (default: /var/www)
 --wwwuser       :    Name of apache user (default: "www-data")
 --apachedir     :    Path to apache installation (default: /etc/apache2)
 --domainname    :   Domain name to use for CA certificate
 --logfile       :    Print log to this file
 --newlog        :   Flag to create new log file and backup old
 --help          :   Print help info
 
EXAMPLES

sudo install.pl --mode linkDirectories --installdir /xy --urlprefix xy

=cut

#### FLUSH BUFFER
$| = 1;

my $whoami = `whoami`;
if ( not $whoami =~/^root\s*$/ ) {
	print "You must be root to run config.pl\n";
	exit;
}

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### EXTERNAL MODULES
use Getopt::Long;

#### INTERNAL MODULES
use Xy::Installer;

#### GET OPTIONS
my $mode        = "install";
my $urlprefix   = "xy";
my $installdir  = "$Bin/../..";
my $userdir     = "/home";
my $apachedir   = "/etc/apache2";
my $wwwdir      = "/var/www";
my $wwwuser     = "www-data";
my $logfile     = "/tmp/xy-install.log";
my $database;
my $domainname;
my $newlog;
my $help;
GetOptions (
    'mode=s'        =>  \$mode,
    'urlprefix=s'   =>  \$urlprefix,
    'installdir=s'  =>  \$installdir,
    'database=s'    =>  \$database,
    'apachedir=s'   =>  \$apachedir,
    'domainname=s'  =>  \$domainname,
    'userdir=s'     =>  \$userdir,
    'wwwdir=s'      =>  \$wwwdir,
    'wwwuser=s'     =>  \$wwwuser,
    'logfile=s'     =>  \$logfile,
    'newlog=s'      =>  \$newlog,
    'help'          =>  \$help
) or die "No options specified. Try '--help'\n";

#### PRINT HELP IF REQUESTED
if ( defined $help )	{	usage();	}

#### CHECK IF URL PREFIX EXISTS
my $urlprefixpath = "$wwwdir/$urlprefix";
print "install.pl    urlprefix directory already exists: $urlprefix\n" and exit if -d $urlprefixpath;

my $object = Xy::Installer->new(
    {
        urlprefix   =>  $urlprefix,
        installdir  =>  $installdir,
        database    =>  $database,
        apachedir   =>  $apachedir,
        domainname  =>  $domainname,
        userdir     =>  $userdir,
        wwwdir      =>  $wwwdir,
        wwwuser     =>  $wwwuser,
        logfile     =>  $logfile,
        newlog      =>  $newlog
    }
);

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
    
