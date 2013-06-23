use MooseX::Declare;

=head2

	PACKAGE		Agua::Upload
	
	PURPOSE

		1. SAVE FILE CONTENTS TO TEMP FILE
		
		2. CHECK PRIVILEGES, QUIT IF INSUFFICIENT
		
		3. TRANSFER TEMP FILE TO DESTINATION DIRECTORY

=cut

class Agua::Upload with (Agua::Common::Logger,
	Agua::Common::Privileges,
	Agua::Common::Base,
	Agua::Common::Database,
	Agua::Common::Util) {

use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use PerlIO::eol;
use JSON;

#### INTERNAL MODULES
use Conf::Agua;
use Agua::Common::Exchange;


# Ints
has 'SHOWLOG'		=> ( isa => 'Int', is => 'rw', default 	=> 	2 	);  
has 'PRINTLOG'		=> ( isa => 'Int', is => 'rw', default 	=> 	2 	);
has 'maxnamelength'	=> ( isa => 'Int', is => 'rw', default 	=> 	80 	);
has 'validated'		=> ( isa => 'Int', is => 'rw', default => 0 );
has 'counter'		=> ( isa => 'Int', is => 'rw', default => -1 );
has 'maxindex'		=> ( isa => 'Int', is => 'rw', default => -1 );

# Strings
has 'whoami'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'details'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'username'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
#has 'sessionid'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'filename'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'tempfile'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'tempdir'	=> ( isa => 'Str|Undef', is => 'rw', default	=>	'/tmp'	);
has 'logfile'	=> ( isa => 'Str|Undef', is => 'rw', default	=>	'/tmp/upload.log'	);
has 'boundary'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'boundarynumber'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);

#### Objects
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'params'	=> ( isa => 'HashRef|Undef', is => 'rw', required	=>	0	);
has 'conf'		=> ( isa => 'Conf::Yaml', is => 'rw', required => 0 	);
has 'data'		=> ( isa => 'ArrayRef|Undef', is => 'rw', required	=>	0	);

# Objects
has 'exchange'
	=> (
	isa => 'Agua::Common::Exchange',
	is => 'rw',
	default	=>	sub {
		Agua::Common::Exchange->new({
			#logfile		=>	"$Bin/log/admin.head.log",
			SHOWLOG		=>	2
			#PRINTLOG	=>	5
		});
	}
);


####/////}}

=head2

	SUBROUTINE		BUILD
	
	PURPOSE

		GET AND VALIDATE INPUTS, AND INITIALISE OBJECT

=cut

method BUILD ($hash) {
	$self->initialise();
}

method initialise {
	#### OPEN LOGFILE
	my $logfile = $self->logfile() || "/tmp/upload.log";
	$self->logfile($logfile);
	$self->logDebug("");
}

method upload {
	#### GET DATA FROM STDIN IN STREAM OR ARRAY
	$self->setData();
	
	#### SET RECORD SEPARATOR AS BOUNDARY
	my $boundary = $self->getBoundary();
	$self->logDebug("boundary", $boundary);	

	#### PARSE FILENAME
	my $filename = $self->parseFilename();
	$self->logDebug("filename", $filename);
	
	#### PRINT CONTENTS TO FILE (STOP AT PARAMS)
	my $tempfile = $self->printTempfile($filename, $boundary);
	
	#### PARSE PARAMS FROM STDIN
	my $params = $self->parseParams();
	$params->{filename} = $filename;
	$params->{tempfile} = $tempfile;
	$self->logDebug("params", $params);
	$self->logDebug("params->{filename}", $params->{filename});

	#### SET TOKEN
	my $token =	$params->{token};
	
	#### VALIDATE USER
	my $status = $self->validateUser($params);
	$self->logDebug("validateUser status", $status);
	if ( ! $status ) {
		$self->notifyStatus({
			callback=> "postUpload",
			error	=> "User validation failed",
			queue	=> "routing",
			token	=>	$token,
			data	=>	$params
		});
		return;
	}
	
	#### PARSE MANIFEST FILE
	my $error;
	($params, $error) = $self->parseManifest($params) if $params->{mode} eq "manifest";
	$self->logDebug("parseManifest AFTER parseManifest    params", $params);
	$self->logDebug("parseManifest AFTER parseManifest    status", $status);
	if ( $error ) {
		$self->notifyStatus({
			callback=> "postUpload",
			error	=>	$error,
			queue	=> "routing",
			token	=>	$token,
			data	=>	$params
		});
		return;
	}
	
	#### VERIFY FILE TRANSFER
	if ( $params->{mode} eq "manifest" ) {
		$status = $self->transferManifest($params);
		$self->logDebug("transferManifest status", $status);
	}
	else {
		$status = $self->transferFile($params);
		$self->logDebug("transferFile status", $status);
	}
	
	if ( ! $status ) {
		$self->notifyStatus({
			callback=> "postUpload",
			error	=>	"Can't transfer file",
			queue	=> "routing",
			token	=>	$token,
			data	=>	$params
		});
		return;
	}
	
	#### SET UP OUTPUT DATA
	my $samples = $params->{samples};
	my $project	= {};
	foreach my $key ( keys %$params ) {
		$self->logDebug("key", $key);
		next if $key eq "samples";
		$project->{$key} = $params->{$key};
	}

	my $data = {};
	$data->{project} 	= 	$project;
	$data->{samples}	=	$samples;
	#$self->logDebug("data", $data);
	
	
	$self->notifyStatus({
		callback=> "postUpload",
		status	=> "uploaded",
		queue	=> "routing",
		token	=>	$token,
		data	=>	$data
	});	
}

