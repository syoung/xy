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
use File::Basename;
use Illumina::WGS::BuildReport;
use Illumina::WGS::Sample;
use Illumina::WGS::Status;
use Switch;
use File::Spec::Functions ':ALL';

our %Opt; 
my $hr_status2id = Illumina::WGS::Status->hasref_status2id;
my $hr_id2status = Illumina::WGS::Status->hashref_id2status;

&process_commandline(); 


### get active samples with build finished 
my $sql = qq! 
	select * from sample_overview_2 xxx where 
	xxx.sample_status = 'active' and xxx.project_status = 'active' and 
	xxx.build_report_id is not null and xxx.build_queue_status = 'build_finished'!; 
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
my @to_update_build_reports; 
my @to_update_samples;
SAMPLE: while( my $w = $sth->fetchrow_hashref){
		$c++; 
        my $pass = 1;
		my %build_stats_cutoffs; 
		if ($w->{cancer} eq 'Y'){
			%build_stats_cutoffs = %{$Opt{build_qc_cancer_samples}}; 
		}
		else {
			%build_stats_cutoffs = %{$Opt{build_qc_normal_samples}}; 		
		}
		## switch from x to g hack
		if ($w->{target_fold_coverage}>=110){
			$build_stats_cutoffs{pf_total_gb} = ['ge' , $w->{target_fold_coverage}]; 
		}
		else {
			$build_stats_cutoffs{casava_coverage_autosomal_depth} = ['ge', $w->{target_fold_coverage}]; 		
		}
		my @reasons; 
		my $sample_barcode = $w->{sample_barcode}; 
		my $br = Illumina::WGS::BuildReport->retrieve($w->{build_report_id}); 		
		my $sdir = catdir($Opt{build_root}, $w->{project_name}, $w->{sample_barcode}); 
		#print $sdir . "\n"; 
        # Does the directory exist
        if ( ! -d $sdir ) {
            push @reasons, "No sample directory!";
            $pass = 0;
        }
        # Does the deliverable dir exist?
        if ( ! -d $sdir ) {
            push @reasons, "No deliverable directory";
            $pass = 0;
        }
        # Are the build_stats there?
        my $build_stats = catfile($sdir, 'build_stats.txt'); 
		if ( ! -f $build_stats ) {
            push @reasons, "Build stats $sample_barcode/build_stats.txt doesn't exist";
            $pass = 0;
        }
		#Are the build stats file the same as in the database ?
		my $md5sum = `md5sum $build_stats | awk '{print \$1}'`;
		chomp $md5sum ; 
		if ($md5sum ne $br->check_md5sum){
            push @reasons, "Build stats is not the same as the one stored in the database";
            $pass = 0;	
			print "should be updated soon; skip this sample $sample_barcode for now\n"; 
			next; 
		}
        # Is the md5sum ok there?
		my $md5sumfile = catfile($sdir, $sample_barcode.'.md5sum.ok'); 
        if ( ! -f $md5sumfile ) {
            push @reasons, "md5sum check not present";
            $pass = 0;
        }
        # Test to see if the cutoffs hold
        foreach my $col (sort keys %build_stats_cutoffs ) {
			my $value = $br->$col; 
			if (! defined $value){
				print " col $col is not defined for $sdir \n";
				next SAMPLE; 
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
                print STDERR "\tChecking $col : $value\n";
            }
        } 
        if( $Opt{force} && !$pass) {
				$pass=1; 
                print "FORCE_PASS $sample_barcode:", join("|", @reasons). "\t".$w->{sample_barcode}."\t". $br->to_string_extended. "\n";
        }	
		if( $Opt{verbose}) {
				if (!$pass){
					print "FAILED". join("|", @reasons)."\t"; 
				}
				print $w->{sample_barcode}."\t".$br->to_string_extended."\n";
        }
        if ( $pass ) {
			$br->comments(join("|", @reasons)); 
			push @to_update_build_reports, $br; 
			my $sample = Illumina::WGS::Sample->retrieve($w->{sample_id}); 
			$sample->status_id($hr_status2id->{'qc_pass'}); 
			push @to_update_samples, $sample; 
        }
		else {
			$br->comments(join("|", @reasons)); 
			push @to_update_build_reports, $br; 
			my $sample = Illumina::WGS::Sample->retrieve($w->{sample_id}); 
			$sample->status_id($hr_status2id->{'qc_fail'}); 
			push @to_update_samples, $sample; 
        }
		
}
print "found $c sample entries \n"; 

if (!$Opt{dryrun}){
	foreach my $b (@to_update_build_reports){
		$b->update; 
	}
	foreach my $s (@to_update_samples){
		$s->update; 
	}
}
else {
	foreach my $b (@to_update_build_reports){
		$b->discard_changes; 
	}
	foreach my $s (@to_update_samples){
		$s->discard_changes; 
	}
	print "DRY RUN!!!!\n"; 
}




#subs 

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

