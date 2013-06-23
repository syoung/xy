package Agua::Common::App;
use Moose::Role;
use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Agua::Common::App
	
	PURPOSE
	
		APPLICATION METHODS FOR Agua::Common
		
=cut
use Data::Dumper;


sub getAppHeadings {
	my $self		=	shift;

    	my $json			=	$self->json();

	$self->logDebug("");

	#### VALIDATE    
    my $username = $json->{username};
	$self->logError("User $username not validated") and return unless $self->validate($username);

	#### CHECK REQUESTOR
	print qq{ error: 'Agua::Common::App::getHeadings    Access denied to requestor: $json->{requestor}' } if defined $json->{requestor};
	
	my $headings = {
		leftPane => ["Packages", "Parameters"],
		middlePane => ["Parameters", "App", "Modules"],
		rightPane => ["Parameters", "App", "Packages"]
	};
	$self->logDebug("headings", $headings);
	
    return $headings;
}


sub getApps {
	my $self		=	shift;
	
    my $username	= $self->username();
	my $admin = $self->conf()->getKey("agua", 'ADMINUSER');
	return [] if $admin ne $username;
	
	my $appspackage = $self->conf()->getKey("agua", "APPSPACKAGE");
	
	#### GET AGUA USER AND ADMIN USER APPS	
	my $agua = $self->conf()->getKey("agua", "AGUAUSER");
    my $query = qq{SELECT * FROM app
WHERE owner = '$username'
ORDER BY package, type, name};
	$self->logDebug("query", $query);
    my $apps = $self->db()->queryhasharray($query);
	
	$apps = [] if not defined $apps;
	
	return $apps;
}

sub getAguaApps {

	my $self		=	shift;
	
    my $username;
	$username = $self->json()->{username} if defined $self->json();
    $username = $self->username() if not defined $username;

	my $appspackage = $self->conf()->getKey("agua", "APPSPACKAGE");
	
	#### GET AGUA USER AND ADMIN USER APPS	
	my $agua = $self->conf()->getKey("agua", "AGUAUSER");
    my $query = qq{SELECT * FROM app
WHERE owner = '$agua'
ORDER BY package, type, name};
	$self->logDebug("query", $query);
    my $apps = $self->db()->queryhasharray($query);
	
	$apps = [] if not defined $apps;
	
	return $apps;
}

sub getAdminApps {
	my $self		=	shift;
	$self->logDebug("");

	my $json			=	$self->json();

	#### VALIDATE    
    my $username = $json->{username};
    my $sessionid = $json->{sessionid};
    $self->logError("User $username not validated") and exit unless $self->validate($username, $sessionid);
	$self->logDebug("User validated", $username);

	#### ADMIN USER'S PUBLIC PACKAGES FROM package TABLE
	my $admin = $self->conf()->getKey("agua", 'ADMINUSER');
	my $query = qq{SELECT package FROM package
WHERE username='$admin'
AND privacy='public'};
	$self->logDebug("query", $query);
	my $packages = $self->db()->queryarray($query);

	$packages = [] if not defined $packages;
	$self->logDebug("packages", $packages);
	
	my $and = "";
	for ( my $i = 0; $i < @$packages; $i++ ) {
		my $package 	=	$$packages[$i];
		$and	.=	" AND ( package= '$package'\n" if $i == 0;
		$and	.=	" OR package= '$package'\n" if $i != 0;
	}
	$and .= ")" if $and;
	
	#### GET admin USER'S APPS	
    $query = qq{SELECT * FROM app
WHERE owner = '$admin'
$and
ORDER BY package, type, name};
    my $sharedapps = $self->db()->queryhasharray($query);
	$sharedapps = [] if not defined $sharedapps;

	$self->logDebug("sharedapps", $sharedapps);
	
	return $sharedapps;
}

sub deleteApp {
=head2

    SUBROUTINE:     deleteApp
    
    PURPOSE:

        VALIDATE THE admin USER THEN DELETE AN APPLICATION
		
=cut

	my $self		=	shift;

	my $data = $self->json()->{data};
	$data->{owner} = $self->json()->{username};
	$self->logDebug("data", $data);

	my $success = $self->_removeApp($data);
	return if not defined $success;

	$self->logStatus("Deleted application $data->{name}") if $success;
	$self->logError("Could not delete application $data->{name} from the apps table") if not $success;
	return;
}

