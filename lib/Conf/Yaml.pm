use MooseX::Declare;
use Method::Signatures::Modifiers;

class Conf::Yaml with (Conf, Xy::Common::Logger, Xy::Common::Util) {

use YAML::Tiny;
use Data::Dumper;

# Bool
has 'memory'		=> ( isa => 'Bool', 	is => 'rw', default	=> 	0);

# Ints
has 'valueoffset'		=>  ( isa => 'Int', is => 'rw', default => 24 );  
# Strings
has 'inputfile' =>	(	is	=>	'rw',	isa	=>	'Str'	);
has 'outputfile' => (	is	=>	'rw',	isa	=>	'Str'	);

# Objects
has 'yaml' 	=> (
	is 		=>	'rw',
	isa 	=> 	'YAML::Tiny',
	default	=>	method {	YAML::Tiny->new();	}
);

#####////}}}}
method BUILD ($arguments) {
	$self->initialise($arguments);
}

method initialise ($arguments) {
	$self->setSlots($arguments);
}

method read ($inputfile) {
=head2

	SUBROUTINE 		read
	
	PURPOSE
	
		READ CONFIG FILE AND STORE VALUES
		
=cut
	$self->logDebug("inputfile", $inputfile);
	
	$inputfile = $self->inputfile() if not defined $inputfile;
	$self->logCritical("inputfile not defined") and exit if not defined $inputfile;
	
	my $yaml = YAML::Tiny->read($inputfile) or $self->logCritical("Can't open inputfile: $inputfile") and exit;
	#$self->logDebug("yaml", $yaml);

	$self->yaml($yaml);
}

method copy ($file) {
	$self->logNote("file", $file);
	$self->outputfile($file);
	$self->write($self->outputfile());	
};

method write ($file) {
	$self->logNote("file", $file);
	$file = $self->outputfile() if not defined $file;	
	$file = $self->inputfile() if not defined $file;	
	#$self->logNote("FINAL file", $file);
	
	my $memory = $self->memory();
	$self->logNote("memory", $memory);
	return $self->writeToMemory() if $self->memory();

	my $yaml 		=	$self->yaml();
	$self->logDebug("yaml", $yaml);

	return $yaml->write($file);
}

method getKey ($key, $subkey) {
	$self->logDebug("key", $key);
	$self->logDebug("subkey", $subkey) if defined $subkey;
	$self->read($self->inputfile());

	return $self->_getKey($key, $subkey);
}

method _getKey ($key, $subkey) {
	$self->logDebug("key", $key);
	$self->logDebug("subkey", $subkey) if defined $subkey;
	
	my $yaml 		= 	$self->yaml();
	#$self->logDebug("yaml", $yaml);
	#my $value = $yaml->[0]->{$key};
	#$self->logDebug("value", $value);

	return $yaml->[0]->{$key} if not defined $subkey;
	
	return $yaml->[0]->{$key}->{$subkey};
}

method setKey ($key, $value) {
	$self->logDebug("key", $key);
	$self->logDebug("value", $value);
	$self->read($self->inputfile());
	$self->_setKey($key, $value);
	$self->write($self->outputfile());
}

method _setKey ($key, $value) {
	$self->logDebug("key", $key);
	$self->logDebug("value", $value);
	my $yaml 		= 	$self->yaml();
	$yaml->[0]->{$key}	=	$value;

	$self->yaml($yaml);
}

method removeKey ($key) {
	$self->logDebug("key", $key);

	$self->_removeKey($key);
	
	$self->write($self->outputfile());
}

method _removeKey ($key) {
	$self->logDebug("key", $key);

	return if not defined $self->yaml()->[0]->{$key};
	
	return delete $self->yaml()->[0]->{$key};
}

method writeToMemory {
	$self->logDebug("");
	
	#### DO NOTHING
}


}	#### Conf::Yaml