method notifyStatus ($data) {
	
	$self->logDebug("DOING self->openConnection() with data", $data);
	$self->logDebug("self->exchange", $self->exchange());
	
	my $connection = $self->exchange()->openConnection();
	$self->logDebug("connection", $connection);
	sleep(1);
	
	$self->logDebug("DOING self->exchange()->sendData(data)");
	return $self->exchange()->sendData($data);
}

method parseFilename {
	my $input = $self->nextData();
	my $counter = 0;
	while ( $input !~ /Content-Disposition: (multipart\/)?form-data/i ) {
		$counter++;
		$input = $self->nextData();
		$self->logDebug("input", $input);
		last if $counter > 10 or $input =~ /Content-Disposition: (multipart\/)?form-data/i;
	}
	$self->logDebug("input", $input);
	
	my ($trash, $filename) = $input =~ /Content-Disposition:\s+(multipart\/)?form-data;\s+name="uploadedfiles\[\]";\s+filename="([^"]+)"/i;
	$self->logDebug("filename", $filename);

	return $filename;	
}

method printTempfile ($filename, $boundary) {
#### NB: TEMP UPLOAD DIR MUST BE 'chmod 0777 tempdir'
	$self->logDebug("filename", $filename);

	#### REMOVE 'Content-type' LINE AND EMPTY LINE AFTER IT
	my $input = $self->nextData();
	$self->logDebug("input", $input);
	while ( $input =~ /Content-type: / ) {
		$self->logDebug("DOING self->nextData");
		$input = $self->nextData();
		$self->logDebug("input", $input);
	}
	$self->logDebug("input", $input);
	
	#### SKIP EMPTY LINE
	my $emptyline = $self->nextData();
	$self->logDebug("emptyline", $emptyline);
	$self->logCritical("No empty line after 'Content-type:...', emptyline: $emptyline") if $emptyline ne "";
	
	my $tempdir 	= $self->tempdir(); 
	my $tempfile 	= $self->getTempfile($filename, $tempdir);
	#$self->logDebug("tempfile", $tempfile);
	
	#### WE EXPECT A BOUNDARY AT THE END OF THE FILE CONTENTS
	open(TEMPFILE, ">$tempfile") or die "Can't open tempfile: $tempfile\n";
	binmode TEMPFILE;
	my $line = $self->nextData();
	while ( $line !~ /[\-]+$boundary/ ) {
		last if not defined $line;
		print TEMPFILE $line, "\n";
		$line = $self->nextData();
	}
	close(TEMPFILE) or die "Can't close temp file: $tempfile\n";

	return $tempfile;
}

