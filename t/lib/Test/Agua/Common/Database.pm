package Test::Agua::Common::Database;
use Moose::Role;
use Method::Signatures::Simple;

use Test::More;
use Test::DatabaseRow;
use Data::Dumper;

method setUpTestDatabase () {
    #### LOAD DATABASE FROM SCRATCH
	$self->logDebug("Doing prepareTestDatabase()");
    $self->prepareTestDatabase();

	$self->logDebug("Doing loadDatabase()");
    $self->loadDatabase();
}

method prepareTestDatabase {
	$self->logDebug("");
    my $database 	= 	$self->database();
	$database 		= 	$self->conf()->getKey("database", "TESTDATABASE");
    my $user 		=	$self->conf()->getKey("database", "TESTUSER");
    my $password 	= 	$self->conf()->getKey("database", "TESTPASSWORD");
	$self->logNote("database not defined or empty") if not defined $database or not $database;
	$self->logDebug("database", $database);
	$self->logDebug("user", $user);
	$self->logDebug("password", $password);

    $self->setDbh({
		database	=>	$database,
		user  		=>  $user,
		password    =>  $password
	});

    #### DROP DATABASE
	$self->logDebug("Doing dropDatabase()");
    $self->db()->dropDatabase($database) if defined $self->db()->dbh();
	
    #### CREATE DATABASE
	$self->logDebug("Doing createDatabase()");
    $self->db()->createDatabase($database);
	
	$self->logDebug("AFTER createDatabase");
}

method reloadTestDatabase ($dumpfile) {
	$self->logNote("");
	my $database    =   $self->conf()->getKey('database', 'TESTDATABASE');
	my $user        =   $self->conf()->getKey('database', 'TESTUSER');
	my $password    =   $self->conf()->getKey('database', 'TESTPASSWORD');
	
	$self->logError("database not defined") if not defined $database;
	$self->logError("dumpfile not defined") if not defined $dumpfile;

	#### SET DBH
	$self->setDbh({
		user 		=> 	$user,
		password	=>	$password,
		database	=>	$database
	});

	#### DROP ALL TABLES IN DATABASE
	my $tables = $self->db()->showTables();
	$tables = [] if not defined $tables;
	$self->logNote("tables: @$tables");

	my $success = 1;
	foreach my $table ( @$tables )
	{
		my $query = qq{DROP TABLE $table};
		$self->logNote("$query");
		$success = $self->db()->do($query);	
		$self->logError("Can't drop table: $table") if not $success;
	}
	$self->logNote("success", $success);

	#### RELOAD DATABASE
	$self->logNote("loading database");
	my $load = qq{mysql -u $user -p$password $database < $dumpfile};
	$self->logNote("$load");
	print `$load`;

	#### RESET DBH
	$self->logDebug("DOING second setDbh()");
	$self->setDbh({
		user 		=> 	$user,
		password	=>	$password,
		database	=>	$database
	});

	#### CHECK TABLES
	$tables = $self->db()->showTables();
	$self->logWarning("Failed to load - no response to 'SHOW TABLES'") if not defined $tables or not @$tables;
	$self->logNote("tables: @$tables");
}

method genericRemove ($args) {
    my $json	        =	$args->{json};
    my $table	        =	$args->{table};
    my $removemethod	=	$args->{removemethod};
    my $requiredkeys	=	$args->{requiredkeys};
    my $definedkeys	    =	$args->{definedkeys};
    my $undefinedkeys	=	$args->{undefinedkeys};
    
    $self->logError("json not defined") if not defined $json;
    $self->logError("table not defined") if not defined $table;
    $self->logError("removemethod not defined") if not defined $removemethod;

    $self->json($json);

    #### GET INITIAL ROW COUNT
	my $initialrows = $self->rowCount($table, undef);
    $self->logNote("initialrows", $initialrows);

    #### DO REMOVE
    $self->$removemethod();

    #### CHECK ENTRY HAS BEEN REMOVED    
    my $where = $self->where($json, $requiredkeys);
    not_row_ok(
        table   =>  $table,
        where   =>  $where,
        label   =>  "Entry does not exist in '$table' after $removemethod"
    );

    #### GET FINAL ROW COUNT
    my $finalrows 	= $self->rowCount($table, undef);
;
    ok($initialrows == ($finalrows + 1), "one row removed (final row count: $finalrows)");
}


