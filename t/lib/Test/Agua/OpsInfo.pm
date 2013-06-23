use MooseX::Declare;

class Test::Agua::OpsInfo extends Agua::OpsInfo with Test::Agua::Common::Util {
#### EXTERNAL MODULES
use Data::Dumper;
use Test::More;

use FindBin qw($Bin);
use lib "../../../t/lib";
use lib "../../../lib";

#### INTERNAL MODULES
use Test::Conf::Agua;

has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Test::Conf::Agua',
	default	=>	sub { Test::Conf::Agua->new(	memory	=>	1	);	}
);

####////}}}}

method testNew {
	diag("Test new");
	
	my $inputfile	=	$self->inputfile();
	my $found = -f $inputfile;
	ok(-f $inputfile, "new    inputfile found");
	my $expectedpackage = "fastqc";
	my $package = $self->package();
	is($package, $expectedpackage, "new    package attribute");
	is_deeply($self->authors(), [
		{
			"name"	=> "Stuart Young",
			"email"	=> "stuartpyoung\@gmail.com"
		}
	], "new    authors attribute");
	is(${$self->authors()}[0]->{name}, "Stuart Young", "new    author's name");
	is(${$self->authors()}[0]->{email}, "stuartpyoung\@gmail.com", "new    author's email");
}

method testSet {	
	diag("Test set");

	my $originalfile 	=   "$Bin/inputs/fastqc.ops";
	my $outputfile 		=   "$Bin/outputs/fastqc.ops";
	my $expectedfile	=	"$Bin/inputs/fastqc-set.ops";

	#### SET FILES
	$self->setUpFile($originalfile, $outputfile);
	$self->inputfile($outputfile);
	$self->outputfile(undef);

	#### TESTS
	my $expectedpackage = "FASTQC";
	$self->set("package", $expectedpackage);
	my $package = $self->package();
	is($package, $expectedpackage, "set    package attribute");
	ok($self->diff($outputfile, $expectedfile), "set    outputfile matches expectedfile");	

	my $expectedpublications = [
		{
			"title"	=> "FastQC: A quality control application for FastQ data",
			"URL"	=> "http://www.bioinformatics.bbsrc.ac.uk/projects/fastqc"
		}
	];
	
	$self->set("publications", $expectedpublications);
	my $publications = $self->publications();
	$self->logDebug("publications", $publications);
	is($publications, $expectedpublications, "set    publications attribute");
	is(${$publications}[0]->{URL}, "http://www.bioinformatics.bbsrc.ac.uk/projects/fastqc", "set    publications->{URL}");
}


method testParseFile {
	diag("Test parseFile");

	my $originalfile 	=   "$Bin/inputs/fastqc.ops";
	my $inputfile 		=   "$Bin/outputs/fastqc.ops";

	#### SET FILES
	$self->setUpFile($originalfile, $inputfile);
	$self->inputfile($inputfile);
	$self->outputfile(undef);
	
	#### TESTS
	$self->parseFile($inputfile);
	my $expectedpackage = "fastqc";
	my $package = $self->package();
	is($package, $expectedpackage, "parseFile    package attribute");
	ok(-f $inputfile, "parseFile    inputfile found");
	is_deeply($self->authors(), [
		{
			"name"	=> "Stuart Young",
			"email"	=> "stuartpyoung\@gmail.com"
		}
	], "parseFile    authors");
	is(${$self->authors()}[0]->{name}, "Stuart Young", "parseFile    author's name");
	is(${$self->authors()}[0]->{email}, "stuartpyoung\@gmail.com", "parseFile    author's email");
}

method testGenerate {
	diag("Test generate");

	my $inputfile 		=   "$Bin/outputs/fastqc.ops";
	my $generatedfile 	=   "$Bin/inputs/fastqc-generated.ops";
	
	#### SET FILES
	`rm -fr $inputfile`;
	$self->inputfile($inputfile);
	$self->outputfile(undef);

	#### TESTS
	$self->generate();

	#### CHECK FILE	
	ok(-f $inputfile, "generate    generated file found");
	ok($self->diff($inputfile, $generatedfile), "generate    correct file generated");

	#### ADD ATTRIBUTES
	my $expectedpackage = "fastqc";
	$self->set('package', $expectedpackage);
	my $package = $self->package();
	is($package, $expectedpackage, "generate    package attribute");
	$self->set('authors', [
		{
			"name"	=> "Stuart Young",
			"email"	=> "stuartpyoung\@gmail.com"
		}
	]);
	is_deeply($self->authors(), [
		{
			"name"	=> "Stuart Young",
			"email"	=> "stuartpyoung\@gmail.com"
		}
	], "generate    authors");
}

method testIsKey {
	diag("Test isKey");

	my $originalfile 	=   "$Bin/inputs/fastqc.ops";
	my $outputfile 		=   "$Bin/outputs/fastqc.ops";
	my $expectedfile	=	"$Bin/inputs/fastqc-set.ops";

	#### SET FILES
	$self->setUpFile($originalfile, $outputfile);
	$self->inputfile($outputfile);
	$self->outputfile(undef);
	
	ok($self->isKey('package'), "isKey    correct attribute");
	ok(! $self->isKey('UNKNOWN_ATTRIBUTE'), "isKey    incorrect attribute");	
	ok(! $self->isKey(undef), "isKey    undefined attribute");
}

}   #### Test::Agua::OpsInfo