method parseParams {

	##### DEBUG
	#$/ = undef;
	#my $contents = <$stdin>;
	#$self->logNote("contents", $contents);
	#my $outfile = "/tmp/parseparams.temp";
	#open(OUT, ">$outfile") or die "Can't open outfile: $outfile\n";
	#print OUT $contents;
	##print OUT `env`;
	##my $dump = sprintf Dumper $ENV;
	##print OUT $dump;
	#close(OUT);
	#$self->logNote("DEBUG EXIT") and exit;

	my $params = {};
	$/ = "\n";	
	my $line;
	$self->logNote("OUTSIDE self->hasData", $self->hasData());
	while ( $self->hasData() ) {
		
		$self->logNote("INSIDE self->hasData", $self->hasData());
		$line = $self->nextData();
		$self->logNote("line", $line);
		
		next if not $line =~ /Content-Disposition: form-data; name="([^"]+)"/i;
		$self->logNote("MATCH AT line: $line");
		my $param = $1;
		next if $param eq "uploadedfiles[]";
		
		#### SKIP BLANK LINE
		$line = $self->nextData();

		$line = $self->nextData();
		last if not defined $line;
		
		my ($value) = $line =~ /^\s*(\S+)/;
		$value = "" if not defined $value;

		$self->logNote("param", $param);
		$self->logNote("value", $value);
		$params->{$param} = $value;
	}
	#$self->logNote("params", $params);

	return $params;
}

method getBoundary {
	my $contenttype = $ENV{CONTENT_TYPE};
	$self->logDebug("contenttype", $contenttype);
	my ($boundary) = $contenttype =~ /multipart\/form-data;\s*boundary=[\-]+([^-]+)/;
	$self->logDebug("boundary", $boundary);
	
	$self->boundary($boundary);
}

method validateUser($params) {
	$self->logDebug("params", $params);
	
	#### SANITY CHECK
	$self->logDebug("username not defined") and exit if not defined $params->{username};
	$self->logDebug("sessionid not defined") and exit if not defined $params->{sessionid};

	#### SET username AND sessionid
	my $username = $params->{username};
	my $sessionid = $params->{sessionid};
	$self->logDebug("username", $username);
	$self->logDebug("sessionid", $sessionid);
	$self->username($username);
	$self->sessionid($sessionid);

	#### SET DATABASE HANDLE
	$self->setDbh();
	
	#### VALIDATE
	$self->logDebug("Doing self->validate()");
	$self->logError("Validation failed for username", $username) and exit if not $self->validate();
	$self->logDebug("user validated", $username);

	return 1;
}

method transferFile ($params) {
#### TRANSFER DOWNLOADED FILE TO USER'S DIRECTORY
	$self->logDebug("");

	my $username 		= $self->username();
	my $maxnamelength 	= $self->maxnamelength();
	my $filename 		= $params->{filename};
	
	#### GET FILEROOT
	my $fileroot = $self->getFileroot($username);
	$self->logDebug("fileroot", $fileroot);
	$self->logDebug("No fileroot for user", $username) and exit if not defined $fileroot and not $fileroot;
	
	#### SET DESTINATION DIR INCLUDING INTERVENING PATH IF ANY
	my $destinationdir = "$fileroot";
	my $path = $params->{path};
	$self->logDebug("path", $path);
	$destinationdir .= "/$path" if defined $path and $path;
	$self->logDebug("destinationdir", $destinationdir);
	
	#### CHECK DESTINATION
	my $tempfile = $self->tempfile();
	my $found = -d $destinationdir;
	$self->logDebug("found", $found);
	
	#### GET FILE PATH
	$self->logDebug("DOING setFilepath");
	my $filepath = $self->setFilepath($filename, $destinationdir, $maxnamelength);
	$self->logDebug("filepath", $filepath);
	
	#### MOVE TEMP FILE TO DESTINATION DIRECTORY
	#### *** NB *** : THIS DOESN'T REPORT AN ERROR IF IT FAILS TO COPY
	#### -- FIX LATER	
	$self->logDebug("Doing File::Copy::move($tempfile, $filepath)");
	File::Copy::move($tempfile, $filepath) or $self->logDebug("Cannot move from tempfile: $tempfile to filepath", $filepath) and return 0;
	
	return 1;
}

method transferManifest ($params) {
#### TRANSFER DOWNLOADED FILE TO USER'S DIRECTORY
	$self->logDebug("params", $params);

	my $tempfile 		= 	$params->{tempfile};
	my $project 		= 	$params->{project_name};
	my $filename 		= 	$params->{filename};
	my ($installdir)	=	$self->conf()->getKey("installdir", undef);
	my $outputdir		=	"$installdir/files/project/$project";
	my $outputfile		=	"$outputdir/$filename";
	$self->logDebug("installdir", $installdir);
	$self->logDebug("tempfile", $tempfile);
	$self->logDebug("filename", $filename);
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("outputfile", $outputfile);

	#### CREATE OUTPUT DIR
	`mkdir -p $outputdir` if not -d $outputdir;
	return 0 if not -d $outputdir;
	
	#### REMOVE EXISTING OUTPUTFILE
	`rm -fr $outputfile`;
	
	#### MOVE TEMP FILE TO DESTINATION DIRECTORY
	`mv $tempfile $outputfile`;
	return 0 if not -f $outputfile;
	$self->logDebug("Transferred file", $tempfile);
	
	return 1;
}