method genericAddRemove ($args) {
    $self->logDebug("args", $args);

    my $json	        =	$args->{json};
    my $table	        =	$args->{table};
    my $addmethod	    =	$args->{addmethod};
    my $addmethodargs	=	$args->{addmethodargs};
    my $removemethod	=	$args->{removemethod};
    my $removemethodargs=	$args->{removemethodargs};
    my $requiredkeys	=	$args->{requiredkeys};
    my $definedkeys	    =	$args->{definedkeys};
    my $undefinedkeys	=	$args->{undefinedkeys};
    
    $self->logError("json not defined") if not defined $json;
    $self->logError("table not defined") if not defined $table;
    $self->logError("addmethod not defined") if not defined $addmethod;
    $self->logError("removemethod not defined") if not defined $removemethod;

    $self->json($json);

    #### VERIFY ENTRY DOES NOT EXIST ALREADY
    my $where = $self->where($json, $requiredkeys);
    $self->logDebug("where", $where);

    not_row_ok(
        table   =>  $table,
        where   =>  $where,
        label   =>  "entry doesn't exist in table '$table' before $addmethod"
    );

    #### GET INITIAL ROW COUNT
	my $initialrows = $self->rowCount($table, undef);
    $self->logDebug("initialrows", $initialrows);

    #### DO ADD
    $self->logDebug("Doing $addmethod");
    $self->$addmethod($addmethodargs);

    #### CHECK NUMBER OF ROWS ADDED
    my @rows = (); 
    row_ok(
        table   =>  $table,
        where   =>  $where,
        label   =>  "Get row count after $addmethod",
        store_rows =>   \@rows
    );
	
    my $rowcount_afteradd = $#rows + 1;
    ok($rowcount_afteradd == 1, "One row added by $addmethod");

    #### VALIDATE DEFINED FIELDS IN ADDED ENTRY
    my $entry = $rows[0];
    $self->validateDefinedFields($json, $entry, $definedkeys) if defined $definedkeys;

    #### VALIDATE UNDEFINED FIELDS IN ADDED ENTRY
    $self->validateUndefinedFields($entry, $undefinedkeys) if defined $undefinedkeys;
    
    #### DO REMOVE
    $self->$removemethod($removemethodargs);

    #### CHECK ENTRY HAS BEEN REMOVED    
    not_row_ok(
        table   =>  $table,
        where   =>  $where,
        label   =>  "Entry does not exist in '$table' after $removemethod"
    );

    my $finalrows = $self->rowCount($table, undef);
    ok($initialrows == $finalrows, "initial row count equals final row count: $finalrows");
}

method rowCount ($table, $where) {
	my $query = qq{SELECT COUNT(*) FROM $table};
	$query .= " $where" if defined $where;
	#$self->logNote("query", $query);
	return $self->db()->query($query);
}

method where ($json, $keys) {
#my $DEBUG = 1;
    #$self->logDebug("json", $json);

    $self->logError("json not defined") if not defined $json;
    $self->logError("keys not defined") if not defined $keys;
    my $where = [];
    for my $key ( @$keys )
    {
        push @$where, $key;
        push @$where, $json->{$key};
    }
    
    return $where;
}


method validateDefinedFields ($entry, $json, $keys) {
#my $DEBUG = 1;
    $self->logNote("(entry, json, keys)");
    #$self->logDebug("entry", $entry);
	#$self->logDebug("json", $json);
	
    $self->logError("json not ") if not  $json;
    $self->logError("keys not ") if not  $keys;

    foreach my $key ( @$keys )
    {
    	ok($entry->{$key}	eq	$json->{$key}, "field '$key' value matches");
    }   
}

method validateUndefinedFields ($entry, $keys) {
    foreach my $key ( @$keys )
    {
    	is($entry->{$key}, undef, "field '$key' UNDEF OK");
    }   
}

method insertData ($table, $hash) {
    my $fields = $self->db()->fields($table);
    $self->logDebug("fields: @$fields");
    my $insert = '';
    for ( my $i = 0; $i < @$fields; $i++ )
    {
        next if $$fields[$i] eq "datetime";
        my $value = $hash->{$$fields[$i]} ? $hash->{$$fields[$i]} : '';
        $insert .= "'$value',";
    }
    $insert =~ s/,$//;
    $insert .= ", NOW()";
    my $query = qq{INSERT INTO $table VALUES ($insert)};
    $self->logDebug("query", $query);
	
	#### TEST QUERY
    ok($self->db()->do($query), "inserted testversion row into $table");

	#### TEST INSERTED FIELD VALUES
    row_ok(
        table   =>  $table,
        where   =>  [ %$hash ],
        label   =>  "testversion row values"
    );
}

method setTestDbh {
	$self->logDebug("");
    my $database 	= 	$self->database();
	$database 		= 	$self->conf()->getKey("database", "TESTDATABASE");
    my $user 		=	$self->conf()->getKey("database", "TESTUSER");
    my $password 	= 	$self->conf()->getKey("database", "TESTPASSWORD");
	$self->logNote("database not defined or empty") if not defined $database or not $database;
	$self->logDebug("database", $database);
	$self->logDebug("user", $user);
	$self->logDebug("password", $password);

    return $self->setDbh({
		database	=>	$database,
		user  		=>  $user,
		password    =>  $password
	});
}

method loadDatabase {
#### LOAD DATA INTO DATABASE
	my $dumpfile	=	$self->dumpfile();
    $self->logDebug("dumpfile", $dumpfile);
    $self->reloadTestDatabase($dumpfile);
    $self->logDebug("Finished loadDatabase");
}

method setDatabaseHandle {
	$self->logDebug("");

    #### SET DBH FOR TEST USER
    my $database = $self->conf()->getKey("database", "TESTDATABASE");
    my $user = $self->conf()->getKey("database", "TESTUSER");
    my $pass = $self->conf()->getKey("database", "TESTPASSWORD");
    $self->setDbh({
        database    =>  $database,
        user        =>  $user,
        password    =>  $pass
    });
}

method setTestDatabaseRow {
	$self->logDebug("");
    $Test::DatabaseRow::dbh = $self->db()->dbh();
}




method loadTsvFile ($table, $file) {
	return if not $self->can('db');
	#$self->logDebug("table", $table);
	#$self->logDebug("file", $file);
	
	$self->setDbh() if not defined $self->db();
	return if not defined $self->db();print Dumper ;
	my $query = qq{LOAD DATA LOCAL INFILE '$file' INTO TABLE $table};
	#$self->logDebug("query", $query);
	my $success = $self->db()->do($query);
	$self->logCritical("load data failed") if not $success;
	
	return $success;	
}


1;
