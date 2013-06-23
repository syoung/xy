use Moose::Util::TypeConstraints;
use MooseX::Declare;
use Method::Signatures::Modifiers;

#### USE LIB FOR INHERITANCE
use FindBin::Real;
use lib FindBin::Real::Bin() . "/..";

class Xy::Common::Util::Configure with (Xy::Common::Util, Xy::Common::Logger) {

=head2

PACKAGE		Configure

PURPOSE

    1. CONFIGURE THE DATABASE
    
    2. CONFIGURE DATA AND APPLICATION PATHS AND SETTINGS
    
        E.G., PATHS TO BASIC EXECUTABLES IN CONF FILE:
        
        [applications]
        STARCLUSTER	      	/data/apps/starcluster/0.92.rc1/bin/starcluster
        BOWTIE              /data/apps/bowtie/0.12.2
        CASAVA              /data/apps/casava/1.6.0/bin
        CROSSMATCH          /data/apps/crossmatch/0.990329/cross_match
        CUFFLINKS           /data/apps/cufflinks/0.8.2
        ...
    
=cut

use Illumina::DBase::MySQL;

# Ints
has 'SHOWLOG'	=>  ( isa => 'Int', is => 'rw', default => 1 );  
has 'PRINTLOG'	=>  ( isa => 'Int', is => 'rw', default => 1 );
	
# Strings
has 'validated'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );
has 'username'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );
has 'requestor'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );
has 'outputdir'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );
has 'configfile'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );
has 'logfile'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );
has 'dumpfile'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );
has 'database'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );
has 'rootpassword'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );
has 'password'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );
has 'sqldir'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );
has 'testdatabase'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );
has 'testuser'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );
has 'testpassword'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );
has 'user'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );


# Objects
has 'firsttables'=> ( isa => 'ArrayRef|Undef', is => 'rw', default => undef );
has 'db'	=> ( isa => 'Illumina::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Conf::Yaml',
	default	=>	sub {	Conf::Yaml->new();	}
);


use strict;
use warnings;
use Carp;

#### USE LIB FOR INHERITANCE
use FindBin qw($Bin);
use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";
use Data::Dumper;

#### USE LIB
use FindBin::Real;
use lib FindBin::Real::Bin() . "../../..";

#### EXTERNAL MODULES
use Data::Dumper;
use Term::ReadKey;

#### INTERNAL MODULES
use Illumina::DBaseFactory;
use Conf::Yaml;

####/////}

sub preInitialise {	
	my $self		=	shift;
    my $arguments	=	shift;

	##### ADD ANCESTER SLOTS, MAKE AND LOAD SLOTS
	#$self->doSlots($arguments);
	
	#$SLOTS = $self->slots() if $self->can("slots") and defined $self->slots();
	#print "Illumina::WGS::Util::Configure::initialise    self->conf:\n";
	#print Dumper $self->conf();

	##### QUIT IF NO SLOTS
	#return if not defined $self->slots();

	#### SET CONF LOG
	$self->conf()->SHOWLOG($self->SHOWLOG()) if $self->conf()->can('SHOWLOG') and $self->can('SHOWLOG');
	$self->conf()->PRINTLOG($self->PRINTLOG()) if $self->conf()->can('PRINTLOG') and $self->can('PRINTLOG');


	#### SET CONF LOG
	$self->db()->SHOWLOG($self->SHOWLOG()) if $self->db()->can('SHOWLOG') and $self->can('SHOWLOG');
	$self->db()->PRINTLOG($self->PRINTLOG()) if $self->db()->can('PRINTLOG') and $self->can('PRINTLOG');

}

sub setDbh {
	my $self		=	shift;
	
	my $args;
	$args->{dbtype}		=	$self->dbtype();
	$args->{database}	=	$self->database();
	$args->{user}       =  	$self->user();
	$args->{password}   =  	$self->password();
	$args->{logfile}	=	$self->logfile();
	$args->{SHOWLOG}	=	$self->SHOWLOG();
	$args->{PRINTLOG}	=	$self->PRINTLOG();
	$args->{parent}		=	$self;
	
	$self->_setDbh($args);
}

sub _setDbh {
	my $self		=	shift;
	my $args		=	shift;
	
	my $dbtype	=	$args->{dbtype};
	my $db = 	Illumina::DBaseFactory->new(
		$dbtype,
		{
			database	=>	$args->{database},
			user        =>  $args->{user},
			password    =>  $args->{password},
			logfile		=>	$args->{logfile},
			SHOWLOG		=>	$args->{SHOWLOG},
			PRINTLOG	=>	$args->{PRINTLOG},
			parent		=>	$self
		}
	) or print qq{ error: 'Agua::Database::setDbh    Cannot create database object " . $args->{database} . ": $!' } and return;
	$self->logError("db not defined") and return if not defined $db;
	
	$self->db($db);
}