method parseManifest ($params) {
#### PARSE PROJECT INFORMATION AND SAMPLES FROM MANIFEST FILE
	$self->logNote("params", $params);

	my $tempfile 		= 	$params->{tempfile};
	$self->logNote("tempfile", $tempfile);
	
	#### GET PROJECT FIELDS
	my $lines = $self->getLines($tempfile);
	$self->logNote("lines", $lines);
	
	my $data = [
		"institution_name",
		"principal_investigator",
		"project_name",
		"date_received",
		"description"
	];
	my $projectobject = {};
	
	foreach my $datum ( @$data ) {
		my $line = shift @$lines;
		my ($value) = $line =~ /^[^,]+,([^,]+)/;
		$projectobject->{$datum} = $value;
		
		#### ADD TO PARAMS FOR RETURN CONFIRMATION TO CLIENT
		$params->{$datum} = $value;
	}
	$self->logNote("projectobject", $projectobject);
	if ( not defined $projectobject->{project_name}) {
		$self->logNote("project_name not defined");
		return $params, "Cannot parse project name from manifest file. Verify that all five lines are present : Institute Name, Principal Investigator, Project Name, Date Received, Description";
	}
	
	#### VERIFY PROJECT DOES NOT ALREADY EXIST
	my $query = "SELECT 1 FROM project WHERE project_name='$projectobject->{project_name}'";
	$self->logNote("query", $query);
	my $exists = $self->db()->query($query);
	$self->logNote("exists", $exists);
	if ( $exists ) {
		$self->logNote("project exists");
		return $params, "project '$projectobject->{project_name}' already exists in database";
	}
	
	#### ADD PROJECT TO project TABLE
	my $success = $self->addProject($projectobject);
	if ( not $success ) {
		$self->logNote("problem adding project");
		return $params, "Could not add project '$projectobject->{project_name}' already exists in database";
	}
	
	#### RETRIEVE PROJECT ID
	$query = "SELECT project_id FROM project WHERE project_name='$projectobject->{project_name}'";
	$self->logNote("query", $query);
	my $projectid = $self->db()->query($query);
	$self->logNote("projectid", $projectid);

	#### SET project_id IN PARAMS
	$params->{project_id} = $projectid;
	
	#### VERIFY SAMPLES	
	my $table			=	"sample";
	my $fields			=	$self->db()->fields($table);
	$self->logNote("fields", $fields);
	my $headings;
	@$headings = split ",", shift @$lines;
	$self->logNote("headings", $headings);

	#### GET MAPPING BETWEEN FIELDS AND COLUMN HEADINGS	
	my $mapping = $self->getMappings();
	
	#### GET MAPPING BETWEEN COLUMN HEADINGS AND COLUMN NUMBERS
	my $columnmap = {};
	for ( my $i = 0; $i < @$headings; $i++ ) {
		$columnmap->{$$headings[$i]} = $i;
	}
	$self->logNote("columnmap", $columnmap);
	
	#### GET FIELD TYPES	
	#my ($installdir)	=	$self->conf()->getKey("agua", "INSTALLDIR");
	my ($installdir)	=	$self->conf()->getKey("installdir", undef);
	$self->logNote("installdir", $installdir);
	my $sqlfile 		=	"$installdir/db/sql/$table.sql";
	$self->logNote("sqlfile", $sqlfile);
	my $types = $self->db()->fieldTypes($sqlfile);
	$self->logNote("types", $types);
	#$self->logNote("DEBUG EXIT") and exit;
		
	$self->logNote("lines", $lines);
		
	#### LOAD SAMPLES	
	my $samples = [];
	my $requiredfields = ["project_id", "sample_id", "sample_barcode"];
	my $counter = 0;
	foreach my $line ( @$lines ) {
		$counter++;
		$self->logNote("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX counter", $counter);
		my @elements = split ",", $line;
		$self->logNote("elements", \@elements);

		my $hash = {};
		foreach my $field ( @$fields ) {
			$self->logNote("field", $field);
			my $heading = $mapping->{$field};
			$self->logNote("heading", $heading);
			if ( $heading eq "" ) {
				$hash->{$field} = "";
				next;
			}

			my $column = $columnmap->{$heading};
			
			if ( not defined $column or not $column ) {
				$hash->{$field} = "";
				next;
			}
			$self->logNote("column", $column);
			
			my $value = $elements[$column];
			$self->logNote("value", $value);
			$hash->{$field} = $value;

			my $passed = $self->db()->verifyFieldType($types, $field, $value);
			$self->logNote("passed", $passed);
			if ( not $passed ) {
				$self->logNote("problem adding sample");
				return ($params, "Failed to validate field '$field' (value: $value) in line $counter of samples");
			}
			
			$hash->{project_id} = $projectid;
		}
		$self->logNote("hash", $hash);

		push @$samples, $hash;
		
		my $success = $self->db()->_addToTable($table, $hash, $requiredfields, $fields);
		$self->logNote("success", $success);
				
		if ( not defined $success ) {
			$self->logNote("problem adding sample");
			return ($params, "Could not add sample in line $counter of samples");
		}
	}
	$self->logNote("counter", $counter);
	
	$params->{samples} = $samples;
	
	return $params, "";
}

