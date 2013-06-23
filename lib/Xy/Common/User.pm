package Xy::Common::User;
use Moose::Role;
#use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Xy::Common::User
	
	PURPOSE
	
		USER METHODS FOR Xy::Common
		
=cut
use Data::Dumper;

has 'userobject'	=> ( isa => 'HashRef|Undef', is => 'rw', default => undef );

#has 'requestor'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );

sub getUsers {
	my $self		=	shift;
	$self->logDebug("");

	#### GET USERNAME AND SESSION ID
    my $username = $self->username();

	#### VALIDATE USER USING SESSION ID	
	$self->logError("User $username not validated") and exit unless $self->validate($username);

	#### GET ALL SOURCES
	my $query = qq{SELECT DISTINCT username, firstname, lastname, email, description FROM users ORDER BY username};
	$query = qq{SELECT username, firstname, lastname, email, description  FROM users WHERE username='$username'} if not $self->isAdminUser($username);
	$self->logDebug("$query");	;
	my $users = $self->db()->queryhasharray($query);
	$users = {} if not defined $users;
	
	return $users;
}


sub updateUser {
=head2

    SUBROUTINE     updateUser
    
	PURPOSE

		SAVE USER INFORMATION TO users TABLE IN TWO
		
		SCENARIOS:
		
		1. THE USER UPDATES THEIR OWN INFORMATION

			A PASSWORD CHECK IS REQUIRED.
		
		2. IF THE USER IS AN ADMIN USER. NO oldpassword
		
			IS REQUIRED. THIS ALLOWS ADMIN USERS TO CHANGE
		
			THE PASSWORD OF THE data->{username} USER.

=cut
 	my $self			=	shift;

 	$self->logDebug("");

	my $username		=	$self->username();
	my $userobject		=	$self->userobject();
	my $oldpassword 	=	$userobject->{oldpassword};
	$self->logDebug("oldpassword", $oldpassword);
 	$self->logError("oldpassword is not defined}") and exit unless defined $oldpassword
		or $self->isAdminUser($username);

    #### ONLY AN ADMIN USER CAN CHANGE THE PASSWORD WITHOUT
    #### PROVIDING THE OLD PASSWORD
    my $newpassword = $userobject->{newpassword};
	$self->logDebug("newpassword", $newpassword);

    if ( not defined $newpassword and not $newpassword )
    {
		$self->logError("newpassword not defined") and return;
    }

    my $is_admin = $self->isAdminUser($username);
    if ( not defined $oldpassword and not $oldpassword and not $is_admin )
    {
		$self->logError("oldpassword not defined") and return;
    }

	#### GET USERNAME TO BE CHANGED
	my $changer_username = $username;
	my $changed_username = $userobject->{username};

	#### GET USER PASSWORD AND COMPARE TO INPUT oldpassword
	$self->logDebug("Retrieving password");
	my $query = "SELECT password FROM users WHERE username='$changed_username'";
	$self->logDebug("query", $query);

    my $stored_password = $self->db()->query($query);
	$self->logDebug("stored_password", $stored_password);

	#### QUIT IF NO STORED PASSWORD AND NOT ADMIN USER
    if ( not defined $stored_password and not $stored_password and not $is_admin)
    {
		$self->logError("No password for user in database") and return; 
    }

	#### QUIT IF CHANGING SOMEONE ELSE'S PASSWORD AND NOT ADMIN USER
	if ( $changer_username ne $changed_username and not $is_admin )
	{
		$self->logError("User does not have sufficient privileges: $changer_username") and return; 
	}

	#### QUIT IF THE PASSWORD DOES NOT MATCH AND NOT ADMIN USER
	if ( $stored_password ne $oldpassword and not $is_admin )
	{
		$self->logError("Incorrect password") and return; 
	}

	#### QUIT IF THE PASSWORD DOES NOT MATCH AND ADMIN USER CHANGING OWN PASSWORD
	if ( $stored_password ne $oldpassword
		and $changer_username eq $changed_username and $is_admin )
	{
		$self->logError("Incorrect password") and return; 
	}

	#### REMOVE FROM users TABLE IF EXISTS ALREADY
	my ($success, $user) = $self->_removeUser($userobject);
 	$self->logError("Could not remove user $changed_username from users table") if not defined $success and not $success;
 	
    #### ADD TO users TABLE
	$userobject->{password} = $userobject->{newpassword};
	$success = $self->_addUser($userobject);	
 	$self->logDebug("'_addUser' success", $success);
 	$self->logError("Could not update user $changed_username") and exit if not defined $success;
    
    #### CHANGE USER PASSWORD
    my $password = $userobject->{newpassword};

#	#### FEDORA:
#    (NB: CAN'T LOGIN ...)
#    my $passwd = "echo $password | passwd --stdin $changed_username";
#  	 $self->logDebug("passwd", $passwd);
#    print `$passwd`;

	#### UBUNTU
	if ( $password ) {
		my $change_password = "echo '$changed_username:$password' | chpasswd";
		$self->logDebug("change_password", $change_password);
		print `$change_password`;	
	}

 	$self->logStatus("Updated user $changed_username");
}


