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
use Illumina::WGS::Project; 
use Illumina::WGS::Workflow; 
use Illumina::WGS::WorkflowQueue;
use Illumina::WGS::WorkflowQueueSampleSheet; 

our %Opt; 


my $hr_status2id = Illumina::WGS::Status->hasref_status2id;
my $hr_id2status = Illumina::WGS::Status->hashref_id2status;
process_commandline(); 

my $q = qq! select s.sample_id, sw.workflow_id, p.project_id 
	from sample s , sample_workflow sw , project p
	where s.sample_id = sw.sample_id and 
	p.project_id = s.project_id 
	!; 

#if you are reanilizing a sample not active	
if (!$Opt{override_status}){
	$q .= qq!
	and s.status_id = 63
	and p.status_id  = 63 !; 
}
#if you want to ignore the fact that gt is missing
#note some of the pipelines might not like it
if (!$Opt{exclude_gt}){	
	$q .= qq!
	and s.genotype_report is not null 
	and s.gt_deliv_src is not null
	and s.gt_vcf is not null!; 
}
$Opt{debug} && print $q. "\n"; 

if ( $Opt{project_name} ) {
    $q .= qq! and p.project_name = '$Opt{project_name}' !;
}
if ( $Opt{sample_barcode} ) {
    $q .= qq! and s.sample_barcode = '$Opt{sample_barcode}' !;
}


my $dbh = Illumina::WGS::Sample->db_Main; 
my $sth = $dbh->prepare($q); 
$sth->execute; 
#if there is at least one workflow queue entry for one
# workflow name for a sample don't insert any other
while (my $rs = $sth->fetchrow_hashref){
	my $sample = Illumina::WGS::Sample->retrieve($rs->{sample_id});
	my $project = Illumina::WGS::Project->retrieve($rs->{project_id}); 
	my $sid = $sample->sample_id; 
	my $workflow= Illumina::WGS::Workflow->retrieve($rs->{workflow_id}); 
	$Opt{debug} && print "found requirement for " . 	
		join(" ", $sample->sample_barcode, 
			$workflow->workflow_name, 
			$workflow->workflow_version). "\n"; 		

	my $wid = $workflow->workflow_id; 
	my $qs = qq! 
		select * from workflow_queue wq , 
		workflow_queue_samplesheet wqs, 
		flowcell_samplesheet fs
		where wq.workflow_queue_id = wqs.workflow_queue_id and 
		wqs.flowcell_samplesheet_id = fs.flowcell_samplesheet_id and 
		fs.sample_id = $sid and wq.workflow_id = $wid!; 
	my $sth1= $dbh->prepare($qs); 
	$sth1->execute; 
	#if there is already one entry, regardless of the number of
	# lanes used, skip it.
	if (my $rss = $sth1->fetchrow_hashref){
		$Opt{debug} && print "\talready found a entry for " .
			join(" ", $sample->sample_barcode, 
				$workflow->workflow_name, 
				$workflow->workflow_version). "\n"; 		
		next;
	}	
	else {		
		$Opt{debug} && print "\ttry to create an entry for " .
			join(" ", $sample->sample_barcode, 
				$workflow->workflow_name, 
				$workflow->workflow_version). "\n"; 		
	}
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
	my $hr_config   = $sample->prepare_config(\%conf_options); 
	
	if (!$hr_config){
		print "\tFAILED to initiate config for ". $sample->sample_barcode . "; next\n"; 
		next; 
	}
	if (!$Opt{override_yield} && 
		$hr_config->{trimmed_yield_gb} < $hr_config->{target_trimmed_yield_gb}){
		print "\t#### INSUFFICIENT YIELD #### ". $sample->sample_barcode . 
		" actual: ". $hr_config->{trimmed_yield_gb} . 
		"; target: " . $hr_config->{target_trimmed_yield_gb} . "\n"; 
		next; 
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
			$text =~ s/$random_name/$id/; 
			my $dest = $wfq->output_dir; 
			$dest =~ s/$random_name/$id/;
			$wfq->output_dir($dest); 
			$wfq->workflow_config($text);
			$wfq->status_id($hr_status2id->{in_build_queue});  
			$wfq->update;
			print "\tcreated a workflow queue entry\n"; 

		}
		else {
			print "\twould create a workflow queue entry\n"; 
			#print Dumper \%wf_queue; 
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



=head1 SYNOPSIS


=cut


