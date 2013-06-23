#! /usr/bin/perl 
use strict; 
use FindBin qw($Bin); 
use lib "$Bin/../lib";
use lib "$Bin/../extlib/lib/perl5";
use Data::Dumper; 
use warnings;
use Getopt::Long;
use Pod::Usage; 
use Illumina::WGS::Sample; 
use Illumina::WGS::Workflow; 
our %Opt; 

process_commandline(); 

my @samples = Illumina::WGS::Sample->search(sample_barcode => $Opt{sample_barcode});  
if (!@samples){
	print "sample not found " . $Opt{sample_barcode} . "\n"; 
}
my $sample = $samples[0]; 
my %conf_options; 
if ($Opt{use_gt_gender}){
	$conf_options{use_gt_gender}= 1;
}
if ($Opt{override_compute_server}){
	$conf_options{compute_server} = $Opt{override_compute_server}; 
}
if ($Opt{override_output_server}){
	$conf_options{output_server} = $Opt{override_output_server}; 
}
if ($sample){
	my $hr_config   = $sample->prepare_config(\%conf_options); 
	my @wf = Illumina::WGS::Workflow->search(workflow_name => $Opt{workflow_name}, workflow_version =>  $Opt{workflow_version}); 
	my $config_text = $sample->format_config($wf[0], $hr_config); 
	print $config_text . "\n"; 
}


sub process_commandline {
	GetOptions(
		\%Opt, qw(
        debug
        manual
        version
		workflow_name=s
		workflow_version=s
		sample_barcode=s
		override_compute_server=s
		override_output_server=s
        help
		  )
	) || pod2usage(0);
	if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
	if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
	if ( $Opt{version} ) { die "fetch_sample_config.pl, ", q$Revision:  $, "\n"; } 
    !$Opt{sample_barcode} && pod2usage('! missing sample barcode'); 
    !$Opt{workflow_name} && pod2usage('! missing workflow_name'); 
    !$Opt{workflow_version} && pod2usage('! missing workflow_version'); 

}


1; 

=head1 NAME

fetch_sample_fullconfig.pl - fetches a config for a sample in the saffron db


=head1 SYNOPSIS

fetches a config for a sample in the saffron db

fetch_sample_fullconfig.pl -s SAMPLE_BARCODE [-format YAML|isis_resequencing|casava_clia]

Manifest gender is the gender provided by the customer in the manifest. 
Sequenced gender and array gender are the same, from the genotyping track.  

=cut


