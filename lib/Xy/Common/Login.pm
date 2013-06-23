package Xy::Common::Login;
use Moose::Role;

has 'mode'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'password'	=> ( isa => 'Str|Undef', is => 'rw' );

=head2

	PACKAGE		Xy::Common::Login
	
	PURPOSE
	
		SOURCE METHODS FOR Xy::Common
		
=cut

use Data::Dumper;
use Authen::Simple::ActiveDirectory;
	
####///}}}}
sub ldapAuthentication {

=head2

SUBROUTINE      ldapAuthentication

PURPOSE

	USE LDAP SERVER TO VALIDATE USER
	
INPUTS

	1. JSON->USERNAME
	
	2. JSON->PASSWORD
	
	3. CONF->LDAP_SERVER

OUTPUTS

	1. RETURN 1 ON SUCCESS, 0 ON FAILURE

=cut

	my $self		=	shift;
	my $username	=	shift;
	my $password	=	shift;
	
	$self->logDebug("username", $username);
	$self->logDebug("password", $password);

	my $host = $self->conf()->getKey('authentication', "HOST");
	$self->logDebug("host", $host);
	my $principal = $self->conf()->getKey('authentication', "PRINCIPAL");
	$self->logDebug("principal", $principal);
	
	####  RETURN 1 IF NO HOST OR PRINCIPAL
	return 0 if not defined $host;
	return 0 if not defined $principal;
	
	my $ad = Authen::Simple::ActiveDirectory->new( 
        host      => $host,
        principal => $principal
    );
	$self->logDebug("ad", $ad);
	my $authenticated = $ad->authenticate($username, $password);
	$self->logDebug("authenticated", $authenticated);
	
	return $authenticated;
}

sub submitLogin {
	my $self		=	shift;
	
	my $sessionid = $self->_submitLogin();
	$self->logDebug("sessionid");

	print "{ sessionid : '$sessionid' }" if defined $sessionid;
}
	
