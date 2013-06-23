use MooseX::Declare;

class Test::Agua::Monitor::SGE extends Agua::Monitor::SGE {
use Data::Dumper;
use Test::More;

# Ints
has 'workflowpid'	=> ( isa => 'Int|Undef', is => 'rw', required => 0 );
has 'workflownumber'=>  ( isa => 'Str', is => 'rw' );
has 'start'     	=>  ( isa => 'Int', is => 'rw' );
has 'submit'  		=>  ( isa => 'Int', is => 'rw' );

# Strings
has 'fileroot'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'qstat'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'queue'			=>  ( isa => 'Str|Undef', is => 'rw', default => 'default' );
has 'cluster'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'username'  	=>  ( isa => 'Str', is => 'rw' );
has 'workflow'  	=>  ( isa => 'Str', is => 'rw' );
has 'project'   	=>  ( isa => 'Str', is => 'rw' );

# Objects
has 'json'		=> ( isa => 'HashRef', is => 'rw', required => 0 );
has 'db'	=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'stages'		=> 	( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'stageobjects'	=> 	( isa => 'ArrayRef', is => 'rw', required => 0 );
has 'monitor'		=> 	( isa => 'Maybe|Undef', is => 'rw', required => 0 );
has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Conf::Agua',
	default	=>	sub { Conf::Agua->new(	backup	=>	1, separator => "\t"	);	}
);

method BUILD ($hash) {
	$self->initialise();
}

method initialise () {
	my $logfile = $self->logfile();
	$self->logDebug("logfile", $logfile);
	$self->conf()->logfile($logfile);
}

method testSetMonitor {
	$self->logDebug("");
	$self->logDebug("self->conf", $self->conf());
	my $clustertype =  $self->conf()->getKey('agua', 'CLUSTERTYPE');
	my $classfile = "Agua/Monitor/" . uc($clustertype) . ".pm";
	my $module = "Agua::Monitor::$clustertype";
	$self->logDebug("Doing require $classfile");
	require $classfile;

	my $monitor = $module->new(
		{
			'pid'		=>	$$,
			'conf' 		=>	$self->conf(),
			'db'	=>	$self->db()
		}
	);

	return $monitor;
}


}   #### Test::Agua::Monitor::SGE