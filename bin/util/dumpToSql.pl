#!/usr/bin/perl -w

=head2

APPLICATION     dumpToSql

PURPOSE     CONVERT DUMP FILE TO *.sql CREATE TABLE FILES AND *.tsv DATA FILES

INPUT

    1. LOCATION OF INPUT DUMP FILE
    
    2. LOCATION TO DIRECTORY FOR OUTPUT *.sql AND *.tsv FILE SUBDIRECTORIES

OUTPUT

    1. FOR EACH TABLE IN THE DATABASE:
    
        -   ONE *.sql CREATE TABLE FILE

        -   ONE *.tsv FILE CONTAINING THE DATA FOR THE TABLE

USAGE

./dumpToSql.pl <--db String> <--outputdir String> [-h] 

--dumpfile    :   Location of dump file
--outputdir   :   Location of directory for output files in 'sql' and 'tsv' subdirs
--help        :   print this help message

< option > denotes REQUIRED argument
[ option ] denotes OPTIONAL argument

EXAMPLE

./dumpToSql.pl \
--outputdir /xy/db/dump \
--dumpfile /xy/db/dump/xy.dump


=cut

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### INTERNAL MODULES
use Xy::Dumper;

#### EXTERNAL MODULES
use Data::Dumper;
use Getopt::Long;

#### GET OPTIONS
my $db;
my $dumpfile;
my $outputdir;	
my $help;
my $SHOWLOG     =   2;
my $PRINTLOG    =   2;
GetOptions (
	'dumpfile=s' => \$dumpfile,
	'outputdir=s' => \$outputdir,
	'SHOWLOG=s' => \$SHOWLOG,
	'PRINTLOG=s' => \$PRINTLOG,
	'help' => \$help) or die "No options specified. Try '--help'\n";
if ( defined $help )	{	usage();	}

#### FLUSH BUFFER
$| =1;

#### CHECK INPUTS
die "Output directory not defined (option --outputdir)\n" if not defined $outputdir; 
die "File with same name as output directory already exists: $outputdir\n" if -f $outputdir;

#### CONVERT DUMP TO SQL AND TSV FILES
my $object = Xy::Dumper->new({
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG
});
#print "object:\n";
#print Dumper $object;

$object->dumpToSql($dumpfile, $outputdir);


sub usage { `perldoc $0`;   }
