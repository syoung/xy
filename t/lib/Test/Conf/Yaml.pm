package Test::Conf::Yaml;

#### INTERNAL MODULES
use Test::Common;
use Conf::Yaml;
use Logger;
use base qw(Test::Common Conf::Yaml Logger);

#### EXTERNAL MODULES
use Test::More;
use JSON;
use Data::Dumper;
use FindBin qw($Bin);

sub getAncestors {
	#print "Test::Conf::Yaml\n";
	return __PACKAGE__->Class::ISA::super_path();
}

sub testRead {
	my $self		=	shift;
	
	diag("#### read");
	
	my $configfile	=	"$Bin/inputs/read/config.yaml";
	my $logfile		=	"$Bin/outputs/read/read.log";	
	my $expectedfile=	"$Bin/inputs/read/config.json";
	my $expectedjson=	$self->getFileContents($expectedfile);

	my $expected = JSON->new()->decode($expectedjson);

	#### LOAD SLOTS AND READ FILE	
	$self->configfile($configfile);
	$self->logfile($logfile);
	$self->read();

	my $yaml 		= 	$self->yaml();
	
	is_deeply($yaml->[0], $expected);
}

sub testGetKey {
	my $self		=	shift;
	
	diag("#### getKey");
	
	my $configfile	=	"$Bin/inputs/getkey/config.yaml";
	my $logfile		=	"$Bin/outputs/getkey/getkey.log";	
	my $expectedfile=	"$Bin/inputs/getkey/config.json";
	my $expectedjson=	$self->getFileContents($expectedfile);

	#### LOAD SLOTS AND READ FILE	
	$self->configfile($configfile);
	$self->logfile($logfile);
	$self->read();

	my $username	=	$self->getKey("username");
	my $expectedusername	=	"pcruz";
	is($username, $expectedusername, "username");

	my $emails 			= 	$self->getKey("error_emails");
	my $expectedemails	=	 [
		"pcruz\@illumina.com",
		"bsickler\@illumina.com",
		"sajay\@illumina.com",
		"knobuta\@illumina.com",
		"amaroo\@illumina.com"
	];
	is_deeply($emails, $expectedemails, "array");

	my $fasta 			= 	$self->getKey("fasta_locations");
	my $expectedfasta 	= {
		"NCBI37_XX" => "/illumina/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XX/HumanNCBI37_XX.fa",
		"NCBI37_XY" => "/illumina/scratch/services/Genomes/FASTA_UCSC/HumanNCBI37_XY/HumanNCBI37_XY.fa",
		"NCBI36_XY" => "/illumina/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XY.fa",
		"NCBI36_XX" => "/illumina/scratch/services/Genomes/FASTA_UCSC/HumanNCBI36_XY/HumanNCBI36_XX.fa"
	};
	is_deeply($fasta, $expectedfasta, "hash");
}

sub testGetSubKey {
	my $self		=	shift;
	
	diag("#### getKey    subKey");
	
	my $configfile	=	"$Bin/inputs/getkey/config.yaml";
	my $logfile		=	"$Bin/outputs/getkey/getkey.log";	
	my $expectedfile=	"$Bin/inputs/getkey/config.json";
	my $expectedjson=	$self->getFileContents($expectedfile);

	#### LOAD SLOTS AND READ FILE	
	$self->configfile($configfile);
	$self->logfile($logfile);
	$self->read();

	my $username	=	$self->getKey("test", "TESTUSER");
	$self->logDebug("username", $username);
	my $expectedusername = "testuser";
	ok($username eq $expectedusername, "getKey    subKey: username");
	
	my $database	=	$self->getKey("test", "TESTDATABASE");
	$self->logDebug("database", $database);
	my $expecteddatabase = "testdatabase";
	ok($database eq $expecteddatabase, "getKey    subKey: database");
	
	my $password	=	$self->getKey("test", "TESTPASSWORD");
	$self->logDebug("password", $password);
	my $expectedpassword = "testpassword";
	ok($password eq $expectedpassword, "getKey    subKey: password");
}
sub testSetKey {
	my $self		=	shift;
	
	diag("#### setKey");
	
	my $configfile	=	"$Bin/inputs/setkey/config.yaml";
	my $expectedfile=	"$Bin/inputs/setkey/config.expected.yaml";
	my $outputfile	=	"$Bin/outputs/setkey/config.yaml";
	my $logfile		=	"$Bin/outputs/setkey/setkey.log";	
	my $expectedjson=	$self->getFileContents($expectedfile);

	#### LOAD SLOTS AND READ FILE	
	$self->configfile($configfile);
	$self->outputfile($outputfile);
	$self->logfile($logfile);
	$self->read();

	my $expectedusername	=	"test";
	my $username	=	$self->setKey("username", $expectedusername);

	$self->configfile($outputfile);
	$username		=	$self->getKey("username");
	is($username, $expectedusername, "username");
}



1;