sub config {
	my $self		=	shift;	
	
	#### SET UP MYSQL DATABASE AND DB USER
	$self->mysql();
	
print "\n\n\n"; 
print "************************************       ************************************\n";
print "*********                        Completed 'config'                   *********\n";
print "************************************       ************************************\n";
print "\n\n\n";

	$self->logDebug("Completed $0");
}

#### MYSQL
sub mysql {
	my $self		=	shift;
=head2

SUBROUTINE         mysql

PURPOSE

	1. SET MYSQL ROOT PASSWORD (OPTIONAL)
	
	2. LOAD THE DATABASE (BACKS UP EXISTING DATA)
	
	3. CREATE MYSQL USER	

	4. CREATE TEST MYSQL USER	

=cut 

	$self->printMysqlWelcome();
	
    print qq{\n
Input configuration values or hit 'Enter' to accept the [default_value]

};

    #### SET DATABASE NAME
    my $database        =   $self->setDatabase();
	
	#### CHECK TO RESET ROOTPASSWORD, OTHERWISE GET FROM CONF FILE
	$self->setMysqlRoot();

	#### RELOAD DATABASE
	return if not defined $self->reloadDatabase();	
	
	#### OPTIONALLY RESET MYSQL USER AND PASSWORD    
	my ($user, $password) = $self->setMysqlUser();
	
	#### CREATE TEST DATABASE
	$self->createTestDatabase();

	#### OPTIONALLY RESET TEST MYSQL USER AND PASSWORD    
	my ($testuser, $testpassword) = $self->setTestUser();

    #### PRINT CONFIRMATION THAT THE DATABASE HAS BEEN CREATED
	$self->printMysqlConfirmation($database, $user, $password);
}

sub printMysqlWelcome {
	my $self		=	shift;		#### PRINT INFO
    print qq{\n

This configuration utility does the following:
	
	1. Set the database name

	2. Set the root MySQL password (if not already set)

	3. Drop the database (optional: save existing data) and reload database 

	4. Set the application's MySQL user name and password

	5. Set the test MySQL user name and password
	
\n};
	
	#### CHECK FOR QUIT
    print "\nExiting\n\n" and exit if not $self->yes("Type 'Y' to continue or 'N' to exit");
}

sub printMysqlConfirmation {	
	my $self		=	shift;
	my $database	=	shift;
	my $user		=	shift;
	my $password	=	shift;

	my $configfile = $self->configfile();
	my $logfile = $self->logfile();
	my $timestamp = $self->db()->timestamp();
	print qq{
*******************************************************
MySQL configuration completed.

Please make a note of your MySQL access credentials:

\tDatabase:\t$database
\tUsername:\t$user
\tPassword:\t$password

You can test this on the command line:

\tmysql -u $user -p$password
\tUSE $database
\tSHOW TABLES

Your updated configuration file is here:

\t$configfile

This transaction has been recorded in the log:

\t$logfile

$timestamp
*******************************************************\n};
}

sub setDbObject {
	my $self		=	shift;
	my $database	=	shift;
	my $user		=	shift;
	my $password	=	shift;
	#$self->logDebug("database", $database);

   #### CREATE DB OBJECT USING DBASE FACTORY
    my $db = Illumina::DBaseFactory->new( 'MySQL',
        {
			database	=>	$database,
            user      	=>  $user,
            password  	=>  $password,
			logfile		=>	$self->logfile(),
			SHOWLOG		=>	2,
			PRINTLOG	=>	2
        }
    ) or die "Can't create database object to create database: $database. $!\n";

	$self->db($db);
}

