#!/usr/bin/perl

use FCGI; # Imports the library; required line

# Initialization code

$cnt = 0;

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/lib";
use lib "/agua/lib";
use lib "/agua/lib";

#### INTERNAL MODULES
use Agua::Workflow;
use Agua::DBaseFactory;
use Conf::Yaml;

#### EXTERNAL MODULES
use JSON;
use DBI;
use DBD::SQLite;
use Data::Dumper;

#### TIME BEFORE    
use Devel::Peek;
use Time::HiRes qw[gettimeofday tv_interval];
my $time = [gettimeofday()];	

#### SET LOG
my $SHOWLOG     =   2;
my $PRINTLOG    =   4;

#### GET CONF
my $conf = Conf::Yaml->new(
	configfile	=>	"$Bin/conf/config.yaml",
	backup		=>	1,
    SHOWLOG     =>  2,
    PRINTLOG    =>  4
);

#### LOAD MODULES
my $modules = loadModules($conf);

# Response loop
while (FCGI::accept >= 0) {

my $begintime = time();

print "Content-type: text/html\r\n\r\n";
$| = 1;
$cnt++;

### GET PUTDATA
my $input	= <STDIN>;
print "{ error: 'agua.pl    input not defined' }" and exit if not defined $input or not $input or $input =~ /^\s*$/;

#### GET JSON
my $json = getJson($input);

#### SET WHOAMI
my $whoami = `whoami`;
chomp($whoami);
$json->{whoami} = $whoami;

#### SET REQUIRED INPUTS
my $required = qw(whoami username mode module);

#### CLEAN INPUTS
cleanInputs($json, $required);

#### CHECK INPUTS
checkInputs($json, $required);

#### GET MODE
my $mode = $json->{mode};
warn "$mode $whoami $cnt\n";
print "{ error: 'agua.pl    mode not defined' }" and exit if not defined $mode;

#### GET USERNAME
my $username = $json->{username};
print "{ error: 'view.cgi    username not defined' }" and exit if not defined $username;
#warn "Instantiate Conf::Agua: ", tv_interval($time), "\n";

#### GET MODULE
my $module = $json->{module};

#### SET LOGFILE
my $logfile     =   "$Bin/log/$username.$module.log";
$conf->logfile($logfile);

#### GET OBJECT
my $object = $modules->{$module};

my $jsonparser = JSON->new();
my @keys = keys %$modules;
#print "keys: @keys\n";
my $mods = encode_json(\@keys);
#print "mods: $mods\n";
print "{ error: 'module not supported: $module'. Not found in modules: $mods }" and exit if not defined $object;

#### SET OBJECT LOGFILE AND INITIALISE
$object->logfile($logfile);
$object->initialise($json);

#### CHECK OBJECT 'CAN' mode
print "{ error: 'mode not supported: $mode' }" and exit if not $object->can($mode);

#### RUN QUERY
no strict;
$object->$mode();
use strict;

#### DEBUG INFO
my $endtime = time();
warn "total: " . ($endtime - $begintime) . "\n";

EXITLABEL: { warn "Doing EXIT\n"; };

}   # while (FCGI::accept >= 0) {


##################################################################

sub getJson {
    my $input   =   shift;
    
    my $jsonParser = JSON->new();
    my $json = $jsonParser->allow_nonref->decode($input);
    
    return $json;
}

sub cleanInputs {
    my $json    =   shift;
    my $keys    =   shift;
    print "{ 'error' : 'agua.pl	JSON not defined' }" and exit if not defined $json;

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
    print "{ 'error' : 'agua.pl	JSON not defined' }" and exit if not defined $json;

    foreach my $key ( @$keys ) {
        print "{ 'error' : 'agua.pl	JSON not defined' }" and exit if not defined $json->{$key};
    }
}

sub loadModules {
    my $modules;
    my $installdir = $conf->getKey("installdir", undef);
    my $modulestring = $conf->getKey("modules", undef);
    #my $installdir = $conf->getKey("agua", "INSTALLDIR");
    #my $modulestring = $conf->getKey("agua", "MODULES");
    #$modulestring = "Admin,Folders,Package,Sharing,Upload,View,Workflow";
    #$modulestring = "Admin";
    #$modulestring = "Folders";
    #$modulestring = "Package";
    #$modulestring = "Sharing";
    #$modulestring = "Upload";
    #$modulestring = "View";
    #$modulestring = "Workflow";    
    print "modulestring: $modulestring\n";
    my @modulenames = split ",", $modulestring;
    foreach my $modulename ( @modulenames) {
    
        my $location    = "$installdir/lib/Agua/$modulename.pm";
        print "location: $location\n";
        #require $location;
        my $class       = "Infusion::$modulename";
        print "class: $class\n";
        eval("use $class");
    
        my $object = $class->new({
            conf        =>  $conf,
            SHOWLOG     =>  $SHOWLOG,
            PRINTLOG    =>  $PRINTLOG
        });
        print "object: $object\n";
        
        $modules->{$modulename} = $object;
    }

    return $modules; 
}
