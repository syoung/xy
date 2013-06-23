use Moose::Util::TypeConstraints;
use MooseX::Declare;
use Method::Signatures::Modifiers;

#### USE LIB FOR INHERITANCE
use FindBin::Real;
use lib FindBin::Real::Bin() . "/..";

use Xy::Common::Database;

class Xy::Base with (Xy::Common::Util, Xy::Common::Logger, Xy::Common::Database, Xy::Common::Privileges, Xy::Common::Login) {

# Booleans
has 'validated'	=> ( isa => 'Int', is => 'rw', default => 0 );

# Ints
has 'SHOWLOG'	=>  ( isa => 'Int', is => 'rw', default => 1 );  
has 'PRINTLOG'	=>  ( isa => 'Int', is => 'rw', default => 1 );
	
# Strings
has 'logfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'username'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'sessionid'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'logfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'fileroot'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'table'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'keys'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'oldvalue'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'newvalue'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'field'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );

# Objects
has 'query'	=> ( isa => 'HashRef|Undef', is => 'rw', default => undef );
has 'data'	=> ( isa => 'HashRef|Undef', is => 'rw', default => undef );
has 'db'	=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Conf::Yaml',
	default	=>	sub {	Conf::Yaml->new();	}
);

####////}}}}

=head2

=head2 API

SUBROUTINE		getData

PURPOSE

	RETURN JSON STRING OF ALL REQUIRED TABLE DATA AT STARTUP OR REFRESH
	
INPUT

	1. USERNAME
	
	2. SESSION ID
	
OUTPUT
	
	1. JSON HASH
	
		{
			"projects":[
				{"project": "project1",...},
				{"project": "project2", ...},
				...
			],
			...
		}

=cut

method initialise ($arguments) {
	$self->setSlots($arguments);

	$self->logDebug("arguments", $arguments);

	#### SET DATABASE HANDLE
	$self->setDbh();	
}

=head2 API

SUBROUTINE:		getData

PURPOSE:

	Retrieve all data tables the user has access to
	
USAGE

INPUTS

	username
		type		:	String
		value		:	Default value or set/range of values, e.g., 1|2|3|4|5 or 1..5
		discretion	:	required
		description	:	Name of the user
		
	sessionid
		type		:	String
		discretion	:	required
		description	:	Session ID of the user, e.g., NNNNNNNNNN.NNNN.NNN where N is a digit
		value		:	
		

OUTPUTS

	data
		type		:	JSON
		description	:	All the table entries commensurate with the user's access privileges
		
EXAMPLE

	{
		username: 	"testuser",
		sessionid: 	"0000000000.0000.000"
	}


=cut


method getData {
	#### DETERMINE IF USER IS ADMIN USER
    my $username 		= 	$self->username();
	my $isadmin 		= 	$self->isAdminUser($username);

	#### GET TABLES
	my $tables 			=	$self->conf()->getKey("tables", undef);
#	$self->logDebug("tables", $tables);
#$self->logDebug("DEBUG EXIT") and exit;

	
	#### ADMIN-ONLY
	$tables->{users} 	= 	"users" if $self->isAdminUser($username);

	#### GET OUTPUT
	my $output;
	my @keys = keys %$tables;
	foreach my $key ( sort @keys ) {
		
		$self->logDebug("key", $key);
		
		#next if $key ne "sample" and $key ne "lane" and $key ne "project" and $key ne "flowcell" and $key ne "requeuereport" and $key ne "flowcelllaneqc" and $key ne "trimreport" and $key ne "flowcellreporttrim" and $key ne "status" and $key ne "workflow" and $key ne "workflow_queue";
		#next if $key ne "sample" and $key ne "lane" and $key ne "project";
		#next if $key ne "sample" and $key ne "lane";
		
		my $data = $self->_getTable($tables->{$key});
		#$self->logDebug("data", $data);
		$output->{$key} = $data;
	}

	$self->logDebug("output: $output");
	$output = {} if not defined $output;
	
	#### PRINT JSON AND EXIT
	use JSON -support_by_pp; 
	my $jsonParser = JSON->new();
	
	my $jsonText = encode_json($output);
	#my $jsonText = $jsonParser->encode->allow_nonref->($output);
	#my $jsonText = $jsonParser->encode->allow_nonref->get_utf8->($output);
	#my $jsonText = $jsonParser->encode->allow_nonref->pretty->get_utf8->($output);
    #my $jsonText = $jsonParser->pretty->indent->encode($output);
    #my $jsonText = $jsonParser->encode($output);

	#### TO AVOID HIJACKING --- DO NOT--- PRINT AS 'json-comment-optional'
	print "{}&&$jsonText";
	return;
}