####	MYSQL USER
sub setMysqlUser {
	my $self		=	shift;
	my $database = $self->database();
	$self->logDebug("database not defined") and exit if not defined $database;

	#### SET DB OBJECT
	my $rootpassword = $self->_getRootPassword();
	$self->logError("rootpassword not defined") and return if not defined $rootpassword;
	$self->setDbObject($database, "root", $rootpassword) if not defined $self->db();

	#### GET CURRENT VALUES
	#my $user 			=	$self->conf()->getKey("mysql", "USER");
	my $user 			=	$self->conf()->getKey("database", "USER");
	$self->logDebug("self->conf", $self->conf());
	$self->logDebug("user", $user);
	#my $password		=	$self->conf()->getKey("mysql", "PASSWORD");
	my $password		=	$self->conf()->getKey("database", "PASSWORD");
	my $length 		= 	9;
	$password		=	$self->createRandomPassword($length) if not $password;

	#### USER NAME
	print "\n";
	$user = $self->_inputValue("MySQL user name", $user);
    $self->logError("user not defined") if not defined $user;
        
    #### USER PASSWORD
	$password = $self->_inputValue("MySQL user password", $password);	
    $self->logError("password not defined") if not defined $password;

	#### SET USER AND PASSWORD
	$self->_createDatabaseUser($database, $user, $password);

	#### UPDATE CONF FILE
	my $oldmemory = $self->conf()->memory();
	$self->conf()->memory(0);
	$self->logDebug("self->conf()->memory()", $self->conf()->memory());
	$self->conf()->setKey("mysql", "USER", $user);
	$self->conf()->setKey("mysql", "PASSWORD", $password);
	$self->conf()->memory($oldmemory);
	
	#### UPDATE SLOTS
    $self->user($user);
    $self->password($password);

	return $user, $password;
}

sub setDatabase {
	my $self		=	shift;

	my $database = $self->database() || $self->conf()->getKey("database", "DATABASE");
	$database = $self->_inputValue("MySQL database name", $database);
    $self->logError("database not defined") and exit if not defined $database;

	#### SET DATABASE ATTRIBUTE	
    $self->database($database);
	
	#### UPDATE DATABASE ITEM IN CONFIG
	my $databaseobject = $self->conf()->getKey("database", undef);
	$databaseobject->{database} = $database;
	$self->conf()->setKey("database", $databaseobject);
	
	return $database;
}

sub setMysqlRoot {
#### PROMPT TO SET ROOT MYSQL PASSWORD
	my $self		=	shift;
	
	print "\n";
	my $resetroot = qq{Reset MySQL root password? Type 'Y' to reset or 'N' to skip};

	my $rootpassword;
	if ( $self->yes($resetroot) ) {
		my $rootpassword = $self->_inputRootPassword();
		$self->logError("rootpassword not defined") and return if not defined $rootpassword;

		$self->_setRootPassword($rootpassword);
	}
	else {
		print "MySQL root password will not be changed\n";
		my $rootpassword = $self->_inputRootPassword();
		$self->logError("rootpassword not defined") and return if not defined $rootpassword;
		$self->rootpassword($rootpassword);
	}
}

sub _inputRootPassword {
#### MASK TYPING FOR PASSWORD INPUT
	my $self		=	shift;
    ReadMode 2;
	print "\n";
	my $rootpassword = $self->_inputValue("Input MySQL root password (will not appear on screen)", undef);	

    #### UNMASK TYPING
    ReadMode 0;
    $self->rootpassword($rootpassword);

	return $rootpassword;
}

sub createRandomPassword {
	my $self		=	shift;
	my $length		=	shift;
	
	my $password = '';
	for ( my $i = 0; $i < $length; $i++ ) {
		my $random = int(rand(16)) + 1;
		my $hex = lc(sprintf("%01X", $random));
		$password .= "$hex";
	}
	return $password;
}

#### 	ROOT USER
sub _setRootPassword {
	my $self			=	shift;
	my $rootpassword	=	shift;
	#### RESTART MYSQL WITH  --skip-grant-tables

	print "Setting mysql root password...\n";
	$self->stopMysql();
	$self->killMysql();

	my $start = "sudo mysqld --skip-grant-tables &";
	print "$start\n";
	system($start);
	sleep(5);
	print "Completed\n";

	#### SET root USER PASSWORD
	my $sqlfile = FindBin::Real::Bin() . "/../../conf/setRootPassword.sql";
	$self->logDebug("sqlfile", $sqlfile);
	my $create = qq{
UPDATE mysql.user SET Password=PASSWORD('$rootpassword') WHERE User='root'; 
FLUSH PRIVILEGES;
};
	$self->printToFile($sqlfile, $create);
	my $command = "mysql < $sqlfile";
	$self->logDebug("command", $command);

	print "$command\n";
	print `$command`;

	#`rm -fr $sqlfile`;

	#### SET self->rootpassword
	$self->rootpassword($rootpassword);
}

sub stopMysql {
	my $self		=	shift;	$self->logDebug("");
	my $mysql = $self->getMysql();
    my $command = "$mysql stop";
	print "Illumina::Init::mountMysql    command: $command\n";
	print `$command`;
}

