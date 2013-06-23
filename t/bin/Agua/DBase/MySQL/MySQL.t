#!/usr/bin/perl -w

=head2
	
APPLICATION 	MySQL.t

PURPOSE

	Test Agua::DBase::MySQL module
	
NOTES

	1. RUN AS ROOT
	
	2. BEFORE RUNNING, SET ENVIRONMENT VARIABLES, E.G.:
	
		export installdir=/aguadev

=cut

use Test::More 	tests => 7;
use Getopt::Long;
use FindBin qw($Bin);
use lib "$Bin/../../../../lib";
BEGIN {
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;

BEGIN {
    use_ok('Test::Agua::DBase::MySQL');
}
require_ok('Test::Agua::DBase::MySQL');

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile	=   "$installdir/conf/default.conf";

#### SET $Bin
$Bin =~ s/^.+\/bin/$installdir\/t\/bin/;

#### GET OPTIONS
my $logfile 	= "/tmp/aguatest.dbase.mysql.log";
my $SHOWLOG     =   5;
my $PRINTLOG    =   5;
my $help;
GetOptions (
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'logfile=s'     => \$logfile,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

#### SET DUMPFILE
my $dumpfile    =   "$Bin/../../../../../db/dump/xy.dump";

my $object = new Test::Agua::DBase::MySQL(
    dumpfile    =>  $dumpfile,
    logfile     =>  $logfile,
	SHOWLOG     =>  $SHOWLOG,
	PRINTLOG    =>  $PRINTLOG
);
isa_ok($object, "Test::Agua::DBase::MySQL", "object");

#### METHOD TESTS
$object->testFieldTypes();
$object->testFileFields();
$object->testVerifyFieldType();

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}

