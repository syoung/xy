package Agua::Common::Parameter;
use Moose::Role;
use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Agua::Common::File
	
	PURPOSE
	
		APPLICATION PARAMETER AND STAGE PARAMETER METHODS FOR Agua::Common
		
=cut
use Data::Dumper;

##############################################################################
#				STAGEPARAMETER METHODS
##############################################################################

sub getParametersByStage {
#### RETURN AN ARRAY OF HASHES
	my $self			=	shift;
	my $stageobject	=	shift;
	$self->logNote("stageobject", $stageobject);

	my $required = ["username", "project", "workflow", "appname", "appnumber"];
	my $where = $self->db()->where($stageobject, $required);
	my $query = qq{SELECT * FROM stageparameter
$where};
	#$self->logDebug("$query");

	my $parameters = $self->db()->queryhasharray($query);
	$parameters = [] if not defined $parameters;
	#$self->logDebug("parameters", $parameters);

	return $parameters;
}

sub getParametersByApp {
#### RETURN AN ARRAY OF HASHES
	my $self			=	shift;
	my $appobject	=	shift;
	$self->logNote("appobject", $appobject);

	
	my $required = ["username", "package", "installdir", "appname"];
	my $where = $self->db()->where($appobject, $required);
	my $query = qq{SELECT * FROM parameter
$where};
	$self->logDebug("query", $query);
	
	my $parameters = $self->db()->queryhasharray($query);
	$parameters = [] if not defined $parameters;
	$self->logDebug("no. parameters", scalar(@$parameters)) if defined $parameters;
	$self->logDebug("parameters not defined") if not defined $parameters;
	
	return $parameters;
}

sub getStageParameters {
#### RETURN AN ARRAY OF HASHES
	my $self		=	shift;
	my $username	=	shift;
	$self->logDebug("Common::getStageParameters(username)");
	$self->logDebug("username", $username)  if defined $username;

    	my $json			=	$self->json();
	
	#### SET username IF NOT DEFINED
	$username = $json->{username} if not defined $username;

    #### VALIDATE    
    $self->logError("User session not validated") and return unless $self->validate();

	my $query = qq{SELECT * FROM stageparameter
WHERE username='$username'
ORDER BY project, workflow, appnumber, paramtype, name};
	$self->logDebug("$query");
	my $stageparameters = $self->db()->queryhasharray($query);
	$stageparameters = [] if not defined $stageparameters;

	$self->logDebug("stageparameters", $stageparameters);
	$self->logDebug("no. stageparameters", scalar(@$stageparameters));
	
	$self->logDebug("username", $username);
	my $fileroot = $self->getFileroot($username);
	$self->logDebug("fileroot", $fileroot);
	
	foreach my $stageparameter ( @$stageparameters ) {
		my $valuetype = $stageparameter->{valuetype};
		$self->logDebug("valuetype", $valuetype);
		my $name = $stageparameter->{name};
		$self->logDebug("name", $name);

		next if not $valuetype !~ /^file$/ and not $valuetype !~ /^directory$/;
		my $value = $stageparameter->{value};
		next if not defined $value or not $value;
		
		if ( $valuetype eq "file" or $valuetype eq "directory" ) {
			my $filepath = "$fileroot/$value";
			$self->logDebug("filepath", $filepath);
			$stageparameter->{fileinfo} = $self->getFileinfo($filepath);
			$self->logDebug("stageparameter->{fileinfo}", $stageparameter->{fileinfo});
		}
	}
	
	return $stageparameters;
}

=head2

	SUBROUTINE		addStageParameter
	
	PURPOSE

		ADD A PARAMETER TO THE stageparameter TABLE

	INPUTS
	
		1. ENOUGH STAGE INFORMATION FOR UNIQUE ID
		
			AND TO SATISFY REQUIRED TABLE FIELDS
		
{"project":"Project1","workflow":"Workflow1","appname":"clusterMAQ","name":"cpus","appnumber":"1","description":"","discretion":"optional","type":"integer","paramtype":"integer","value":"optasdfasdional","username":"admin","sessionid":"1234567890.1234.123","mode":"addStageParameter"}
        
=cut

sub addStageParameter {
	my $self		=	shift;

    my $json 		=	$self->json();
 	$self->logDebug("json", $json);

	$self->_removeStageParameter($json);

	my $success = $self->_addStageParameter($json);
	
 	$self->logError("Could not update stage parameter: $json->{name} in application $json->{appname}") if not defined $success;

 	$self->logStatus("Updated stage parameter $json->{name} in application $json->{appname}");
}

