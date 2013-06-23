#! /usr/bin/perl 
use strict; 
use warnings; 
use FindBin qw($Bin); 
use lib "$Bin/../lib";
use lib "$Bin/../extlib/lib/perl5";
use Data::Dumper; 
use Getopt::Long;
use Pod::Usage; 
use File::Spec::Functions ':ALL';
use Illumina::WGS::RequeueReport;
use Illumina::WGS::Status;
use Illumina::WGS::Flowcell; 
use Illumina::WGS::Sample; 
use DateTime::Format::Natural ; 
use Illumina::WGS::RequeueReportSampleSheet; 
use DateTime; 
use YAML::Tiny;
our %Opt; 
&process_commandline(); 

##
# for a active sample check requeues 
# if there is a lane sequenced after the requeue date 
# add to fulfield 
# if fullfield greater or equal than requested close requeue request
#


my $hr_status2id = Illumina::WGS::Status->hasref_status2id;
my $hr_id2status = Illumina::WGS::Status->hashref_id2status;

#alignments running
#get requeue request that have been clustered
# first associate a sample sheet with a requeue request
# TODO make a on delete for this entry from the requeue and from the sample sheet
#'73', 'requeue_acknowledged', 'lab sets it from in_queue'
#'in_requeue_queue'

my @requeued_clustered = Illumina::WGS::RequeueReport->search(
	status_id => $hr_status2id->{'clustered_on_flowcell'}
); 

$Opt{debug} && print " found " . (scalar @requeued_clustered) . "\n"; 

my $dbh = Illumina::WGS::RequeueReport->db_Main; 
my $parser = DateTime::Format::Natural->new;
foreach my $rq (@requeued_clustered){
	my $sample = Illumina::WGS::Sample->retrieve($rq->sample_id); 
	my $sid = $sample->sample_id; 
	$Opt{debug} && print $sample->sample_barcode . "############################\n";
	### get sample sheets NOT associated with a requeue request
	my $q = qq! select ss.* from flowcell_samplesheet ss left join requeue_report_samplesheet rs
				on ss.flowcell_samplesheet_id = rs.flowcell_samplesheet_id 
				where rs.flowcell_samplesheet_id is null and ss.sample_id =  $sid!; 
	my $dbh = Illumina::WGS::SampleSheet->db_Main; 
	my $sth = $dbh->prepare($q); 
	$sth->execute; 
	my @ss = Illumina::WGS::SampleSheet->sth_to_objects($sth); 
	if (!@ss){
		print "no sample sheet info for ". $sample->sample_barcode . " requeue report id ". $rq->requeue_report_id. "\n"; 
		next; 
	}
	#just added the timestamp to samplesheet. used the flowcell start date for now
	my $rq_date = $rq->date_created; 
	my $rq_parsed_date = $parser->parse_datetime($rq_date);  
	my $i=0; 
	foreach my $s (@ss){
		#ignore rehyb
		my $fc = Illumina::WGS::Flowcell->retrieve($s->flowcell_id);
		if ($fc->attempting_rehyb && $fc->attempting_rehyb eq 'Y'){
			$Opt{debug} && print "run rehybed " . $fc->location. "; next\n" ;
			next; 
		}
		my $date = $fc->run_start_date;
		my $fc_parsed_date = $parser->parse_datetime($date); 
		# if flowcell run after the requeue add the samplesheet entry to the table
		if ($fc_parsed_date > $rq_parsed_date){
			$Opt{debug} && print "fc date $date ; requeue date $rq_date \n";
			$Opt{debug}  && print "going to associate requeue " . $rq->requeue_report_id . " sample sheet ". $s->flowcell_samplesheet_id . " \n";
			if (!$Opt{dryrun} && $Opt{now}){
				my %h = (
					flowcell_samplesheet_id => $s->flowcell_samplesheet_id , 
					requeue_report_id => $rq->requeue_report_id
				); 
				my $l = Illumina::WGS::RequeueReportSampleSheet->create(\%h); 
				$Opt{debug} && print  "created entry " . $l->requeue_report_samplesheet_id . "\n" ; 
			}
		}
	}
}


#check if enough samples sheets are to close the requeues
foreach my $rq (@requeued_clustered){
	my @ss_rq= Illumina::WGS::RequeueReportSampleSheet->search(requeue_report_id => $rq->requeue_report_id); 
	my $associated = scalar @ss_rq; 
	my $queued_count = $rq->lanes_requested;
	my $seen_so_far = $rq->current_seen;
	$Opt{debug} && print  " seen so far $seen_so_far vs associated $associated \n"; 
	if ($seen_so_far < $associated){
		$rq->current_seen($associated); 
	}
	$Opt{debug} && print " associate $associated vs queueued originally $queued_count \n";  	
	if ($associated >= $queued_count){
		$rq->status_id($hr_status2id->{requeue_fulfilled}); 
	}
	if (!$Opt{dryrun} && $Opt{now}){
		$rq->update; 
	}
}



sub process_commandline {
    
    my $yaml = YAML::Tiny->read( "$Bin/../config.yaml" )|| die "cannot read config.yaml";
    %Opt  = %{$yaml->[0]}; 
  	GetOptions(
		\%Opt, qw(
        debug
        status=s
        version
        dryrun
        now
        help
		  )
	) || pod2usage(0);
	if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
	if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
    if (!$Opt{now}) { pod2usage( ); }
}
 __END__
 
 
 
=head1 NAME

monitor_alignments.pl 

=head1 SYNOPSIS

monitor_alignments.pl  -now [-status aligning] [-skip_delete_unaligned]

log can be found in ../log/monitor_alignment.log

takes the alignments running and tries to find finished and failed alignments

    -skip_delete_unaligned prevents deleting the unaligned folders for finished alignments

=cut


1; 