sub addUser {
	my $self		=	shift;
 	$self->logDebug("Common::addUser()");
	my $username 	=	$self->username();
	
	$self->logError("requestor is not an admin user: $username") and exit if not $self->isAdminUser($username);
	
	#### SET USER OBJECT
	my $userobject = $self->json()->{data};
	
	#### ADD USER TO DATABASE
	my $success = $self->_addUser($userobject);
	$self->logDebug("self->_addUser($username) success", $success);
	$self->logError("Could not add user $userobject->{username}") and exit if not $success;

	#### ADD LINUX USER
	$self->_addLinuxUser($userobject);

	$self->logStatus("Created user $userobject->{username}");
}

sub _addUser {
	my $self		=	shift;
	my $object		=	shift;
	$self->logDebug("object", $object);

	my $username = $object->{username};
    $self->logError("username not defined") and exit if not defined $username;
	
	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "users";
	my $required_fields = ["username", "email"];
	
	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($object, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;

	#### LATER: FIX THIS SO THAT THE DATE IS ADDED PROPERLY 
	$object->{datetime} = $self->db()->now();

	#### DO THE ADD
	return $self->_addToTable($table, $object, $required_fields);	
}

sub _addLinuxDaemon {
	my $self		=	shift;
	my $object		=	shift;
	$self->logDebug("object", $object);

	my $username = $object->{username};
    $self->logError("username not defined") and exit if not defined $username;

	my $userid = $object->{userid};
    $self->logError("userid not defined") and exit if not defined $userid;

	my $removegroup = "groupdel $username 2> /dev/null 1> /dev/null";
	$self->logDebug("$removegroup");
	print `$removegroup`;
	
	my $addgroup = "groupadd $username -g $userid 2> /dev/null 1> /dev/null";
	$self->logDebug("$addgroup");
	print `$addgroup`;

	my $adduser = "useradd -r -s /bin/false $username --uid $userid -g $userid 2> /dev/null 1> /dev/null";
	$self->logDebug("$adduser");
	print `$adduser`;	
}

sub _addLinuxUser {
#### CREATE USER ACCOUNT AND HOME DIRECTORY
	my $self		=	shift;
	my $object		=	shift;
	$self->logDebug("object", $object);

	my $username = $object->{username};
    $self->logError("username not defined") and exit if not defined $username;

    #### GET USER DIR
    my $userdir = $self->conf()->getKey("agua", 'USERDIR');
    $self->logDebug("userdir", $userdir);
	
	#### REDHAT:
	#my $addgroup = "/usr/sbin/groupadd $username";
	#my $adduser = "useradd -g $username -s/bin/bash -p $username -d $userdir/$username -m $username";

	#### UBUNTU
	my $set_home = "useradd -D -b $userdir 2> /dev/null 1> /dev/null";
	$self->logDebug("$set_home");
	print `$set_home`;

	my $removegroup = "groupdel $username 2> /dev/null 1> /dev/null";
	$self->logDebug("$removegroup");
	print `$removegroup`;
	
	my $adduser = "useradd -m $username -s /bin/bash 2> /dev/null 1> /dev/null";
	$self->logDebug("$adduser");
	print `$adduser`;

	#### CREATE 'AGUA' DIR IN USER'S HOME FOLDER
	my $aguadir = $self->conf()->getKey("agua", 'AGUADIR');
	my $mkdir = "mkdir -p $userdir/$username/$aguadir";
	$self->logDebug("$mkdir");
	print `$mkdir`;

    #### SET CHOWN
    my $apache_user = $self->conf()->getKey("agua", 'APACHEUSER');
	$self->logDebug("apache_user", $apache_user);
    my $chown = "chown -R $username:$apache_user $userdir/$username $userdir/$username/$aguadir";
	$self->logDebug("$chown");
	print `$chown`;

    #### SET chmod SO THAT agua USER CAN ACCESS AND CREATE FILES
    my $chmod = "chmod 770 $userdir/$username $userdir/$username/$aguadir";
	$self->logDebug("$chmod");
	print `$chmod`;
    
    #### SET USER UMASK (APACHE'S UMASK IS ALREADY SET AT 002)
    my $umask = qq{echo "umask 0002" >> $userdir/$username/.bashrc};
	$self->logDebug("$umask");
	print `$umask`;

    my $test = qq{echo "test file" >> $userdir/$username/$aguadir/testfile.txt};
	$self->logDebug("$test");
	print `$test`;
}

sub removeUser {
	my $self		=	shift;
 	$self->logDebug("Common::removeUser()");

	#### DO THE REMOVE
    my $json 	=	$self->json();
    my $object 	=	$json->{data};
	my $success = 	$self->_removeUser($object);
 	$self->logError("Could not remove user $object->{username} from user table") and exit if not defined $success;
	
	$self->_removeLinuxUser($object);

 	$self->logStatus("Removed user $object->{username}");
}

sub _removeUser {
	my $self		=	shift;
	my $object		=	shift;
 	$self->logDebug("object", $object);
    
	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $table = "users";
	my $required_fields = ["username"];
	$self->logDebug("DOING self->db->notDefined");
	my $not_defined = $self->db()->notDefined($object, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if defined $not_defined and @$not_defined;

	#### DO THE REMOVE
	$self->logDebug("BEFORE self->removeFromTable    object: $object");
	return if not $self->_removeFromTable($table, $object, $required_fields);
	$self->logDebug("AFTER self->removeFromTable");

	#### REMOVE FROM GROUPS
	$object->{owner} = $object->{username};
	$object->{name} = $object->{username};
	$object->{type} = "user";
	
	$self->logDebug("DOING self->removeFromTable(groupmember, object, ['owner']");
	$self->_removeFromTable("groupmember", $object, ["owner"]);
	$self->_removeFromTable("groupmember", $object, ["name", "type"]);
}

sub _removeLinuxUser {
#### DELETE USER ACCOUNT AND HOME DIRECTORY
	my $self		=	shift;
	my $object		=	shift;
	$self->logDebug("object", $object);

	my $username = $object->{username};
    $self->logError("username not defined") and exit if not defined $username;
	
	#### DELETE USER
	my $userdel = "userdel  $username";
	$self->logDebug("userdel", $userdel);
	print `$userdel`;

	#### DELETE GROUP
	my $groupdel = "groupdel $username 2> /dev/null 1> /dev/null";
	$self->logDebug("groupdel", $groupdel);
	print `$groupdel`;
	
    #### DELETE USER HOME DIR
    my $userdir = $self->conf()->getKey("agua", 'USERDIR');
    $self->logDebug("userdir", $userdir);
	my $aguadir = $self->conf()->getKey("agua", 'AGUADIR');
	my $mkdir = "rm -fr $userdir/$username/$aguadir";

	$self->logDebug("$mkdir");
	print `$mkdir`;
}


1;