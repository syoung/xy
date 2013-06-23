#!/usr/bin/perl

my $DEBUG = 0;
$DEBUG = 1;

#### REDIRECT STDOUT AND STDERR TO FILE
#my $outfile = "./xy.out";
#open(STDOUT, ">$outfile");
#open(STDERR, ">$outfile");

use FCGI; # Imports the library; required line

# Initialization code

$cnt = 0;

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/lib";
use lib "/agua/lib";
use lib "/agua/lib";

#### INTERNAL MODULES
#use Agua::Workflow;
#use Agua::DBaseFactory;
use Conf::Yaml;

#### EXTERNAL MODULES
#use DBI;
#use DBD::SQLite;
use Data::Dumper;

#### TIME BEFORE
my $time;
BEGIN {
    use Devel::Peek;
    use Time::HiRes qw[gettimeofday tv_interval];
    $time = [gettimeofday()];	    
}
print "xy.pl    TIME: $time\n" if $DEBUG;

#### SET LOG
my $SHOWLOG     =   2;
my $PRINTLOG    =   4;

#### GET CONF
my $conf = Conf::Yaml->new({
    inputfile	=>  "$Bin/conf/config.yaml",
    backup	    =>  1,
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG    
});

print "xy.pl    BEFORE loadModules: ", tv_interval($time), "\n" if $DEBUG;
$time = [gettimeofday()];	    

#### LOAD MODULES
my $modules = loadModules($conf);
my @keys = keys %$modules;
print "xy.pl    modules: @keys\n" if $DEBUG;
print "xy.pl    AFTER loadModules: ", tv_interval($time), "\n" if $DEBUG;

#### COUNTER
my $cnt = 0;

#### RESPONSE LOOP
while ( FCGI::accept >= 0 ) {

my $begintime = time();

print "Content-type: text/html\r\n\r\n";
$| = 1;
$cnt++;

#### SET WHOAMI
my $whoami = `whoami`;
chomp($whoami);

### GET PUTDATA
my $input	= <STDIN>;
#my $input	= $ARGV[0];
`echo '$input' > ./input.json`;
print "{ error: 'xy.pl    input not defined' }" and exit if not defined $input or not $input or $input =~ /^\s*$/;

#### GET JSON
my $json = getJson($input);
$json->{whoami} = $whoami;

#### CLEAN INPUTS AND CONFIRM REQUIRED INPUTS
my $required = q(whoami username mode module);
print "REQUIRED: $required\n" if $DEBUG;
cleanInputs($json, $required);

#### CHECK INPUTS
checkInputs($json, $required);

#### GET MODE
my $mode = $json->{mode};
warn "$mode $whoami $cnt\n";
print "{ error: 'xy.pl    mode not defined' }" and exit if not defined $mode;

#### GET USERNAME
my $username = $json->{username};
print "{ error: 'xy.pl    username not defined' }" and exit if not defined $username;

#### GET MODULE
my $module = $json->{module};

#### SET LOGFILE
my $logfile     =   "$Bin/log/$username.$module.log";
$logfile =~ s/::/-/g;
$conf->logfile($logfile);

#### GET OBJECT
my $object = $modules->{$module};
print "{ error: 'xy.pl    module not supported: $module' }" and exit if not defined $object and $DEBUG;

#### SET OBJECT LOGFILE AND INITIALISE
$object->logfile($logfile);
$object->initialise($json);

#### CHECK OBJECT 'CAN' mode
print "{ error: 'xy.pl    mode not supported: $mode' }" and exit if not $object->can($mode);

#### RUN QUERY
no strict;
$object->$mode();
use strict;

#### DEBUG INFO
my $endtime = time();
warn "total: " . ($endtime - $begintime) . "\n";

EXITLABEL: {};

}   # while (FCGI::accept >= 0) {

sub getJson {
    my $input   =   shift;
    
    use JSON;
    my $jsonParser = JSON->new();
    my $json = $jsonParser->allow_nonref->decode($input);
    
    return $json;
}

sub cleanInputs {
    my $json    =   shift;
    my $keys    =   shift;
    print "{ 'error' : 'xy.pl	   JSON not defined' }" and exit if not defined $json;

    foreach my $key ( @$keys ) {
        $json->{$key} =~ s/;`//g;
        $json->{$key} =~ s/eval//g;
        $json->{$key} =~ s/system//g;
        $json->{$key} =~ s/exec//g;
    }
}

sub checkInputs {
    my $json    =   shift;
    my $keys    =   shift;
    print "{ 'error' : 'xy.pl    JSON not defined' }" and exit if not defined $json;

    foreach my $key ( @$keys ) {
        print "{ 'error' : 'xy.pl	   JSON not defined' }" and exit if not defined $json->{$key};
    }
}

sub loadModules {
    my $installdir = $conf->getKey("installdir", undef);
    my $modulestring = $conf->getKey("modules", undef);
    print "xy.pl    modulestring: $modulestring\n" if $DEBUG;
    my @modulenames = split ",", $modulestring;

    my $modules;
    foreach my $modulename ( @modulenames) {
    
        my $modulepath  =   $modulename;
        $modulepath     =~  s/::/\//g;
        my $location    =   "$installdir/lib/$modulepath.pm";
        print "xy.pl    location: $location\n" if $DEBUG;
        require $location;
        my $class       =   $modulename;
        print "xy.pl    class: $class\n" if $DEBUG;
        eval("use $class");
    
        my $object = $class->new({
            conf        =>  $conf,
            SHOWLOG     =>  $SHOWLOG,
            PRINTLOG    =>  $PRINTLOG
        });
        print "xy.pl    object: $object\n" if $DEBUG;
        
        $modules->{$modulename} = $object;
    }

    return $modules; 
}