method getMappings {
	return {
		"sample_id"			=>	"",	
		"project_id"		=>	"",
		"sample_barcode"	=>	"Sample Well",	
		"sample_name"		=>	"Sample ID",	
		"plate_barcode"		=>	"Plate Barcode",	
		"species"			=>	"Species",	
		"gender"			=>	"Gender (M/F/U)",	
		"volume"			=>	"Volume (ul)",	
		"concentration"		=>	"Concentration (ng/ul)",	
		"od_260_280"		=>	"OD 260/280",	
		"tissue_source"		=>	"Tissue Source",	
		"extraction_method"	=>	"Extraction Method",	
		"ethnicity"			=>	"Ethnicity",	
		"parent_1_sample_id"=>	"Parent 1 ID",	
		"parent_2_sample_id"=>	"Parent 2 ID",	
		"replicates_id"		=>	"Replicate(s) ID",	
		"cancer"			=>	"Cancer sample (Y/N)",	
		"match_sample_ids"	=>	"Matched Sample ID(s)",	
		"match_sample_type"	=>	"Matched Sample Type",	
		"comment"			=>	"Comment",	
		"due_date"			=>	"",	
		"target_fold_coverage"	=>	"",	
		"gt_gender"			=>	"",	
		"do_build"			=>	"",	
		"status_id"			=>	"",	
		"sample_policy"		=>	"",	
		"update_date"		=>	"",	
		"delivered_date"	=>	"",	
		"genotype_report"	=>	"",	
		"gt_deliv_src"		=>	"",	
		"user_code_and_ip"	=>	"",	
		"FTAT"				=>	"",	
		"analysis"			=>	"",	
		"gt_call_rate"		=>	"",	
		"gt_p99_cr"			=>	""
	};
}

method fileContents ($filename) {	
	my $endline = $/;
	$/ = undef;
	open(FILE, $filename) or die "[Util::contents] Can't open file '$filename'\n";
	my $contents = <FILE>;
	close(FILE);
	$/ = $endline;

	return $contents;
}

method addProject ($object) {
	my $table 	=	"project";
	my $requiredfields = [ "project_name" ];
	my $fields 	=	$self->db()->fields($table);
	my $success = 	$self->db()->_addToTable($table, $object, $requiredfields, $fields);
	$self->logDebug("success", $success);

	return 0 if not defined $success;
	
	return 1;
}
	
method getTempfile ($filename, $tempdir) {
	$self->logDebug("filename", $filename);
	$self->logDebug("tempdir", $tempdir);

	my $tempfile = "$tempdir/$filename" . rand(10000000);
	$tempfile = "$tempdir/$filename" . rand(10000000) while ( -e $tempfile );
	$self->tempfile($tempfile);
	#$self->logDebug("tempfile", $tempfile);

	return $tempfile;
}