sub _removeApp {
	my $self		=	shift;
	my $data		=	shift;

	my $table = "app";
	my $required = ["owner", "package", "name", "type"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($data, $required);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;

	#### REMOVE
	return $self->_removeFromTable($table, $data, $required);
}

sub saveApp {
=head2

    SUBROUTINE:     saveApp
    
    PURPOSE:

        SAVE APPLICATION INFORMATION
		
=cut

	my $self		=	shift;

    	my $json			=	$self->json();
	$self->logDebug("json", $json);
	
	#### GET DATA FOR PRIMARY KEYS FOR apps TABLE:
	####    name, type, location
	my $data = $json->{data};
	my $name = $data->{name};
	my $type = $data->{type};
	my $location = $data->{location};
	
	#### CHECK INPUTS
	$self->logError("Name $name not defined or empty") and return if not defined $name or $name =~ /^\s*$/;
	$self->logError("Name $type not defined or empty") and return if not defined $type or $type =~ /^\s*$/;
	$self->logError("Name $location not defined or empty") and return if not defined $location or $location =~ /^\s*$/;
		
	$self->logDebug("name", $name);
	$self->logDebug("type", $type);
	$self->logDebug("location", $location);

	#### SET owner AS USERNAME
	$data->{owner} = $json->{username};
	
	#### EXIT IF ONE OR MORE PRIMARY KEYS IS MISSING	
	$self->logError("Either name, type or location not defined") and return if not defined $name or not defined $type or not defined $location;

	#### GET APP IF ALREADY EXISTS
	my $table = "app";
	my $fields = ["owner", "package", "name", "type"];
	my $where = $self->db()->where($data, $fields);
	my $query = qq{SELECT * FROM $table $where};
	$self->logDebug("query", $query);
	my $app = $self->db()->queryhash($query);
	$self->logDebug("app", $app);
	
	#### REMOVE APP IF EXISTS
	if ( defined $app ) {
		$self->_removeApp($data);

		#### ... AND COPY OVER DATA ONTO APP
		foreach my $key ( keys %$data ) {
			$app->{$key} = $data->{$key};
		}
		$self->logDebug("app", $app);		

		#### ADD APP MODIFIED WITH DATA
		my $success = $self->_addApp($app);

	}
	
	#### ADD DATA
	my $success = $self->_addApp($data);
	$self->logDebug("success", $success);
	$self->logError("Could not insert application $name into app table ") and return if not $success;

	$self->logStatus("Inserted application $name into app table");
	return;
}

sub _addApp {
	my $self		=	shift;
	my $data		=	shift;
	$self->logNote("data", $data);
	
	my $owner 	=	$data->{owner};
	my $name 	=	$data->{name};

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $table = "app";
	my $required_fields = ["owner", "package", "name", "type"];
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;
		
	#### DO ADD
	return $self->_addToTable($table, $data, $required_fields);	
}

sub saveParameter {
=head2

    SUBROUTINE:     saveParameter
    
    PURPOSE:

        VALIDATE THE admin USER THEN SAVE APPLICATION INFORMATION
		
=cut

	my $self		=	shift;
	$self->logDebug("Admin::saveParameter()");

    	my $json			=	$self->json();

	#### GET DATA FOR PRIMARY KEYS FOR parameters TABLE:
    my $username 	= 	$json->{username};
	my $data 		= 	$json->{data};
	my $appname 	= 	$data->{appname};
	my $name 		= 	$data->{name};
	my $paramtype 	= 	$data->{paramtype};

	#### SET owner AS USERNAME IN data
	$data->{owner} = $username;
	
	#### CHECK INPUTS
	$self->logError("appname not defined or empty") and return if not defined $appname or $appname =~ /^\s*$/;
	$self->logError("name not defined or empty") and return if not defined $name or $name =~ /^\s*$/;
	$self->logError("paramtype not defined or empty") and return if not defined $paramtype or $paramtype =~ /^\s*$/;
	
	$self->logDebug("name", $name);
	$self->logDebug("paramtype", $paramtype);
	$self->logDebug("appname", $appname);

	my $success = $self->_addParameter($data); 
	if ( $success != 1 ) {
		$self->logError("Could not insert parameter $name into app $appname");
	}
	else {
		$self->logStatus("Inserted parameter $name into app $appname");
	}

	return;
}

sub _addParameter {
	my $self		=	shift;
	my $data		=	shift;

	my $username	=	$data->{username};
	my $appname		=	$data->{appname};
	my $name		=	$data->{name};

	my $table = "parameter";
	my $required = ["owner", "appname", "name", "paramtype", "ordinal"];
	my $updates = ["version", "status"];

	#### REMOVE IF EXISTS ALREADY
	my $success = $self->_removeFromTable($table, $data, $required);
	$self->logNote("Deleted app success") if $success;
		
	#### INSERT
	my $fields = $self->db()->fields('parameter');
	my $insert = $self->db()->insert($data, $fields);
	my $query = qq{INSERT INTO $table VALUES ($insert)};
	$self->logNote("query", $query);	
	return $self->db()->do($query);
}

sub deleteParameter {
=head2

    SUBROUTINE:     deleteParameter
    
    PURPOSE:

        VALIDATE THE admin USER THEN DELETE AN APPLICATION
		
=cut

	my $self		=	shift;
	
	#### GET DATA 
	my $json			=	$self->json();
	my $data = $json->{data};

	#### REMOVE
	my $success = $self->_removeParameter($data);
	$self->logStatus("Deleted parameter $data->{name}") and return if defined $success and $success;

	$self->logError("Could not delete parameter $data->{name}");
	return;
}

sub _removeParameter {
	my $self		=	shift;
	my $data		=	shift;
		
	my $table = "parameter";
	my $required_fields = ["owner", "name", "appname", "paramtype"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;
	
	#### REMOVE IF EXISTS ALREADY
	$self->_removeFromTable($table, $data, $required_fields);
}


1;