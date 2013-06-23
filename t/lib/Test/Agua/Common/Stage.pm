use MooseX::Declare;

class Test::Agua::Common::Stage with (Test::Agua::Common,
	Agua::Common::Base,
	Agua::Common::Database,
	Agua::Common::Logger,
	Agua::Common::Privileges,
	Agua::Common::Stage) {

use Data::Dumper;
use Test::More;
use Test::DatabaseRow;
use Agua::DBaseFactory;

our $DEBUG = 0;
#$DEBUG = 1;

# Ints
has 'workflowpid'	=> ( isa => 'Int|Undef', is => 'rw', required => 0 );
has 'workflownumber'=>  ( isa => 'Str', is => 'rw' );
has 'start'     	=>  ( isa => 'Int', is => 'rw' );
has 'submit'  		=>  ( isa => 'Int', is => 'rw' );
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 2 );  
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 5 );

# Strings
has 'dumpfile'		=> ( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'database'		=> ( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'user'			=> ( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'password'		=> ( isa => 'Str|Undef', is => 'rw', required => 1 );

has 'fileroot'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'qstat'			=> ( isa => 'Str|Undef', is => 'rw', default => '' );

has 'queue'			=>  ( isa => 'Str|Undef', is => 'rw', default => 'default' );
has 'cluster'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'username'  	=>  ( isa => 'Str', is => 'rw' );
has 'workflow'  	=>  ( isa => 'Str', is => 'rw' );
has 'project'   	=>  ( isa => 'Str', is => 'rw' );

# Objects
has 'json'			=> ( isa => 'HashRef', is => 'rw', required => 0 );
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'stages'		=> 	( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'stageobjects'	=> 	( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'monitor'		=> 	( isa => 'Maybe|Undef', is => 'rw', required => 0 );

has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Conf::Agua',
	default	=>	sub { Conf::Agua->new(	backup	=>	1, separator => "\t"	);	}
);


####///}}

method BUILD ($hash) {
	foreach my $key ( keys %$hash ) {
		$self->$key($hash->{$key}) if defined $hash->{$key} and $self->can($key);
	}

	$self->logDebug("self", $self);
	#print "Test::Agua::Common::Stage::BUILD    self:\n";
	#print Dumper $self;
	
	$self->initialise();
}

method initialise () {
	my $dumpfile 	= $self->dumpfile();
	$self->reloadTestDatabase($dumpfile);	
    $Test::DatabaseRow::dbh = $self->db()->dbh();	
}

method testAddRemoveStage ($json) {
    diag("Test addRemoveStage");

    #### TABLE
    my $table       =   "stage";
    my $addmethod       =   "_addStage";
    my $removemethod    =   "_removeStage";
    my $requiredkeys    =   [
        'username',
		'project',
		'workflow',
		'name',
		'number',
		'workflownumber'
    ];
    my $definedkeys =   [
		'name',
		'owner',
		'type',
		'executor',
		'location',
		'number',
		'project',
		'workflow',
		'username',
		'workflownumber'
    ];

    my $undefinedkeys =   [
		'localonly',
		'notes',
		'description'
    ];

    $self->logDebug("Doing genericAddRemove(..)");
    $self->genericAddRemove(
        {
            json	        =>	$json,
            table	        =>	$table,
            addmethod	    =>	$addmethod,
            addmethodargs	=>	$json,
            removemethod	=>	$removemethod,
            removemethodargs=>	$json,
            requiredkeys	=>	$requiredkeys,
            definedkeys	    =>	$definedkeys,
            undefinedkeys	=>	$undefinedkeys
        }        
    );
    
}   #### testAddRemoveStage


}   #### Test::Agua::Common::Stage