method setFilepath ($filename, $directory, $maxnamelength) {
	#$self->logDebug("");
    $self->logDebug("filename", $filename);
    $self->logDebug("directory", $directory);
    $self->logDebug("maxnamelength", $maxnamelength);

    #### GET SHORTENED FILENAME
    if ( $filename =~ /(.+)\.(.+)/ ) {
        my ($fn,$ext) = ($1,$2);
        $fn = substr($fn, 0, $maxnamelength);
    
        #### RETURN SHORTENED FILENAME IF NOT EXISTS
        return "$directory/$fn.$ext" if not -e "$directory/$fn.$ext";
    
        ### CHANGE THE FILE NAME 
        my $i = 0;
        $i++ while ( -e "$directory/$fn.$i.$ext" );
    
		#### MOVE THE EXISTING FILE TO THE SHORT NAME
		#### AND UPLOAD THE FILE USING THE LONG NAME
		$self->logDebug("transferUpload    Doing File::Copy::move('$directory/$fn.$ext', '$directory/$fn.$i.$ext')...");

		use File::Copy;
		File::Copy::move("$directory/$fn.$ext", "$directory/$fn.$i.$ext") or die "{    error: 'Cannot move from file: $directory/$fn.$ext to file: $directory/$fn.$i.$ext' ";

        $self->logDebug("Returning $fn.$ext");
        return "$directory/$fn.$ext";
    }
    else {
        my $fn = substr($filename, 0, $maxnamelength);
    
        #### RETURN SHORTENED FILENAME IF NOT EXISTS
        return "$directory/$fn" if not -e "$directory/$fn";
    
        ### CHANGE THE FILE NAME 
        my $i = 0;
        $i++ while ( -e "$directory/$fn.$i" );
    
		#### MOVE THE EXISTING FILE TO THE SHORT NAME
		#### AND UPLOAD THE FILE USING THE LONG NAME
		$self->logDebug("Doing File::Copy::move('$directory/$fn', '$directory/$fn.$i')...");
		use File::Copy;
		File::Copy::move("$directory/$fn", "$directory/$fn.$i") or $self->logError("Cannot move from file: $directory/$fn to file $directory/$fn.$i") and exit;
	
        $self->logDebug("Returning $fn");
        return "$directory/$fn";
    }
}



method parseParam ($params, $line) {
#### LEGACY : REMOVE
	$self->logNote("params", $params);
	$self->logNote("line", $line);
	
	$line =~ /^.+?name="([^"]+)"/;
	my $param = $1;
	my $value = $2;
	$self->logNote("param", $param);
	$self->logNote("value", $value);

	return $params if not defined $param;

	if ( not defined $value ) {
		$params->{$param} = '';
		return $params;
	}
	
	$value =~ s/\s+$//;
	$value =~ s/\s*[\-]+$//;
	$self->logNote("value", $value);
	
	$params->{$param} = $value if defined $value;
	$self->logNote("params", $params);
	
	return $params;
}


method nextData {
#### LATER: MAKE CGI PLAY NICE WITH STDIN FILEHANDLE

	#### INCREMENT SELF COUNTER
	$self->counter($self->counter() + 1);
	$self->logNote("self->counter", $self->counter() . ${$self->data()}[$self->counter()]);
	
	return ${$self->data()}[$self->counter()];	
}

method hasData {
	$self->logNote("self->counter", $self->counter());
	#$self->logNote("self->maxindex", $self->maxindex());
	return 1 if $self->counter() < $self->maxindex();

	return 0;
}

method setData {
	$/ = undef;
	my $stream = <STDIN>;
	#$self->logNote("stream", $stream);
	
	#### SET DATA
	$stream =~ s/\r\r/\r\r\r/g;
	$stream =~ s/\n\n/\n\n\n/g;
	my @array = split /[\n\r]{1,2}/, $stream;
	#$self->logNote("array", \@array);
	#
	#$self->logNote("DEBUG EXIT") and exit;
	
	#@array = split /\r/, $stream if not @array;
#	$self->logNote("FINAL array", \@array);
#$self->logNote("DEBUG EXIT") and exit;


	$self->data(\@array);
	
	for ( 0 .. $#array ) {
		$self->logNote("data[$_]", ${$self->data()}[$_]);
	}
	#$self->logNote("DEBUG EXIT") and exit;
	

	#### SET COUNTER
	$self->counter(-1);

	#### SET MAX INDEX
	$self->maxindex($#array);
}



} #### Upload.pm