sub getMysql {
	my $self		=	shift;	my $mysql = "/etc/init.d/mysqld";
	$mysql = "/etc/init.d/mysql" if not -f $mysql;
	
	return $mysql;
}

sub killMysql {
	my $self		=	shift;#### KILL MYSQL IF RUNNING
	$self->logDebug("");
	my @lines = split "\n", `ps aux | egrep "^mysql"`;
	$self->logDebug("lines", \@lines);
	foreach my $line ( @lines ) {
		$self->logDebug("line", $line);
		my ($pid) = $line =~ /^mysql\s+(\d+)/;
		$self->logDebug("pid", $pid);
		my $command = "kill -9 $pid";
		$self->logDebug("command", $command);
		`$command`;
	}	
}

sub _getRootPassword {
	my $self		=	shift;
	my $rootpassword = $self->rootpassword();
	$self->logError("rootpassword not defined") and return if not defined $rootpassword;
	
	if ( not $rootpassword ) {
		$rootpassword = $self->_inputRootPassword();
		$self->rootpassword($rootpassword);
	}
	
	return $rootpassword;
}

####	LOAD DATABASE
sub reloadDatabase {
	my $self		=	shift;

	my $database = $self->database() || $self->conf()->getKey("database", "DATABASE");
	$self->logDebug("database", $database);
	$self->logDebug("database not defined") and exit if not defined $database;

	#### SET DB OBJECT
	my $rootpassword = $self->_getRootPassword();
	$self->logDebug("rootpassword", $rootpassword);
	$self->logError("rootpassword not defined") and return if not defined $rootpassword;
	
	##### SET DB OBJECT TO mysql
	$self->setDbObject("mysql", "root", $rootpassword);
	
	#### DELETE DATABASE IF CONFIRM OVERWRITE
	my $overwrite = $self->_checkOverwrite($database);
	$self->logDebug("overwrite", $overwrite);
	if ( $overwrite ) {
		print "Creating database... ";
		$self->_createDatabase($database);
		print "done\n";
	}	
	
	#### SET DATABASE OBJECT TO DATABASE
	$self->setDbObject($database, "root", $rootpassword);

	#### GET SQL FILES
	my $sqldir		=	$self->sqldir();
	my $sqlfiles 	=	$self->getFiles($sqldir);
	$sqlfiles = $self->filterByRegex($sqlfiles, "\.sql\$");
	@$sqlfiles 		= sort @$sqlfiles;

	#### GET TABLES TO BE LOADED FIRST
	my $firsttables = $self->firsttables();
	$self->logDebug("firststables", $firsttables);
	my $firstsqlfiles = [];
	foreach my $firsttable ( @$firsttables ) {
		my $firstfile = $firsttable;
		$firstfile .= ".sql";
		push @$firstsqlfiles, $firstfile;
	}

	#### ORDER FILES
	$sqlfiles	=	$self->_orderFiles($sqlfiles, $firstsqlfiles);
	$self->logDebug("sqlfiles", $sqlfiles);

	#### CREATE TABLES
	$self->_createTables($sqldir, $sqlfiles);
	
	#### LOAD DATA FROM TSV FILES
	my $tsvdir = $sqldir;
	$tsvdir =~ s/\/[^\/]+$//;
	$tsvdir .= "/tsv";
	$self->logDebug("tsvdir", $tsvdir);
	my $tsvfiles 	=	$self->getFiles($tsvdir);
	$tsvfiles = $self->filterByRegex($tsvfiles, "\.tsv\$");
	@$tsvfiles 	= 	sort @$tsvfiles;
	$self->logDebug("tsvfiles", $tsvfiles);
	
	#### GET TABLES TO BE LOADED FIRST
	my $firstfiles = [];
	foreach my $firsttable ( @$firsttables ) {
		push @$firstfiles, "$firsttable.tsv";
	}
	
	#### ORDER FILES
	$tsvfiles	=	$self->_orderFiles($tsvfiles, $firstfiles);
	$self->logDebug("tsvfiles", $tsvfiles);

	print "Loading database... ";
	$self->_loadTsvFiles($tsvdir, $tsvfiles);
	print "done\n";
}

sub _dropDatabase {
	my $self		=	shift;
	my $database	=	shift;

	$self->logDebug("database", $database);

	my $query = qq{DROP DATABASE $database};
	my $success = $self->db()->do($query);
	$self->logDebug("Drop database success", $success);
}

