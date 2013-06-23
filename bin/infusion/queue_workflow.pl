#! /usr/bin/perl 
use strict; 
use FindBin qw($Bin); 
use lib "$Bin/../lib";
use lib "$Bin/../extlib/lib/perl5";
use Data::Dumper; 
use warnings;
use Getopt::Long;
use Pod::Usage; 
use File::Spec::Functions ':ALL';
use Illumina::WGS::Sample; 
use Illumina::WGS::Status; 
use Illumina::WGS::Workflow; 
use Illumina::WGS::WorkflowQueue;
use Illumina::WGS::WorkflowQueueSampleSheet; 

our %Opt; 


my $hr_status2id = Illumina::WGS::Status->hasref_status2id;
my $hr_id2status = Illumina::WGS::Status->hashref_id2status;
process_commandline(); 


my @workflow = Illumina::WGS::Workflow->search(
	workflow_name=> $Opt{workflow_name}, 
	workflow_version=> $Opt{workflow_version} 
);  
if (scalar @workflow !=1 ){
	print "unknown workflow " . $Opt{workflow_name}. " " . $Opt{workflow_version} . "\n";
	exit; 
}
my $workflow= $workflow[0];
my @samples = Illumina::WGS::Sample->search(sample_barcode => $Opt{sample_barcode});  
if (!@samples){
	print "sample not found " . $Opt{sample_barcode} . "\n"; 
}
my $sample = $samples[0];

#my options for config
## this is where a cascading config would be usefull
my %conf_options; 
$conf_options{workflow_name} = $workflow->workflow_name; 
if ($Opt{use_gt_gender}){
	$conf_options{use_gt_gender}= 1;
}
if ($Opt{override_compute_server}){
	$conf_options{compute_server} = $Opt{override_compute_server}; 
}
if ($Opt{override_output_server}){
	$conf_options{output_server} = $Opt{override_output_server}; 
}

###
my $hr_config   = $sample->prepare_config(\%conf_options); 
if (!$hr_config){
	print "FAILED to initiate config for ". $sample->sample_barcode . "; next\n"; 
	next; 
}
if (!$Opt{override_yield} && $hr_config->{trimmed_yield_gb} < $hr_config->{target_trimmed_yield_gb}){
	print "#### INSUFFICIENT YIELD #### ". $sample->sample_barcode . " actual: ". $hr_config->{trimmed_yield_gb} . "; target: " . $hr_config->{target_trimmed_yield_gb} . "\n"; 
	exit;
}
my @samplesheet_ids; 
if (!@{$hr_config->{good_lanes}}){
	print "no good lanes available!!!!\n"; 
	next; 
}
else {
	foreach my $gssid (@{$hr_config->{good_lanes}}){
		push @samplesheet_ids, $gssid->{ssid};
	}
}
#output config text
my $config_text = $sample->format_config($workflow, $hr_config); 

#will be used by the multi-site work
#default to run and output on the server with the most flowcells
if (@samplesheet_ids && $config_text){
	my $date = `date "+%Y-%m-%d %H:%M:%S"`;
	my %wf_queue = (
		workflow_id => $workflow->workflow_id, 
		set_date => $date,
		workflow_config => $config_text, 
		compute_server => $hr_config->{compute_server}, 
		status_id => $hr_status2id->{transient}, 
		output_dir =>  $hr_config->{output_dir}, 
		output_server => $hr_config->{output_server}
	);
	my $wfq; 
	if (!$Opt{dryrun}){
		$wfq = Illumina::WGS::WorkflowQueue->create(\%wf_queue); 
		my $id= 'WF'.$wfq->workflow_queue_id;
		my $random_name = $hr_config->{random_name}; 
		my $text = $wfq->workflow_config; 
		$text =~ s/$random_name/$id/g; 
		my $dest = $wfq->output_dir; 
		$dest =~ s/$random_name/$id/g;
		$wfq->output_dir($dest); 
		$wfq->workflow_config($text);
		$wfq->status_id($hr_status2id->{in_build_queue});  
		$wfq->update;
	}
	else {
		print "would create a workflow queue entry\n"; 
		print Dumper \%wf_queue; 
	}
	foreach my $ssids (@samplesheet_ids){	
		if (!$Opt{dryrun}){	
			my %h = ( 
				workflow_queue_id => $wfq->workflow_queue_id, 
				flowcell_samplesheet_id => $ssids
			); 
			my $wf_ss  =  Illumina::WGS::WorkflowQueueSampleSheet->create(\%h); 
		}
		else {
			#print "would create sample sheet associations \n"; 
		}
	}	
}

sub process_commandline {
    my $yaml = YAML::Tiny->read( "$Bin/../config.yaml" )|| die "cannot read config.yaml";
    %Opt  = %{$yaml->[0]}; 
	GetOptions(
		\%Opt, qw(
        debug
        manual
        version
		dryrun
		sample_barcode=s
		project_name=s
		override_compute_server=s
		override_output_server=s
		exclude_gt
		workflow_name=s
		workflow_version=s
		override_yield
		now
        help
		  )
	) || pod2usage(0);
	if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
	if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
	if ( $Opt{version} ) { die "fetch_sample_config.pl, ", q$Revision:  $, "\n"; } 
	if (!$Opt{now}){ pod2usage(0);}
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


