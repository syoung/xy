#!/usr/bin/perl -w

use Test::More  tests => 22;
use Getopt::Long;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;

#### INTERNAL MODULES
use Test::Agua::Common::Admin;
use Conf::Agua;

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile  =   "$installdir/conf/default.conf";

#### SET $Bin
$Bin =~ s/^.+t\/bin/$installdir\/t\/bin/;

my $logfile = "$Bin/outputs/aguatest.admin.log";

#### GET OPTIONS
my $SHOWLOG = 3;
my $PRINTLOG = 3;
my $help;
GetOptions (
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $conf = Conf::Agua->new(
	inputfile	=>	$configfile,
	memory		=>	1,
	backup		=>	1,
	separator	=>	"\t",
	spacer		=>	"\\s\+",
    logfile     =>  $logfile,
    SHOWLOG     =>  2,
    PRINTLOG    =>  2
);

#### SET DUMPFILE
my $dumpfile    =   "$Bin/../../../dump/create.dump";

my $object = new Test::Agua::Common::Admin (
    database    =>  "aguatest",
    dumpfile    =>  $dumpfile,
    conf        =>  $conf,
    json        =>  {
        username    =>  'syoung',
    	sessionId	=>	"1234567890.1234.123"
    },
    username    =>  "aguatest",
    project     =>  "Project1",
    workflow    =>  "Workflow1",
    logfile     =>  $logfile,
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG
);

my $json = {
    owner		=>	'aguatest',
    groupname	=>	'analysis',
    groupwrite	=>	0,
    groupcopy	=>	1,
    groupview	=>	1,
    worldwrite	=>	0,
    worldcopy	=>	0,
    worldview	=>	0
};
$object->testAddRemoveAccess($json);

$json = {
    username	=>	"aguatest",
    groupname	=>	"analysis",
    description	=>	"Analysis group",
    notes		=>	"Analysts and PIs only"
};
$object->testAddRemoveGroup($json);


#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}


__END__

GETACCESS

perl -U admin.cgi < t/admin-getAccess.json 
{"username":"admin","sessionId":"1228791394.7868.158","mode":"getAccess"}


GETUSERS

perl -U admin.cgi < t/admin-getUsers.json
{"username":"admin","sessionId":"1228791394.7868.158","mode":"getUsers"}


LOGIN

perl -U admin.cgi < t/admin-login-admin.json 
{"mode":"login","username":"admin","password":"xxxxxxx"}

perl -U admin.cgi < t/admin-login.json 
{"mode":"login","username":"syoung","password":"xxxxxxx"}

perl -U admin.cgi < t/admin-login-wrong.json 
{"mode":"login","username":"syoung","password":"xxxxxxx"}

perl -U admin.cgi < t/admin-login-singlequote.json 
{'mode':'login','username':'syoung','password':'xxxxxxx'}