sub _removeStageParameter {
	my $self		=	shift;
	my $data		=	shift;
 	$self->logDebug("data", $data);

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "stageparameter";
	my $required_fields = ["username", "project", "workflow", "appname", "appnumber", "name", "paramtype"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;

	#### REMOVE IF EXISTS ALREADY
 	$self->logDebug("Doing _removeFromTable(table, data, required_fields)");
	return $self->_removeFromTable($table, $data, $required_fields);
}

sub _addStageParameter {
	my $self		=	shift;
	my $data		=	shift;
 	$self->logDebug("data", $data);

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "stageparameter";
	my $required_fields = ["username", "project", "workflow", "appname", "appnumber", "name", "paramtype"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;

	#### ADD ALL FIELDS OF THE PASSED STAGE PARAMETER TO THE TABLE
 	$self->logDebug("Doing addToTable(table, data, required_fields)");
	return $self->_addToTable($table, $data, $required_fields);	
}


=head2

    SUBROUTINE     addParameters
    
    PURPOSE

		COPY parameter TABLE ENTRIES FOR THIS APPLICATION

		TO stageparameter TABLE
		
=cut

sub addParameters {
	my $self		=	shift;

	$self->logDebug("Common::addParameters()");

    	my $json			=	$self->json();

	$self->logDebug("json", $json);

	#### GET APPLICATION OWNER
	my $owner = $json->{owner};
	
	#### GET PRIMARY KEYS FOR parameters TABLE
    my $username = $json->{username};
	my $appname = $json->{name};
	my $project = $json->{project};
	my $workflow = $json->{workflow};
	my $number = $json->{number};
	
	#### CHECK INPUTS
	$self->logError("appname $appname not defined or empty") and return if not defined $appname or $appname =~ /^\s*$/;
	$self->logError("username $username not defined or empty") and return if not defined $username or $username =~ /^\s*$/;
	$self->logDebug("username", $username);
	$self->logDebug("appname", $appname);

	#### DELETE EXISTING ENTRIES FOR THIS STAGE IN stageparameter TABLE
	my $success;
	my $query = qq{DELETE FROM stageparameter
WHERE username='$username'
AND project='$project'
AND workflow='$workflow'
AND appname='$appname'
AND appnumber='$number'};
	$self->logDebug("$query");
	$success = $self->db()->do($query);
	$self->logDebug("Delete success", $success);
	
	#### GET ORIGINAL PARAMETERS FROM parameter TABLE
	$query = qq{SELECT * FROM parameter
WHERE username='$owner'
AND appname='$appname'};
    $self->logDebug("$query");
    my $parameters = $self->db()->queryhasharray($query);
	$self->logError("no entries in parameter table") and return if not defined $parameters;
	
	##### SET QUERY WITH PLACEHOLDERS
	my $table = "stageparameter";
	my $fields = $self->db()->fields($table);
	#my $fields_csv = $self->db()->fields_csv($table);

	$success = 1;
	my $args = {
		project => $project,
		workflow => $workflow,
		username	=>	$username
	};
	foreach my $parameter ( @$parameters )
	{
		$parameter->{username} = $username;
		$parameter->{project} = $project;
		$parameter->{workflow} = $workflow;
		$parameter->{appnumber} = $number;

		#### INSERT %OPTIONAL% VARIABLES
		$parameter->{value} = $self->systemVariables($parameter->{value}, $args);

		#### DO INSERT
		my $values_csv = $self->db()->fieldsToCsv($fields, $parameter);
		my $query = qq{INSERT INTO $table 
	VALUES ($values_csv) };
		$self->logDebug("$query");
		my $do_result = $self->db()->do($query);
		$self->logDebug("do_result", $do_result);
		
		$success = 0 if not $do_result;
	}
	$self->logDebug("success", $success);
	
	return $success;
}



##############################################################################
#				PARAMETER METHODS
##############################################################################
sub getParameters {
	my $self		=	shift;

    my $username	= $self->username();
	my $admin = $self->conf()->getKey("agua", 'ADMINUSER');
	return [] if $admin ne $username;

	#### SET DEFAULT username IF NOT DEFINED
	$username = $self->conf()->getKey('agua', "ADMINUSER") if not defined $username;
    $self->logDebug("username", $username);

    #### VALIDATE    
    $self->logError("User session not validated") and return unless $self->validate();

	#### GET USER'S OWN APPS	
	my $agua = $self->conf()->getKey("agua", "AGUAUSER");
    my $query = qq{SELECT * FROM parameter
WHERE owner = '$agua'
ORDER BY apptype, appname};
    my $parameters = $self->db()->queryhasharray($query);
	$parameters = [] if not defined $parameters;

	return $parameters;
}

sub getAguaParameters {
	my $self		=	shift;

	#### GET USER'S OWN APPS	
	my $agua = $self->conf()->getKey("agua", "AGUAUSER");
    my $query = qq{SELECT * FROM parameter
WHERE owner = '$agua'
ORDER BY apptype, appname};
    my $parameters = $self->db()->queryhasharray($query);
	$parameters = [] if not defined $parameters;

	return $parameters;
}

sub getAdminParameters {
	my $self		=	shift;
	$self->logDebug("");

	#### GET admin USER'S APPS	
	my $admin = $self->conf()->getKey("agua", 'ADMINUSER');
    my $query = qq{SELECT * FROM parameter
WHERE owner = '$admin'
ORDER BY appname, apptype};
    my $apps = $self->db()->queryhasharray($query);
	$apps = [] if not defined $apps;
	
	return $apps;
}



1;