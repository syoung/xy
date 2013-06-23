#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin); 
use lib "$Bin/../lib";
use lib "$Bin/../extlib/lib/perl5";
use Scalar::Util qw(looks_like_number);
use Data::Dumper; 
use Getopt::Long;
use Pod::Usage; 
use Illumina::WGS::Sample;
use Illumina::WGS::Status;
use Illumina::WGS::WorkflowQueue; 
use Illumina::WGS::Workflow;
use Switch;
use File::Spec::Functions ':ALL';

our %Opt; 
my $hr_status2id = Illumina::WGS::Status->hasref_status2id;
my $hr_id2status = Illumina::WGS::Status->hashref_id2status;

&process_commandline(); 

# this is only needed for this script because of simple file checks
# these could be dropped
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


### get active samples with build finished 
my $sql = qq! 
select distinct(wq.workflow_queue_id) as wfq_id, 
p.project_name, 
s.sample_barcode, 
s.sample_id 
from workflow_queue wq, workflow_queue_samplesheet wqs, 
flowcell_samplesheet ss, sample s , project p 
where 
s.project_id  = p.project_id and
ss.sample_id = s.sample_id and 
wqs.flowcell_samplesheet_id = ss.flowcell_samplesheet_id and
wq.workflow_queue_id = wqs.workflow_queue_id and 
wq.status_id = 16
!; 
##TODO add active sample and projects


print $sql ; 

if ($Opt{project_name}){
	$sql .= qq! and xxx.project_name = '$Opt{project_name}' !; 
}	
if ($Opt{sample_barcode}){
	$sql .= qq! and xxx.sample_barcode  = '$Opt{sample_barcode}' !; 
}	