sub _createDatabase {
	my $self		=	shift;
	my $database	=	shift;
	
    my $rootpassword   	=   $self->rootpassword();
    my $user       		=   $self->user();
    my $password   		=   $self->password();
	my $logfile 		= 	$self->logfile();
	$self->logDebug("Creating database", $database);

	#### CREATE DATABASE AND USER AND PASSWORD
	my $sqlfile = $self->_setSqlFile("createDb.sql");
    $self->logDebug("sqlfile", $sqlfile);

	my $create = qq{CREATE DATABASE $database;};
	$self->logDebug("create", $create);
	$self->printToFile($sqlfile, $create);
	my $command = "mysql -u root -p$rootpassword < $sqlfile";
	$self->logDebug("$command");
	print `$command`;
	`rm -fr $sqlfile`;
	
	$self->logDebug("Created database", $database);
}

sub _orderFiles {
	my $self		=	shift;
	my $files		=	shift;
	my $firsts		=	shift;
	$self->logDebug("files", $files);
	$self->logDebug("firsts", $firsts);
	
	foreach my $first ( @$firsts ) {
		for ( my $i = 0; $i < @$files; $i++ ) {
			if ( $$files[$i] =~ /^$first$/ ) {
				splice @$files, $i, 1;
				last ;
			}
		}
		unshift @$files, $first;
	}
	
	return $files;
}

sub _loadTsvFiles {
	my $self		=	shift;
	my $tsvdir		=	shift;
	my $tsvfiles	=	shift;

	foreach my $tsvfile ( @$tsvfiles ) {
		my $table = $tsvfile;
		$table =~ s/\.tsv$//;
		#$self->logDebug("tsvfile", $tsvfile);
		#$self->logDebug("table", $table);
		$self->_loadTsvFile($table, "$tsvdir/$tsvfile");
	}
}

sub _loadTsvFile {
	my $self		=	shift;
	my $table		=	shift;
	my $file 		=	shift;
	
	return if not $self->can('db');
	
	$self->logDebug("table", $table);
	$self->logDebug("file", $file);
	
	$self->setDbh() if not defined $self->db();
	return if not defined $self->db();
	my $query = qq{LOAD DATA LOCAL INFILE '$file' INTO TABLE $table};
	$self->logDebug("query", $query);
	my $success = $self->db()->do($query);
	$self->logCritical("load data failed") if not $success;
	
	return $success;	
}

####	CREATE TABLES
sub _createTables {
	my $self		=	shift;
	my $sqldir		=	shift;
	my $sqlfiles 	= 	shift;
	$self->logDebug("sqlfiles", $sqlfiles);
	
	$self->setDbh() if not defined $self->db();

	my $tables = [];
	my $counter = 0;
	foreach my $sqlfile ( @$sqlfiles ) {
		next if not $sqlfile =~ /\.sql$/;
		$self->logDebug("DOING sourcesqlfile: $sqldir/$sqlfile");
		push @$tables, $self->_createTable("$sqldir/$sqlfile");
	}
	
	return $tables;
}

sub getSqlFiles {
#### HANDLE ORDER DUE TO CONSTRAINT/FOREIGN KEY DEPENDENCIES
	my $self		=	shift;
	my $sqldir		=	shift;
	my $firsts		=	shift;
	$self->logDebug("sqldir", $sqldir);
	$self->logDebug("firsts", $firsts);
	$self->logDebug("DEBUG EXIT") and exit;
	
	
	my $files 		=	$self->getFiles($sqldir);
	@$files			=	sort @$files;
	$self->logDebug("files", $files);
	for ( my $i = 0; $i < @$files; $i++ ) {
		if ( $$files[$i] !~ /\.sql$/ ) {
			splice @$files, $i, 1;
			$i--;
		}
	}
	
	foreach my $first ( @$firsts ) {
		unshift @$files, "$first.sql";
	}
	$self->logDebug("files", $files);
	$self->logDebug("DEBUG EXIT") and exit;
	
	
	return $files;
}

