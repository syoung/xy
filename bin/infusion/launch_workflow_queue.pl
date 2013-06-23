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
use File::Path qw(make_path remove_tree);
use Illumina::WGS::Sample; 
use Illumina::WGS::Status; 
use Illumina::WGS::Workflow; 
use Illumina::WGS::WorkflowQueue;
use Illumina::WGS::WorkflowQueueSampleSheet; 
use File::Path qw(make_path remove_tree);
our %Opt; 
process_commandline(); 


#will be used by the multi-site work
my $hostname = `hostname`;
chomp $hostname;
if ($Opt{$hostname}){
	$Opt{debug} && print "I know this host $hostname as ". $Opt{$hostname} . "!\n"; 
	$hostname = $Opt{$hostname}; 
}
else {
	print "I don't know this host $hostname!\n"; 
	exit; 
}
print "running on $hostname\n"; 

my $hr_status2id = Illumina::WGS::Status->hasref_status2id;
my $hr_id2status = Illumina::WGS::Status->hashref_id2status;


my $q = qq! select distinct(wq.workflow_queue_id) from 
	sample s , 
	project p, 
	flowcell_samplesheet fs, 
	workflow_queue_samplesheet wqs , 
	workflow_queue wq , 
	workflow w
	where 
	p.project_id = s.project_id and 
	s.sample_id = fs.sample_id and 
	wqs.workflow_queue_id = wq.workflow_queue_id and 
	wq.workflow_id = w.workflow_id and 
	wq.status_id = 14 and 
	wq.compute_server = \"$hostname\"; 
	!; 
#	and s.status_id = 63
#	and p.status_id  = 63!; 
print $q. "\n"; 


if ( $Opt{project_name} ) {
    $q .= qq! and p.project_name = '$Opt{project_name}' !;
}
if ( $Opt{sample_barcode} ) {
    $q .= qq! and s.sample_barcode = '$Opt{sample_barcode}' !;
}
if ($Opt{workflow_name}){
	$q.= qq! and w.workflow_name='$Opt{workflow_name}' !; 
}

my $dbh = Illumina::WGS::WorkflowQueue->db_Main; 
my $sth = $dbh->prepare($q); 
$sth->execute; 
my $c=0; 
while (my $rs = $sth->fetchrow_hashref){
	my $wq= Illumina::WGS::WorkflowQueue->retrieve($rs->{workflow_queue_id}); 
	my $w= Illumina::WGS::Workflow->retrieve($wq->workflow_id); 
	$Opt{debug} && print "ready to launch " . $wq->workflow_queue_id . " workflow queue id \n"; 
	my @wqs = Illumina::WGS::WorkflowQueueSampleSheet->search(workflow_queue_id => $wq->workflow_queue_id); 

	### only one sample one project right now.. later 
	#### this will break bad if more than one sample	
	## doable though
	my $sample; 
	my $project;  
	foreach my $wqs (@wqs){
		my $ss = Illumina::WGS::SampleSheet->retrieve($wqs->flowcell_samplesheet_id); 
		$sample = Illumina::WGS::Sample->retrieve($ss->sample_id); 
		$project = Illumina::WGS::Project->retrieve($sample->project_id); 
		last;
	}
	my $workdir = catdir($Opt{build_root}, $project->project_name, 'Configs'); 	
	my $config_file = catfile($workdir, $sample->sample_barcode . "_WF" . $wq->workflow_queue_id .  '.config'); 
	my $sge_options = join(" ", $w->sge_min_parameters, ' -e ' .  $config_file.'.err',  '-o ' . $config_file . '.out'); 
	my $launch_command = join(" ", $sge_options, $w->driver_location, $config_file); 
	if ($Opt{dryrun}){
		print $workdir . "\n"; 
		print $w->driver_location ."\n"; 
		print $wq->workflow_config . "\n"; 
		print $launch_command . "\n"; 
		print "dry run!!\n"; 
	}
	else {
		if (!-d $workdir && !make_path($workdir)){
			print "failed to mkpath $workdir; next; \n"; 
			next; 
		}
		if (open my $fh, ">", $config_file){
			print $fh $wq->workflow_config. "\n"; 
		}
		else {
			print "cannot write to file $config_file \n";
			next; 
		}
		my $sge_id = `$launch_command`; 
		if ($sge_id =~ /^\d+$/){
			print " launched $sge_id \n"; 
		}
		else {
			print "FAILED to launch $launch_command\n"; 
			next; 
		}
		$wq->sge_job_id($sge_id); 
		$wq->status_id($hr_status2id->{building}); 
		$wq->update; 
	}
	$c++; 
	if ($c == $Opt{limit}){
		print "reached limit ". $Opt{limit} . "\n"; 
		last; 
	}
}




sub process_commandline {
	my $yaml = YAML::Tiny->read( "$Bin/../config.yaml" )|| die "cannot read config.yaml";
    %Opt = %{$yaml->[0]};
	$Opt{limit}=50; 
	GetOptions(
		\%Opt, qw(
        debug
        manual
        version
		dryrun
		sample_barcode=s
		workflow_name=s
		workflow_version=s
		limit=n
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