$Opt{debug} && print $sql . "\n"; 	
my $dbh = Illumina::WGS::Sample->db_Main; 
my $sth = $dbh->prepare($sql); 
$sth->execute || die "cannot execute $sql : $!"; 
my $c=0; 
while( my $w = $sth->fetchrow_hashref){
	my $wq = Illumina::WGS::WorkflowQueue->retrieve($w->{wfq_id}); 
	my $workflow = Illumina::WGS::Workflow->retrieve($wq->workflow_id); 
	my $sample = Illumina::WGS::Sample->retrieve($w->{sample_id});
	print "qc'ing " . join(" " ,
		$w->{project_name}, 
		$w->{sample_barcode}, 
		$workflow->workflow_name,		
		$wq->workflow_queue_id, $wq->output_server, $wq->output_dir ) . "\n";  	
	my $thresholds = YAML::Tiny->read_string($workflow->report_thresholds)|| die "Cannot read config"; 
	my $table= $workflow->workflow_name; 
	my $sql2 = qq! select * from $table where status_id = 97 !; 
	my $sth2 = $dbh->prepare($sql2); 
	$sth2->execute; 
	while (my $r = $sth2->fetchrow_hashref){
		$c++; 
        my $pass = 1;
		my %build_stats_cutoffs; 
		if ($sample->cancer eq 'Y'){
			%build_stats_cutoffs = %{$thresholds->[1]->{cancer_samples}}; 
		}
		else {
			%build_stats_cutoffs = %{$thresholds->[1]->{normal_samples}}; 		
		}
		## switch from x to g hack
		#set yield min for this instance
		# 
		if ($sample->target_fold_coverage >= 110 && $workflow->workflow_name =~ /casava/){
			$build_stats_cutoffs{pf_total_gb} = ['ge' , $sample->target_fold_coverage]; 		
		}
		elsif ($sample->target_fold_coverage < 110 && $workflow->workflow_name =~ /casava/){
			$build_stats_cutoffs{casava_coverage_autosomal_depth} = ['ge', $sample->target_fold_coverage]; 	
		}
		elsif ($sample->target_fold_coverage >= 110 && $workflow->workflow_name =~ /ISIS/){
			#ASSUMES READS OF 100 bases
			$build_stats_cutoffs{total_reads} = ['ge' , ($sample->target_fold_coverage/100)*1000000000]; 		
		}
		elsif ($sample->target_fold_coverage < 110 && $workflow->workflow_name =~ /ISIS/){
			$build_stats_cutoffs{genome_coverage} = ['ge' , $sample->target_fold_coverage];		
		}
		else {
			print "Unknown workflow yield threshold.. need to hack in the sepc to this script!!\n"; 
			next
		}
		my @reasons; 
		my $sample_barcode = $w->{sample_barcode}; 
		my $sdir = $wq->output_dir; 
		#print $sdir . "\n"; 
        # Does the directory exist 
        if ( ! -d $sdir ) {
            push @reasons, "No sample directory!";
            $pass = 0;
        }
        # Are the build_stats there?
        my $build_stats = catfile($sdir, $workflow->report_file_name); 
		if ( ! -f $build_stats ) {
            push @reasons, "Build stats $build_stats doesn't exist";
            $pass = 0;
        }
		#Are the build stats file the same as in the database ?
		my $md5sum = `md5sum $build_stats | awk '{print \$1}'`;
		chomp $md5sum ; 
		if ($md5sum ne $r->{check_md5sum}){
            push @reasons, "Build stats is not the same as the one stored in the database";
            $pass = 0;	
			next; 
		}
        # Test to see if the cutoffs hold
        foreach my $col (sort keys %build_stats_cutoffs ) {
			my $value = $r->{$col}; 
			if (! defined $value){
				print " col $col is not defined for $sdir \n";
				push @reasons, "$col:is_not_defined"; 
				$pass = 0;
			}
		    my @comparison_arr = @{$build_stats_cutoffs{$col}};
            my $cutoff_operator = $comparison_arr[0];
            my $cutoff_value = $comparison_arr[1];
            my $value_check_pass = value_check($value, $cutoff_operator, $cutoff_value);
            if ( ! $value_check_pass ) {
                push @reasons, "$col:$value-$cutoff_operator-$cutoff_value";
                $pass = 0;
            }
            if ($Opt{verbose}) {
                print STDERR "\tChecking $col : $value => $pass\n";
            }
        } 
        if( $Opt{force} && !$pass) {
				$pass=1; 
                print "FORCE_PASS $sample_barcode:", join("|", @reasons)."\n";
        }	
		if( $Opt{verbose}) {
				if (!$pass){
					print "$sample_barcode => FAILED". join("|", @reasons)."\n"; 
				}
				else {
					print "$sample_barcode => PASS\n"; 
				}
        }
		my $comments = (join("|", @reasons));
		if ($Opt{dryrun}){
			print "$sample_barcode => PASS $pass; $comments\n"; 
			next; 
		}
		
		#PASS = 77 FAIL = 17
		my $sql_update = qq! update $table 
			set status_id = ? where report_id = ? !; 
		my $comments_table = join("_", $table, 'comment'); 
        my $sth_u = $dbh->prepare($sql_update); 
		if ( $pass ) {
			$sth_u->execute(77, $r->{report_id}); 
        }
		else {
			$sth_u->execute(17, $r->{report_id});
			my $sql_insert = qq! insert into $comments_table 
			(report_id, comment_content, user) values (?,?,?)!; 
			my $sth_insert = $dbh->prepare($sql_insert); 
			$sth_insert->execute($r->{report_id}, $comments, 'auto_qc'); 
        }
	}
}
print "found $c sample entries \n"; 


sub value_check {
    my $value = shift;
    my $cutoff_operator = shift;
    my $cutoff_value = shift;

    my $pass = '';

    if ( ! looks_like_number($value) ) {
        return 0;
    }
    switch ($cutoff_operator) {
        case 'gt'   { if($value > $cutoff_value) { return 1 } }
        case 'ge'   { if($value >= $cutoff_value) { return 1 } }
        case 'lt'   { if($value < $cutoff_value) { return 1 } }
        case 'le'   { if($value <= $cutoff_value) { return 1 } }
        case 'eq'   { if($value == $cutoff_value) { return 1 } }
        else        { return 0 }
    }

    return 0;
}




sub process_commandline {
     my $yaml = YAML::Tiny->read( "$Bin/../config.yaml" )|| die "cannot read config.yaml";
     %Opt  = %{$yaml->[0]};
  	GetOptions(
		\%Opt, qw(
        debug
		verbose
        status=s
        version
		force
        dryrun
		project_name=s
		sample_barcode=s
        now
		dryrun
        help
		)
	) || pod2usage(0);
	if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
	if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
    if (!$Opt{now}) { pod2usage( ); }
}