sub fileToTableName {
	my $self		=	shift;
	my $file		=	shift;

	my $contents = $self->getFileContents($file);
	#$self->logDebug("contents", $contents);

	my ($tablename) = $contents =~ /CREATE\s+TABLE\s+[^\(]*?(\S+)\s*\(/;
	#$self->logDebug("tablename", $tablename);

	return $tablename;	
}

sub _createTable {
#### CREATE DATABASE BY QUERY
	my $self		=	shift;
	my $file		=	shift;

	my $contents = $self->getFileContents($file);
	#$self->logDebug("contents", $contents);
	
	my $tablename = $self->fileToTableName($file);
	return if not defined $tablename;
	
	#print "DOING DROP TABLE\n" if $self->db()->hasTable($tablename);
	$self->db()->dropTable($tablename) if $self->db()->hasTable($tablename);
	
	my $result = $self->db()->do($contents);
	
	return 0 if not defined $result;
	return 1;
}

sub _checkOverwrite {
	my $self		=	shift;
	my $database	=	shift;
	
    my $rootuser       	=   "root";
    my $rootpassword   	=   $self->rootpassword();

	my $warning = "\nDatabase '$database' exists already. Type 'Y' to overwrite it or 'N' to keep it";
	return 0 if not $self->yes($warning);

	#### CREATE DUMPFILE OF AGUA DATABASE
	my $dumpfile = $self->_dumpDb($database, $rootuser, $rootpassword, undef);

	#### DELETE DATABASE
	$self->db()->dropDatabase($database) or die "Can't drop database: $database. $!\n";

	$self->_printOverwriteReport($database, $dumpfile);
	
	return 1;
}

sub _printOverwriteReport {
	my $self		=	shift;
	my $database	=	shift;
	my $dumpfile	=	shift;

	#### TIMESTAMP
	my $timestamp = $self->db()->timestamp();
	my $logfile = $self->logfile();
	my $report = qq{
*******************************************************
[$timestamp] Deleted database: $database
Tables and data have been saved to here:
$dumpfile
The logfile is here:
$logfile
*******************************************************\n};
	print  $report;
	$self->logDebug("report: ", $report);
}

sub _loadDumpfile {
	my $self		=	shift;
	my $database	=	shift;

	$self->logDebug("database", $database);
    my $rootpassword   	=   $self->rootpassword();
	my $dumpfile		=	$self->dumpfile();
	$self->logDebug("dumpfile", $dumpfile);
	my $command = "mysql -u root -p$rootpassword $database < $dumpfile";
	$self->logDebug("command", $command);
	print `$command`;
}

#### 	TEST USER
sub setTestUser {
	my $self		=	shift;
	my $testdatabase = $self->testdatabase() || $self->conf()->getKey("test", "TESTDATABASE");
	$self->logDebug("testdatabase not defined") and exit if not defined $testdatabase;
	
	#### SET DB OBJECT
	my $rootpassword = $self->_getRootPassword();
	$self->logError("rootpassword not defined") and return if not defined $rootpassword;
	$self->setDbObject($testdatabase, "root", $rootpassword) if not defined $self->db();

	#### GET CURRENT VALUES
    my $testuser       	=   $self->testuser() || $self->conf()->getKey("test", "TESTUSER");
    my $testpassword   	=   $self->testpassword() || $self->conf()->getKey("test", "TESTPASSWORD");
	my $length 			= 	9;
	$testpassword		=	$self->createRandomPassword($length) if not $testpassword;
	
    #### TEST USER NAME
	$testuser = $self->_inputValue("Test MySQL username", $testuser);	
    
    #### TEST USER PASSWORD
	$testpassword = $self->_inputValue("Test MySQL user password", $testpassword);	

	#### SET USER AND PASSWORD
	$self->_createDatabaseUser($testdatabase, $testuser, $testpassword);

	#### UPDATE CONF FILE
	$self->conf()->setKey("test", "TESTUSER", $testuser);
	$self->conf()->setKey("test", "TESTPASSWORD", $testpassword);

	#### UPDATE SLOTS
    $self->testuser($testuser);
    $self->testpassword($testpassword);

	return $testuser, $testpassword;
}

#### 	TEST DATABASE
sub createTestDatabase {
	my $self		=	shift;
	
	my $testdatabase = $self->testdatabase() || $self->conf()->getKey("test", "TESTDATABASE");
	$self->logDebug("testdatabase", $testdatabase);

	$testdatabase = $self->conf()->getKey("database", "TESTDATABASE") if not defined $testdatabase;
	$self->logDebug("testdatabase", $testdatabase);
	$self->logDebug("testdatabase not defined") and exit if not defined $testdatabase;

	#### SET DB OBJECT
	my $rootpassword = $self->_getRootPassword();
	$self->logError("rootpassword not defined") and return if not defined $rootpassword;

	#### SET DB OBJECT
	$self->setDbObject("mysql", "root", $rootpassword);
	
	#### DROP DATABASE IF EXISTS	
	$self->db()->dropDatabase($testdatabase);
	
	#### CREATE DATABASE 
	$self->_createDatabase($testdatabase);

	#### SET DB OBJECT
	$self->setDbObject($testdatabase, "root", $rootpassword);
}

sub _setSqlFile {
	my $self		=	shift;
	my $filename	=	shift;

	my $logfile 	=	$self->logfile();
	$self->logCritical("logfile not defined") and exit if not defined $logfile;
	
	my $sqlfile = $logfile;
	$sqlfile =~ s/[^\/]+$//;
	$sqlfile .= $filename;	
}

sub _createDatabaseUser {
	my $self		=	shift;
	my $database	=	shift;
	my $user		=	shift;
	my $password	=	shift;

    my $rootuser       	=   "root";
    my $rootpassword   	=   $self->rootpassword();

	$self->logDebug("rootuser", $rootuser);
	$self->logDebug("rootpassword", $rootpassword);
	
	#### CREATE DATABASE AND USER AND PASSWORD
	my $sqlfile = $self->_setSqlFile("createDbUser.sql");
    $self->logDebug("sqlfile: $sqlfile");
	my $create = qq{
USE mysql;
GRANT SHOW DATABASES ON *.* TO '$user'\@'localhost' IDENTIFIED BY '$password';
GRANT ALL ON $database.* TO '$user'\@'localhost' IDENTIFIED BY '$password';	
FLUSH PRIVILEGES;};
	$self->printToFile($sqlfile, $create);
	my $command = "mysql -u $rootuser -p$rootpassword < $sqlfile";
	$self->logDebug("$command");
	print `$command`;
	
	#### CLEAN UP
	`rm -fr $sqlfile`;
}

sub _getTimestamp {
	my $self		=	shift;
	my $database	=	shift;
	my $user		=	shift;
	my $password	=	shift;

	#### SET DB OBJECT
	$self->setDbObject($database, $user, $password) if not defined $self->db();

	my $timestamp = $self->db()->timestamp();
	$timestamp =~ s/\s+/-/g;
	return $timestamp;
}

sub _dumpDb {
	my $self		=	shift;
	my $database	=	shift;
	my $user		=	shift;
	my $password	=	shift;
	my $dumpfile	=	shift;

	$self->logDebug("dumpfile", $dumpfile);

	#### PRINT DUMP COMMAND FILE
	my $timestamp = $self->_getTimestamp($database, $user, $password);
	
	$dumpfile = $self->dumpfile() if not defined $dumpfile;
	my ($dumpdir) = $dumpfile =~ /^(.+)\/[^\/]+$/;
	$self->logDebug("dumpdir", $dumpdir);
	`mkdir -p $dumpdir` if not -d $dumpdir;
	print "Illumina::Configure::_dumpDb    Can't create dumpdir: $dumpdir\n" if not -d $dumpdir;
	
	my $cmdfile = FindBin::Real::Bin() . "/../sql/dump/agua.$timestamp.cmd";
	$self->printToFile($cmdfile, "#!/bin/sh\n\nmysqldump -u $user -p$password $database > $dumpfile\n");

	#### DUMP CONTENTS OF DATABASE TO FILE
	`chmod 755 $cmdfile`;
	print `$cmdfile`;
	`rm -fr $cmdfile`;

	return $dumpfile;
}

#### MISCELLANEOUS METHODS
sub _inputValue {
	my $self		=	shift;
	my $message		=	shift;
	my $default		=	shift;
	
	$self->logError("message is not defined") if not defined $message;
	$default = '' if not defined $default;
	
	if ( defined $default and $default !~ /^\s*$/ ) {
		print "\n$message [$default]: " ;
	}
	else {
		print "\n$message : ";
	}
	
	my $input = '';
    while ( $input =~ /^\s*$/ )
    {
        $input = <STDIN>;
        $input =~ s/\s+//g;
		
		$default = $input if $input;
		print "\n" and return $default if $default;

        print "\n$message [$default]: " if defined $default and $default !~ /^\s*$/;
        print "\n$message : " if not defined $default;
    }
}

sub _inputHiddenValue {
	my $self		=	shift;
	my $message		=	shift;
	my $default		=	shift;

	$self->logDebug("Illumina::Configure::inputHiddeValue(message, default)");
	$self->logDebug("message", $message);
	$self->logDebug("default", $default);
	
	$self->logError("Illumina::Configure::_inputHiddenValue    message is not defined") if not defined $message;
	$default = '' if not defined $default;
	print "$message []: ";

	my $input = '';
    while ( $input =~ /^\s*$/ )
    {
        $input = <STDIN>;
        $input =~ s/\s+//g;
		$default = $input if $input;
		print "\n" and return $default if $default;

        print "\n$message []: ";
    }
}

sub yes {
#### PROMPT THE USER TO ENTER 'Y' OR 'N'

	my $self		=	shift;
	my $message		=	shift;
	
	return if not defined $message;
	print "$message: ";
    my $max_times = 10;
	
	$/ = "\n";
	my $input = <STDIN>;
	my $counter = 0;
	while ( $input !~ /^Y$/i and $input !~ /^N$/i )
	{
		if ( $counter > $max_times ) { print "Exceeded 10 tries. Exiting...\n"; }
		print "$message: ";
		$input = <STDIN>;
		$counter++;
	}	

	if ( $input =~ /^N$/i )	{	return 0;	}
	else {	return 1;	}
}

sub backupFile {
	my $self		=	shift;
	my $filename	=	shift;
	
	my $counter = 1;
	my $backupfile = "$filename.$counter";
	while ( -f $backupfile )
	{
		$counter++;
		$backupfile = "$filename.$counter";
	}
	`cp $filename $backupfile`;
	
	$self->logError("Could not create backupfile: $backupfile") if not -f $backupfile;
	print "backupfile created: $backupfile\n";
}



sub printToFile {
	my $self		=	shift;
	my $file		=	shift;
	my $text		=	shift;
	
	$self->logDebug("file", $file);
	#### PRINT TO FILE
	open(OUT, ">$file") or $self->logCaller() and $self->logCritical("Can't open file: $file") and exit;
	print OUT $text;
	close(OUT) or $self->logCaller() and $self->logCritical("Can't close file: $file") and exit;	
}

#### CRON JOB
sub cron {
	my $self		=	shift;

=head2

	SUBROUTINE		cron
	
	PURPOSE

		INSERT INTO /etc/crontab COMMANDS TO BE RUN AUTOMATICALLY
		
		ACCORDING TO THE DESIRED TIMETABLE:
		
			1. checkBalancers.pl	-	VERIFY LOAD BALANCERS ARE
			
				RUNNING AND RESTART THEM IF THEY HAVE STOPPED. THIS
				
				TASK RUNS ONCE A MINUTE

	NOTES
	
		cat /etc/crontab
		# /etc/crontab: system-wide crontab
		# Unlike any other crontab you don't have to run the `crontab'
		# command to install the new version when you edit this file
		# and files in /etc/cron.d. These files also have username fields,
		# that none of the other crontabs do.
		
		SHELL=/bin/sh
		PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
		
		# m h dom mon dow user	command
		17 *	* * *	root    cd / && run-parts --report /etc/cron.hourly
		25 6	* * *	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )
		47 6	* * 7	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.weekly )
		52 6	1 * *	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.monthly )