method getConf {
	my $conf;
	$conf->{agua}->{opsrepo} 	=	$self->conf()->getKey("agua", "OPSREPO");
	$conf->{agua}->{privateopsrepo} =	$self->conf()->getKey("agua", "PRIVATEOPSREPO");
	$conf->{agua}->{appsdir} 	=	$self->conf()->getKey("agua", "APPSDIR");
	$conf->{agua}->{installdir}	=	$self->conf()->getKey("agua", "INSTALLDIR");
	$conf->{agua}->{reposubdir}	=	$self->conf()->getKey("agua", "REPOSUBDIR");
	$conf->{agua}->{repotype}	=	$self->conf()->getKey("agua", "REPOTYPE");
	$conf->{agua}->{aguauser}	=	$self->conf()->getKey("agua", "AGUAUSER");
	$conf->{agua}->{adminuser}	=	$self->conf()->getKey("agua", "ADMINUSER");

	##### SET LOGIN
	#my $username = $self->username();
	#my $query = qq{SELECT login FROM hub WHERE username='$username'};
	#my $login = $self->db()->query($query);
	#$self->logDebug("login", $login);
	#$conf->{agua}->{login}	=	$login;
	
	return $conf;	
}

method _getTable ($table) {
=head2

	SUBROUTINE		getTable
	
	PURPOSE

		RETURN THE OBJECT CONTAINING ALL ENTRIES IN THE DESIGNATED TABLE

	INPUT
	
		1. USERNAME
		
		2. SESSION ID
        
        3. TABLE PROXY NAME, E.G., "stageParameters" RETURNS RELATED
        
            'stageparameter' TABLE ENTRIES
		
	OUTPUT
		
		1. JSON HASH { "projects":[ {"project": "project1","workflow":"...}], ...}

=cut
$self->logDebug("table", $table);
	my $query = qq{SELECT * FROM $table};
	$self->logDebug("query", $query);

	return $self->db()->queryhasharray($query);
}


=head2 API

SUBROUTINE:		_updateTable

PURPOSE:

	Update database table:
	
		-	Update an existing entry if present. Removes existing entry and replaces with
				
			user-provided data object.

		-	Add a new entry if not present
				
INPUTS
		
	Required inputs:

		data:
			type	    :   HashRef
			discretion	:	required
			description	:	Contains all the required fields to be
							inserted into the table
			
		table:
			type	    :   String project
			discretion	:	required
			description	:	Name of table to be updated
		
	Optional inputs:
		
		keys:
			type	    :   ArrayRef
			discretion	:	optional
			description	:	Contains primary keys to uniquely
							identify the table entry
		
OUTPUTS

	result	:	1 (success), undef (failure), 0E0 (no rows returned)
		

=cut

method createExperiment () {
	my $query = $self->query();
	$self->logDebug("query", $query);
	my $experiment 	=	 $query->{experiment};
	my $username	=	$self->username();
	
	my $exists = $self->experimentExists($username, $experiment);	
	$self->logDebug("exists", $exists);	

}

method experimentExists ($username, $experiment) {
	my $query = qq{SELECT 1 FROM experiment
WHERE username='$username'
AND experiment='$experiment'};
	my $exists = $self->db()->query($query);
	$self->logDebug("exists", $exists);
	
}

method _updateTable ($table, $data, $required_fields, $set_data, $set_fields){

 	$self->logNote("Common::_updateTable(table, data, required_fields, set_fields)");
    $self->logError("data not defined") and return if not defined $data;
    $self->logError("required_fields not defined") and return if not defined $required_fields;
    $self->logError("set_data not defined") and return if not defined $set_data;
    $self->logError("set_fields not defined") and return if not defined $set_fields;
    $self->logError("table not defined") and return if not defined $table;

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;

	#### GET WHERE
	my $where = $self->db()->where($data, $required_fields);

	#### GET SET
	my $set = $self->db()->set($set_data, $set_fields);
	$self->logError("set values not defined") and return if not defined $set;

	##### UPDATE TABLE
	my $query = qq{UPDATE $table $set $where};           
	$self->logDebug("$query");
	my $result = $self->db()->do($query);
	$self->logDebug("result", $result);
	
	return $result;
}

method updateProject () {
	#### VALIDATE
	my $username = $self->username();
	$self->logError("Can't validate user '$username'") and exit if not $self->validate();

	#### UPDATE
	my $data = $self->data();
	my $success = $self->_updateProject($data);
	$self->logDebug("success", $success);

	#### NO WARNING
	$data->{project_name} = "" if not defined $data->{project_name};
	
	#### REPORT
	if ( $success eq "0E0" ) {
		$self->logError("Update failed - no project '$data->{project_name}' in database");
	}
	else {
		$self->logStatus("Updated project '$data->{project_name}'", $data);
	}	
}
	
method _updateProject ($data) {
	my $requiredfields 	= [ "project_id", "project_name" ];
	my $table = "project";
	my $fields	=	$self->db()->fields($table);
	$self->logDebug("fields", $fields);
	
	return $self->_updateTable($table, $data, $requiredfields, $data, $fields);
}

method updateSample () {
	#### VALIDATE
	my $username = $self->username();
	$self->logError("Can't validate user '$username'") and exit if not $self->validate();

	#### UPDATE
	my $data = $self->data();
	my $success = $self->_updateSample($data);
	$self->logDebug("success", $success);

	#### NO WARNING
	$data->{sample_barcode} = "" if not defined $data->{sample_barcode};
	
	#### REPORT
	if ( $success eq "0E0" ) {
		$self->logError("Update failed - no sample '$data->{sample_barcode}' in database");
	}
	else {
		$self->logStatus("Updated sample '$data->{sample_barcode}'", $data);
	}	
}
	
method _updateSample ($data) {
	my $requiredfields 	= [ "sample_id", "sample_barcode", "project_id" ];
	#my $requiredfields 	= [ "sample_id" ];
	my $table = "sample";
	my $fields	=	$self->db()->fields($table);
	$self->logDebug("fields", $fields);
	
	return $self->_updateTable($table, $data, $requiredfields, $data, $fields);
}

method updateFlowcell () {
	#### VALIDATE
	my $username = $self->username();
	$self->logError("Can't validate user '$username'") and exit if not $self->validate();

	#### UPDATE
	my $data = $self->data();
	my $success = $self->_updateFlowcell($data);
	$self->logDebug("success", $success);

	#### NO WARNING
	$data->{flowcell_barcode} = "" if not defined $data->{flowcell_barcode};
	
	#### REPORT
	if ( $success eq "0E0" ) {
		$self->logError("Update failed - no flowcell '$data->{flowcell_barcode}' in database");
	}
	else {
		$self->logStatus("Updated flowcell '$data->{flowcell_barcode}'", $data);
	}	
}
	
method _updateFlowcell ($data) {
	my $requiredfields 	= [ "flowcell_id" ];
	my $table = "flowcell";
	my $fields	=	$self->db()->fields($table);
	$self->logDebug("fields", $fields);
	
	return $self->_updateTable($table, $data, $requiredfields, $data, $fields);
}

method updateLane () {
	#### VALIDATE
	my $username = $self->username();
	$self->logError("Can't validate user '$username'") and exit if not $self->validate();

	#### UPDATE
	my $data = $self->data();
	my $success = $self->_updateLane($data);
	$self->logDebug("success", $success);

	#### NO WARNING
	$data->{lane_barcode} = "" if not defined $data->{lane_barcode};
	
	#### REPORT
	if ( $success eq "0E0" ) {
		$self->logError("Update failed - no lane '$data->{lane_barcode}' in database");
	}
	else {
		$self->logStatus("Updated lane '$data->{lane_barcode}'", $data);
	}	
}
	
method _updateLane ($data) {
	my $requiredfields 	= [ "lane_id", "flowcell_id", "sample_id" ];
	my $table = "lane";
	my $fields	=	$self->db()->fields($table);
	$self->logDebug("fields", $fields);
	
	return $self->_updateTable($table, $data, $requiredfields, $data, $fields);
}

method addProject ($data) {
	$self->logDebug("data", $data);
	
	my $requiredfields 	= [ "project_id", "project_name" ];
	my $table = "project";
	my $fields	=	$self->db()->fields($table);
	$self->logDebug("fields", $fields);
	
	return $self->_addToTable($table, $data, $requiredfields, $fields);
}

method addSample ($data) {
	my $requiredfields 	= [ "sample_id", "sample_barcode", "project_id" ];
	my $table = "project";
	my $fields	=	$self->db()->fields($table);
	$self->logDebug("fields", $fields);
	
	return $self->_addToTable($table, $data, $requiredfields, $fields);
}

method addFlowcell ($data) {
	my $requiredfields 	= [ "flowcell_id" ];
	my $table = "project";
	my $fields	=	$self->db()->fields($table);
	$self->logDebug("fields", $fields);
	
	return $self->_addToTable($table, $data, $requiredfields, $fields);
}

method addLane ($data) {
	my $requiredfields 	= [ "lane_id", "flowcell_id", "sample_id" ];
	my $table = "project";
	my $fields	=	$self->db()->fields($table);
	$self->logDebug("fields", $fields);
	
	return $self->_addToTable($table, $data, $requiredfields, $fields);
}

method _addToTable {
=head2

	SUBROUTINE		_addToTable
	
	PURPOSE

		ADD AN ENTRY TO A TABLE
        
	INPUTS
		
		1. NAME OF TABLE      

		2. ARRAY OF KEY FIELDS THAT MUST BE DEFINED 

		3. HASH CONTAINING TABLE FIELD KEY-VALUE PAIRS
        
=cut

	my $table			=	shift;
	my $hash			=	shift;
	my $required_fields	=	shift;
	my $inserted_fields	=	shift;
	
	#### CHECK FOR ERRORS
    $self->logError("hash not defined") and return if not defined $hash;
    $self->logError("required_fields not defined") and return if not defined $required_fields;
    $self->logError("table not defined") and return if not defined $table;
	
	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($hash, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;

	#### GET ALL FIELDS BY DEFAULT IF INSERTED FIELDS NOT DEFINED
	$inserted_fields = $self->db()->fields($table) if not defined $inserted_fields;

	$self->logError("fields not defined") and return if not defined $inserted_fields;
	my $fields_csv = join ",", @$inserted_fields;
	
	##### INSERT INTO TABLE
	my $values_csv = $self->db()->fieldsToCsv($inserted_fields, $hash);
	my $query = qq{INSERT INTO $table ($fields_csv)
VALUES ($values_csv)};           
	$self->logDebug("$query");
	my $result = $self->db()->do($query);
	$self->logDebug("result", $result);
	
	return $result;
}

method _removeFromTable ($table, $hash, $required_fields) {
=head2

	SUBROUTINE		_removeFromTable
	
	PURPOSE

		REMOVE AN ENTRY FROM A TABLE
        
	INPUTS
		
		1. HASH CONTAINING TABLE FIELD KEY-VALUE PAIRS
		
		2. ARRAY OF KEY FIELDS THAT MUST BE DEFINED 

		3. NAME OF TABLE      
=cut
 	
    #### CHECK INPUTS
    $self->logError("hash not defined") and return if not defined $hash;
    $self->logError("required_fields not defined") and return if not defined $required_fields;
    $self->logError("table not defined") and return if not defined $table;

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($hash, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;

	#### DO DELETE 
	my $where = $self->db()->where($hash, $required_fields);
	my $query = qq{DELETE FROM $table
$where};
	$self->logNote("\n$query");
	my $result = $self->db()->do($query);
	$self->logNote("Delete result", $result);		;
	
	return 1 if defined $result;
	return 0;
}

method arrayToArrayhash ($array, $key) {
=head2

    SUBROUTINE:     arrayToArrayhash
    
    PURPOSE:

        CONVERT AN ARRAY INTO AN ARRAYHASH, E.G.:
		
		{
			key1 : [ entry1, entry2 ],
			key2 : [ ... ]
			...
		}

=cut
	
	#$self->logNote("array: @$array");
	#$self->logNote("key", $key);

	my $arrayhash = {};
	for my $entry ( @$array )
	{
		if ( not defined $entry->{$key} )
		{
			$self->logNote("entry->{$key} not defined in entry. Returning.");
			return;
		}
		$arrayhash->{$entry->{$key}} = [] if not exists $arrayhash->{$entry->{$key}};
		push @{$arrayhash->{$entry->{$key}}}, $entry;		
	}
	
	#$self->logNote("returning arrayhash", $arrayhash);
	return $arrayhash;
}



}

#### Xy::Base

