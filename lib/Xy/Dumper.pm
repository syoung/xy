use Moose::Util::TypeConstraints;
use MooseX::Declare;
use Method::Signatures::Modifiers;

use strict;
use warnings;

#### USE LIB FOR INHERITANCE
use FindBin::Real;
use lib FindBin::Real::Bin() . "/..";

class Xy::Dumper with (Xy::Common::Util, Xy::Common::Logger) {

=pod

PACKAGE		Xy::Dumper

PURPOSE		DATABASE-RELATED UTILITIES

=cut

has 'outputfile'=> ( isa => 'Str|Undef', is => 'rw', default => undef );
has 'dumpfile'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );

#### EXTERNAL MODULES
use FindBin qw($Bin);
use File::Path;

####/////}}}

sub dumpToSql {
	my $self		=	shift;
	my $dumpfile	=	shift;
	my $outputdir	=	shift;
	$self->logDebug("dumpfile", $dumpfile);

	#### CHECK DEFINED
	print "Xy::Dumper::dumpToSql    dumpfile not defined\n" and return if not defined $dumpfile;
	print "Xy::Dumper::dumpToSql    outputdir not defined\n" and return if not defined $outputdir;

	#### CREATE DIRS
	my $sqldir = "$outputdir/sql";
	my $tsvdir = "$outputdir/tsv";
	$self->createDir($outputdir);
	$self->createDir($sqldir);
	$self->createDir($tsvdir);
	
	#### GET FILE CONTENTS
	open(FILE, $dumpfile) or die "Xy::Dumper::dumpToSql    Can't open dumpfile: $dumpfile\n";
	$/ = undef;
	my $contents = <FILE>;
	close(FILE);
	
	#### PARSE BLOCKS
	my @blocks = split "CREATE TABLE", $contents;
	$self->logDebug("no. blocks", $#blocks + 1);
	shift @blocks;
	foreach my $block ( @blocks ) {
		my ($create, $insert) = $self->parseBlock($block);
		my ($tablename) = $create =~ /^\s*\'([^\s^\']+)/;
		print "TABLENAME NOT DEFINED IN CREATE: $create\n" and exit if not defined $tablename;

		#### CLEAN QUOTES (HANDLE enum, DEFAULTS AND '')
		$create = $self->cleanQuotes($create);
		
		my $sqlfile = "$sqldir/$tablename.sql";
		$self->logDebug("sqlfile", $sqlfile);
		$self->printToFile($sqlfile, "CREATE TABLE $create\n");

		#### NEXT IF INSERT MISSING
		next if not defined $insert;

		#### OTHERWISE, CONVERT INSERT TO TSV
		my $tsvfile = "$tsvdir/$tablename.tsv";
		my $tsv = $self->insertToTsv($insert);
		$self->printToFile($tsvfile, $tsv);
	}
}

sub cleanQuotes {
#### CLEAN QUOTES (HANDLE enum, DEFAULTS AND '')
	my $self		=	shift;
	my $text		=	shift;
	
	my @lines = split "\n", $text;
	foreach my $line ( @lines ) {
		$self->logDebug("line", $line);
		
		#### HANDLE enum
		if ( $line =~ /enum/i ) {
			my ($before, $after) = $line =~ /^(.+)?(enum.+)$/;

			$before = $self->removeQuotes($before);
			$line = $before . $after;
		}
		elsif ( $line =~ /DEFAULT/i ) {
			my ($before, $after) = $line =~ /^(.+)?(DEFAULT.+)$/;

			$before = $self->removeQuotes($before);
			$line = $before . $after;
		}
		elsif ( $line =~ / COMMENT /i and not $line =~ / comment\s+\(/i ) {
			my ($before, $after) = $line =~ /^(.+?)(COMMENT.+)$/;			
			$before = $self->removeQuotes($before);
			$line = $before . $after;
		}
		else {
			$self->logDebug("DOING removeQuotes(line)");
			$line = $self->removeQuotes($line);
		}
	}
	$text = join "\n", @lines;
	
	return $text;
}

sub removeQuotes {
	my $self		=	shift;
	my $text		=	shift;
	
	#$self->logDebug("BEFORE text", $text);
	$text =~ s/([^'])'([^'])/$1$2/g;
	
	#### 2ND PASS TO AVOID STRANDED COMMENT:
	#### (workflow_queue_id,'flowcell_samplesheet_id) 
	$text =~ s/([^'])'([^'])/$1$2/g;  
	#$self->logDebug("AFTER text", $text);

	return $text;
}

sub parseBlock {
	my $self		=	shift;
	my $block	=	shift;

	my ($create)	=   $block =~ /^(.+)\n\n/ms;
	my ($insert)	=   $block =~ /Dumping data for table.+?(INSERT INTO.+?)\n\n/ms;
	$create =~ s/\n\).*$/\n\)/ms if defined $create;
	$create =~ s/\`/'/g if defined $create;
	$insert =~ s/\);.*$/\);/ms if defined $insert;
	$insert =~ s/\`/'/g if defined $insert;
	
	return $create, $insert;	
}

sub insertToTsv {
	my $self		=	shift;
	my $inserts		=	shift;
	my @blocks = split "INSERT INTO \\S+ VALUES ", $inserts;
	shift @blocks;
	my $tsv = '';
	foreach my $block ( @blocks ) {
		$block =~ s/^\(//;
		$block =~ s/\);\s*$//;

		my @lines = split "\\),\\(", $block;
		
		foreach my $line ( @lines ) {

			$line =~ s/^\s+//;
			my $elements = $self->getLineElements($line);
			
			my $counter = 0;
			foreach my $element ( @$elements ) {
				$counter++;
				$self->logDebug("counter", $counter);
				#next if $counter != 9;

				$self->logDebug("BEFORE element", $element);
				#### SPECIAL CASES: CLEAN UP BECAUSE INTERFERES WITH DATA
				#$element	=~ s/\\'//g;
				$element	=~ s/\-\-\-+//g;
				$element	=~ s/\\n/ /g;

				#### CLEAN LEADING AND TRAILING WHITESPACE
				$element 	=~ s/^\s+//;
				$element 	=~ s/\s+$//;

				#### HANDLE MYSQL NULL
				$element 	=~ s/^NULL$/\\N/g;
				$self->logDebug("AFTER element", $element);
			}
			
			$tsv .= join "\t", @$elements;
			$tsv .= "\n";
		}
		
	}
	$tsv =~ s/\n$//;
	
	return $tsv;	
}

sub getLineElements {
	my $self		=	shift;
	my $line		=	shift;

#### HANDLE LINES LIKE THIS WITH COMMAS INSIDE FIELDS, WHITESPACE AND TRAILING COMMAS:
### 1 , '  uscp-prd-lndt-1-2.local','C09LTACXX','2013-02-17 23:33:50','3.2.06','1.13.48','101,101','no',11, NULL ,NULL,   NULL,'SN901','/isilon/RUO/Runs/111102_SN901_0125_BC09LTACXX_Genentech','0000-00-00',0,'e6969d1b388f7119c78ac80eba36447f',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,,,,

	$self->logDebug("line", $line);
	
	my $elements	= 	[];
	my $start 		= 	0;
	my $end			=	0;
	my $counter 	= 	0;
	my $ender		=	"'";
	
	#### ALTERNATIVES (SPEED DIFFERENCE?):
	#### 1. GET ARRAYS OF POSITIONS OF "," AND "'" THEN REVERSE INTERCALATE
	#### 2. KEEP START/STOP POSITIONS AND DO SUBSTRING AT END OF EACH ELEMENT
	#### 3. USE element TO COLLECT STRING AS WE GO AND PUSH TO ELEMENTS AT END OF EACH ELEMENT
	
	#### USED: ALTERNATIVE 3
	my $element = '';
	if ( $line =~ /^\s*'/ ) {
		$ender = "'";
		$line =~ s/^\s+//;
	}
	else {
		$ender = ",";
	}
	#$self->logDebug("ender", $ender);
	
	#### LOOP THROUGH POSITIONS AND PUSH OFF ELEMENTS WHEN ENDED
	my $inside = 1;
	my @array = split ("", $line, -1);
	for ( my $i = 0; $i < $#array + 1; $i++ ) {
		$self->logDebug("array[$i]", $array[$i]);
		$self->logDebug("ender", $ender);
		
		#### CHECK FOR backslash-quote
		my $backslash = 0;
		$backslash = 1 if $i != 0 and $array[$i-1] eq "\\";
		
		if ( $array[$i] eq $ender and not $backslash ) {
			$inside = 1 if $i == 0 and $ender eq ",";
			$self->logDebug("pushing element", $element);
			push @$elements, $element if $inside or $element eq "";
			$inside = $inside ? 0 : 1;

			$element = '';

			#### SCOOT PAST COMMA IF ENDER IS "'"
			$self->logDebug("SKIPPING whitespace");
			$i = $self->skipWhiteSpace(\@array, $i);

			#### OUT OF LOOP IF PAST END OF ARRAY
			last if $i > $#array;
			
			$self->logDebug("SCOOTING PAST comma") if $ender eq "'" and $array[$i + 1] eq ",";
			$i++ if $ender eq "'" and $array[$i + 1] eq ",";
						
			$i = $self->skipWhiteSpace(\@array, $i);
			
			#### HANDLE CASES: ',' AND ',, and ',888
			$ender = "," if $array[$i + 1] ne "'";
			if ( $array[$i + 1] eq "'" ) {
				$ender = "'";
				$i++;
			}
			$self->logDebug("position $i + 1 new ender", $ender);
		}
		else {
			$inside = 1;
			$element .= $array[$i];
		}
	}
	#$self->logDebug("inside", $inside);
	push @$elements, $element if $inside;
	
	#$self->logDebug("elements", $elements);
	#$self->logDebug("DEBUG EXIT") and exit;
	
	
	return $elements;
}

sub skipWhiteSpace {
	my $self		=	shift;
	my $array		=	shift;
	my $index		=	shift;

	#$self->logDebug("BEFORE array[$index+ 1]", $$array[$index+ 1]);

	return $index if $index > scalar(@$array);	
	while ( $$array[$index + 1] eq " " ) {
		#$self->logDebug("removing whitespace at position", $index+ 1);
		$index++;
	}
	#$self->logDebug("AFTER array[$index+ 1]", $$array[$index+ 1]);
	
	return $index;
}

sub printToFile {
	my $self		=	shift;
	my $file		=	shift;
	my $text		=	shift;
	
	$self->logDebug("file", $file);

	$self->createParentDir($file);
	
	#### PRINT TO FILE
	open(OUT, ">$file") or print "Can't open file: $file\n" and exit;
	print OUT $text;
	close(OUT) or print "Can't close file: $file\n" and exit;
}

sub createParentDir {
	my $self		=	shift;
	my $file		=	shift;
	
	#### CREATE DIR IF NOT PRESENT
	my ($directory) = $file =~ /^(.+?)\/[^\/]+$/;
	`mkdir -p $directory` if $directory and not -d $directory;
	
	return -d $directory;
}

sub createDir {
	my $self		=	shift;
	my $directory	=	shift;
	#### CREATE OUTPUT DIRECTORY
	File::Path::mkpath($directory) if not -d $directory;
	print "Xy::Dumper::createDir    Can't create directory: $directory\n" and return 0 if not -d $directory;

	return 1;	
}

sub getFileContents {
	my $self		=	shift;
	my $file		=	shift;
	
	open(FILE, $file) or print "Can't open file: $file\n" and exit;
	my $temp = $/;
	$/ = undef;
	my $contents = 	<FILE>;
	close(FILE);
	$/ = $temp;

	return $contents;
}

} #### Xy::Dumper