=cut

	print "Running cron configuration\n";
	
	my $installdir = $self->conf()->getKey("installdir", undef);	
	$self->logDebug("installdir", $installdir);

	my $inserts	= [
		qq{* 20     * * *   root    MAILTO=""; $installdir/bin/scripts/checkBalancers.pl > /tmp/agua-loadbalancers.out}
];
	my $crontext = `crontab -l`;
	$crontext = `crontab -l` if $crontext =~ /No crontab for root/;

	#### REMOVE INSERTS IF ALREADY PRESENT	
	foreach my $insert ( @$inserts ) {
		my $temp = $insert;
		$temp =~ s/\*/\\*/g;
		$temp =~ s/\$/\$/g;
		$temp =~ s/\-/\\-/g;
		$temp =~ s/\//\\\//g;
		$crontext =~ s/$temp//msg;
	}

	#### ADD INSERTS TO BOTTOM OF CRON LIST	
	$crontext =~ s/\s+$//;
	foreach my $insert ( @$inserts ) {	$crontext .= "\n$insert";	}
	$crontext .= "\n";
	
	`echo '$crontext' | crontab -`;
}

sub _crontextFromFile {
	my $self		=	shift;
	my $crontab		=	shift;

	$crontab = "/etc/crontab" if not defined $crontab;
	$self->backupFile($crontab);
	my $temp = $/;
	$/ = undef;
	open(FILE, $crontab) or die "Can't open crontab: $crontab\n";
	my $crontext = <FILE>;
	close(FILE) or die "Can't close crontab: $crontab\n";
	$/ = $temp;

	return $crontext;
}

sub _crontextToFile {
	my $self		=	shift;
	my $crontab		=	shift;
	my $crontext	=	shift;

	open(OUT, ">$crontab") or die "Can't open crontab: $crontab\n";
	print OUT $crontext;
	close(OUT) or die "Can't close crontab: $crontab\n";
}


    
} #### END PACKAGE Illumina::WGS::Util::Configure