sub _submitLogin {
=head2

    SUBROUTINE      login
    
    PURPOSE
    
        AUTHENTICATE USER USING ONE OF TWO WAYS:
		
		1. IF EXISTS 'LDAP_SERVER' ENTRY IN CONF FILE, USE THIS TO AUTHENTICATE

			THEN GENERATE A SESSION_ID IF SUCCESSFULLY AUTHENTICATED
		
		2. OTHERWISE, CHECK INPUT PASSWORD AGAINST STORED PASSWORD IN users TABLE
		
			THEN GENERATE A SESSION_ID IF SUCCESSFULLY AUTHENTICATED
		
		3. IF SUCCESSFULLY AUTHENTICATED, STORE SESSION_ID IN sessions TABLE
		
		4. IF SUCCESSFULLY AUTHENTICATED, PRINT SESSEION ID TO STDOUT
		
	INPUTS
	
		1. USERNAME
		
		2. PASSWORD
	
	OUTPUTS
	
		1. SESSION ID

=cut
	my $self		=	shift;

	my $username	=	$self->username();
	my $password 	=	$self->password();
	$self->logDebug("username", $username);
	$self->logNote("password not defined or empty") if not defined $password or not $password;
    
    #### CHECK USERNAME AND PASSWORD DEFINED AND NOT EMPTY
    if ( not defined $username )    {   return; }
    if ( not defined $password )    {   return; }
    if ( not $username )    {   return; }
    if ( not $password )    {   return; }

	#### CHECK IF GUEST USER AND IF SO WHETHER ACCESS IS ALLOWED
	$self->guestLogin();
		
	#### VALIDATE USING LDAP IF EXISTS 'LDAP_SERVER' ENTRY IN CONF FILE
	my $authenticationtype 	=	$self->conf()->getKey('authentication', "TYPE");
	my $match = 0;
	$self->logDebug("LDAP SERVER", $authenticationtype);
	if ( $authenticationtype eq "ldap" ) {
		$self->logDebug("Doing LDAP authentication...");
		$match = $self->ldapAuthentication($username, $password);
	}
	#### OTHERWISE, GET STORED PASSWORD FROM users TABLE
	else {
		$self->logDebug("Doing database authentication...");
		my $query = qq{SELECT password FROM users
	WHERE username='$username'};
		$self->logDebug("$query");
		my $storedpassword = $self->db()->query($query);	
	
		#### CHECK FOR INPUT PASSWORD MATCHES STORED PASSWORD
		$self->logDebug("Stored_password", $storedpassword);
		$self->logDebug("Passed password", $password);
	
		if ( defined $storedpassword ) {
			$match = $password =~ /^$storedpassword$/; 
			$self->logDebug("Match", $match);
		}
	}
	$self->logDebug("match", $match);

	#### GENERATE SESSION ID
	my $sessionid;
	
	#### IF PASSWORD MATCHES, STORE SESSION ID AND RETURN '1'
	my $exists;
	
	####
	my $now = $self->db()->now();
	$self->logDebug("now", $now);
	
	if ( $match ) {
		while ( not defined $sessionid ) {
			#### CREATE A RANDOM SESSION ID TO BE STORED IN dojo.cookie
			#### AND PASSED WITH EVERY REQUEST
			$sessionid = time() . "." . $$ . "." . int(rand(999));

			#### CHECK IF THIS SESSION ID ALREADY EXISTS
			my $exists_query = qq{
			SELECT username FROM sessions
			WHERE username = '$username'
			AND sessionid = '$sessionid'};
			$self->logDebug("Exists query", $exists_query);
			$exists = $self->db()->query($exists_query);
			if ( defined $exists ) {
				$self->logDebug("Exists", $exists);
				$sessionid = undef;
			}
			else {
				$self->logDebug("Session ID for username $username does not exist in sessions table");
			}
		}        
        
		#### IF IT DOES EXIST, UPDATE THE TIME
		if ( defined $exists ) {
			my $update_query = qq{UPDATE sessions
			SET datetime = $now
			WHERE username = '$username'
			AND sessionid = '$sessionid'};
			$self->logDebug("Update query", $update_query);
			my $update_success = $self->db()->query($update_query);
			$self->logDebug("Update success", $update_success);
		}
		
		#### IF IT DOESN'T EXIST, INSERT IT INTO THE TABLE
		else {
			my $query = qq{
INSERT INTO sessions
(username, sessionid, datetime)
VALUES
('$username', '$sessionid', $now )};
			$self->logDebug("$query");
			my $success = $self->db()->do($query);
			$self->logDebug("$success");
			if ( $success ) {
				$self->logDebug("Session ID has been stored.");
			}
		}		
	}
	
	#### LATER:: CLEAN OUT OLD SESSIONS
	# DELETE FROM sessions WHERE datetime < ADDDATE(NOW(), INTERVAL -48 HOUR)
	# DELETE FROM sessions WHERE datetime < DATE_SUB(NOW(), INTERVAL 1 DAY)
	my $timeout = $self->conf()->getKey('database', 'SESSIONTIMEOUT');
	$timeout = "24" if not defined $timeout;
	my $delete_query = qq{
#DELETE FROM sessions
#WHERE datetime < DATETIME ('NOW()', 'LOCALTIME', '-$timeout HOURS') };
	my $dbtype = $self->conf()->getKey('database', 'DBTYPE');
	$delete_query = qq{
DELETE FROM sessions
WHERE timediff(sysdate(), datetime) > $timeout * 3600} if defined $dbtype and $dbtype eq "MySQL";
	$self->logDebug("delete_query", $delete_query);
	$self->db()->do($delete_query);
	
	if ( not defined $sessionid and $authenticationtype eq "ldap" ) {
		$self->logError("LDAP authentication failed for user: $username");
		return;
	}
	elsif ( not defined $sessionid ) {
		$self->logError("Authentication failed for user: $username");
		return;
	}
	
	return $sessionid;
}

sub guestLogin {
	my $self		=	shift;
	
	my $username	=	$self->username();
	$username		=	$self->requestor() if $self->requestor();
	
	my $guestuser 	= $self->conf()->getKey("guest", "GUESTUSER");
	$self->logDebug("guestuser", $guestuser);	
	my $guestaccess = $self->conf()->getKey("guest", "GUESTACCESS");
	$self->logDebug("guestaccess", $guestaccess);
	
	#### SKIP IF NOT GUEST USER
	return if not defined $guestuser;
	return if not $username eq $guestuser;
	$self->logDebug("username is guestuser: $guestuser");
	
	#### QUIT IF GUEST ACCESS NOT ALLOWED
	$self->logError("guestuser access denied") and exit if not $guestaccess;
}

sub newuser {
=head2

    SUBROUTINE      newuser
    
    PURPOSE
    
        CHECK 'admin' NAME AND PASSWORD AGAINST INPUT VALUES. IF
        
        VALIDATED, CREATE A NEW USER IN THE users TABLE
        
=cut
	my $self		=	shift;
	$self->logDebug("Xy::Common::Login::newuser()");

    
    my $json;
    if ( not $self->validate() )
    {
        $json = "{ {validated: false} }";
        print $json;
        return;
    }
	
	my $username	=	$self->cgiParam('username');
	my $password 	=	$self->cgiParam('password');
	my $newuser 	=	$self->cgiParam('newuser');
	my $newuserpassword 	=	$self->cgiParam('newuserpassword');

	$self->logDebug("DB User", $username);
	$self->logDebug("DB Password", $password);
	$self->logDebug("New user", $newuser);
	$self->logDebug("New user password", $newuserpassword);

    ##### CREATE TABLE users IF NOT EXISTS
    #$self->createTable('users');

	#### CHECK IF USER ALREADY EXISTS
	my $query = qq{SELECT username FROM users WHERE username='$newuser' LIMIT 1};
	my $exists_already = $self->db()->query($query);
	if ( $exists_already )
	{
		$self->logError("User exists already: $username");
		return;
	}
	
    $query = qq{INSERT INTO users VALUES ('$newuser', '$newuserpassword', NOW())};
    my $success = $self->db()->do($query);
    $self->logDebug("Insert success", $success);

    if ( $success )
    {
        $self->logStatus("New user created");
    }
    else
    {
        $self->logStatus("Failed to create new user");
    }
}












1;