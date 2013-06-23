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
use Illumina::WGS::Flowcell;
use Illumina::WGS::FlowcellLaneQC;
use Illumina::WGS::Status;
use Illumina::WGS::TrimReport; 
use Illumina::WGS::FlowcellReport; 
use YAML::Tiny;
use File::Temp qw/ tempfile tempdir /;
our %Opt; 
&process_commandline(); 


my $hr_status2id = Illumina::WGS::Status->hasref_status2id;
my $hr_id2status = Illumina::WGS::Status->hashref_id2status;


#find lanes that belong to finished flowcells but have not yet been qc'ed
my $sql = qq! select t.* from flowcell_report_trim t left join 
	flowcell_lane_qc q on q.flowcell_id = t.flowcell_id and 
	q.lane= t.lane , 
	flowcell f 
	where q.flowcell_lane_qc_id is null 
	and f.flowcell_id = t.flowcell_id
	and f.status_id = 2!; 
if ($Opt{location}){
	my $l = $Opt{location}; 
	$sql .= qq! and f.location = '$l' !; 
}
my $sth = Illumina::WGS::FlowcellReport->db_Main->prepare($sql); 
$sth->execute(); 
my @reports = Illumina::WGS::FlowcellReport->sth_to_objects($sth);  


my $user = 'autobot'; 
my $host = `hostname`; 
chomp $host; 



###
my $good=0; 
my $bad =0; 

my @to_create; 
foreach my $rep (@reports){
	my $fc= Illumina::WGS::Flowcell->retrieve($rep->flowcell_id); 
	$Opt{debug} && print $fc->location. "\t" . $rep->lane. "\n"; 
	my @trim_report = Illumina::WGS::TrimReport->search(flowcell_id => $rep->flowcell_id, lane => $rep->lane);  
	if (!@trim_report){
		$Opt{debug} && print "cannot find trim_report for fcid " . $rep->flowcell_id . " " . $rep->lane . "\n" ; 
		next; 
	}
	elsif (@trim_report && $trim_report[0]->report_time ne 'FINISHED'){
		$Opt{debug} && print "trim report report time as not FINISHED \n"; 
		next; 
	}
	my $tr = $trim_report[0]; 
	my @comments; 
	my $flag = 0 ;
	
	#### rules 
	if ($tr->per_good_tiles){
		if ($tr->per_good_tiles < $Opt{min_per_good_tiles}){
			$Opt{debug} && print " good_tiles_less_than_min:".$Opt{min_per_good_tiles} ."\n"; 
			push @comments,  'good_tiles_less_than_min:'.$Opt{min_per_good_tiles} ; 
			$flag++;  
		}
	}		
	else {
		$Opt{debug} && print "per_good_tiles not defined for lane " . $tr->lane . " fc id ". $rep->flowcell_id . "\n"; 
		next; 
	}
	### read1 
	if ($rep->read1_phiX_error_rate){
		if ($rep->read1_phiX_error_rate > $Opt{max_read1_phiX_error_rate} ){
			$Opt{debug} && print " read1_phiX_error_rate greater than 1.5 " . $rep->read1_phiX_error_rate . "\n"; 
			push @comments,  'read1_phiX_error_rate_greater_than_max:'.$Opt{max_read1_phiX_error_rate}; 
			$flag++; 
		}
	}
	else{
		$Opt{debug} && print " read1_phiX_error_rate  not defined ". $rep->flowcell_id . "\n"; 
		#tb dont spike phix
		#next; 
	}
	#read 2 
	if ($rep->read2_phiX_error_rate){
		if ($rep->read2_phiX_error_rate > $Opt{max_read2_phiX_error_rate} ){
			$Opt{debug} && print " read2_phiX_error_rate greater than 1.5 " . $rep->read2_phiX_error_rate . "\n"; 
			push @comments,  'read2_phiX_error_rate_greater_than_max:'.$Opt{max_read2_phiX_error_rate}; 
			$flag++; 
		}
	}
	else{
		$Opt{debug} && print " read2_phiX_error_rate  not defined ". $rep->flowcell_id . "\n"; 
		#tb dont spike phix
		#next; 
	}
	
	#per q30 read1 
	if ($rep->read1_per_q30){
		if ($rep->read1_per_q30 < $Opt{min_read1_per_q30} ){
			$Opt{debug} && print " read1_per_q30 less than " . $rep->read1_per_q30 ." < ". $Opt{min_read1_per_q30} . "\n"; 
			push @comments,  'read1_per_q30_less_than_min:'.$Opt{min_read1_per_q30}; 
			$flag++; 
		}
	}
	else{
		$Opt{debug} && print " read1_per_q30 not defined ". $rep->flowcell_id . "\n"; 
		next; 
	}
	#per q30 read2 
	if ($rep->read2_per_q30){
		if ($rep->read2_per_q30 < $Opt{min_read2_per_q30} ){
			$Opt{debug} && print " read2_per_q30 less than " . $rep->read2_per_q30 ." < ". $Opt{min_read2_per_q30} . "\n"; 
			push @comments,  'read2_per_q30_less_than_min:'.$Opt{min_read2_per_q30}; 
			$flag++; 
		}
	}
	else{
		$Opt{debug} && print " read2_per_q30 not defined ". $rep->flowcell_id . "\n"; 
		next; 
	}
	## END OF RULES
	my %t; 
	if ($flag){		
		%t = (
				flowcell_id => $tr->flowcell_id, 
				lane => $tr->lane,
				comments => join(";",@comments), 
				status_id => $hr_status2id->{'bioinfo_threshold'}, 
				user_and_ip => join("_", $user, $host)
		);
		$bad++; 
	}
	else {
		%t = (
				flowcell_id => $tr->flowcell_id, 
				lane => $tr->lane,
				comments => join(";",@comments), 
				status_id => $hr_status2id->{'lane_qc_pass'}, 
				user_and_ip => join("_", $user, $host)
		);	
		$good++; 
	}
	push @to_create, \%t; 
}	

print "FOUND $good good lanes and $bad bad lanes "; 



if (!$Opt{dryrun}){
	my $out; 
	foreach my $qc (@to_create){
		my $d = Illumina::WGS::FlowcellLaneQC->create($qc); 
		$Opt{debug} && print "stored entry for  " . $qc->{flowcell_id} . " lane " . $d->lane . "\n"; 
	} 
}
print "DONE\n";


sub process_commandline {
     my $yaml = YAML::Tiny->read( "$Bin/../config.yaml" )|| die "cannot read config.yaml";
     %Opt  = %{$yaml->[0]};
  	GetOptions(
		\%Opt, qw(
        debug
        status=s
        version
        dryrun
		location=s
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

monitor_lanes.pl - qc lanes
  less than min tiles (set in the config.yaml) 
  more than r1 phiX error rate
  
  
=head1 SYNOPSIS

monitor_lanes.pl  -now [-dry] [-debug]

log can be found in ../log/monitor_lanes.log

=cut


1; 
