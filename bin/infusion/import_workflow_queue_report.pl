#! /usr/bin/perl 
use strict; 
use warnings; 
use FindBin qw($Bin); 
use lib "$Bin/../lib";
use lib "$Bin/../extlib/lib/perl5";
use Data::Dumper; 
use Getopt::Long;
use Pod::Usage; 
use Illumina::WGS::WorkflowQueue;
use Illumina::WGS::Workflow; 
use Illumina::WGS::Status; 
use File::Spec::Functions ':ALL';
use YAML::Tiny;
our %Opt; 

&process_commandline(); 

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
my $dbh = Illumina::WGS::Status->db_Main; 
#build_finished = 16

my %q = (
	output_server => $hostname,
	status_id => 16
); 
my @wfq = Illumina::WGS::WorkflowQueue->search(%q); 	
my @to_store; 


#got to be a way to make this faster. The left join is a bit hard because 
# I don't know the table name before hand. 

foreach my $w (@wfq){
	my $wfq_id = $w->workflow_queue_id; 
	my $wf = Illumina::WGS::Workflow->retrieve($w->workflow_id); 
	my $table = $wf->workflow_name; 
	my $f = catfile($w->output_dir,$wf->report_file_name); 
	my $sth = $dbh->prepare("SELECT * FROM $table where workflow_queue_id = $wfq_id"); 
	$sth->execute; 
	my @columns = @{$sth->{NAME}};
	my $hr_res = $sth->fetchrow_hashref; 
	if (-s $f){
		print "found report file for " . $w->output_dir . " $f; importing\n"; 
		my $h = parse_report($f); 
		my $md5sum = `md5sum $f | awk '{print \$1}'`;
		chomp $md5sum;
		if ($hr_res->{check_md5sum} && $md5sum eq $hr_res->{check_md5sum}){
			$Opt{debug} && print "md5sum matches, stored and fine, next; \n";
			next; 
		}
		elsif ($hr_res->{check_md5sum} && $md5sum ne $hr_res->{check_md5sum}) {
			$Opt{debug} && print "WARNING md5sum does not match, next; \n";
			next; 
		}
		#checksum and id must always be in the report tables
		$h->{check_md5sum} = $md5sum; 
		$h->{workflow_queue_id} = $w->workflow_queue_id;
		$h->{status_id} = $hr_status2id->{in_queue_qc}; 
		$h->{create_date} = `date "+%Y-%m-%d %H:%M:%S"`;
		my $table = $wf->workflow_name; 
		#this is to make sure we don't try to insert values that there
		# are no columns for, making it generic too.
		
		my %temp;
		foreach my $c (@columns){
			if ($h->{$c}){
				$temp{$c} = $h->{$c}; 
			}
		}
		if (insert_hash($table, \%temp)){
			print "inserted data \n"; 
		}
		else {
		
		
		}
	}
	elsif ($hr_res->{check_md5sum}) {
		print "PROBLEM! file removed???!\n"; 
	}
	else {
		print "cannot find report for ". $w->output_dir . "; failed ?\n"; 
	}
}

sub parse_report {
    my $f = shift;
    open(FH, $f) || die $!; 
    my @header ; 
	my %hash; 
	my $l=0;
    while (<FH>){ 
        chomp; 
        next if /^$/; 
        next if /^#/; 
		if ($l==0){
			@header = split /\t/, $_; 
			$l++;
			next; 
        }
        if (!@header){
            print "$f : report header not present!\n"; 
            last;
        }
        my @line = split /\t/, $_; 
		#skip empty columns, NA and None
        for (my $i = 0; $i < scalar @header ; $i++){
            next unless $line[$i]; 
            if ($line[$i] eq 'NA' || $line[$i] eq 'None'){
                next; 
            }
            $hash{$header[$i]} = $line[$i]; 
        }
    	last; #only one line of stats 
    }
    close FH;
    return \%hash; 
}

sub insert_hash {
    my ($table, $field_values) = @_;
    # sort to keep field order, and thus sql, stable for prepare_cached
    my @fields = sort keys %$field_values;
    my @values = @{$field_values}{@fields};
    my $sql = sprintf "insert into %s (%s) values (%s)",
        $table, join(",", @fields), join(",", ("?")x@fields);
    my $sth = $dbh->prepare_cached($sql);
    return $sth->execute(@values);
  }


sub process_commandline { 	    
    my $yaml = YAML::Tiny->read( "$Bin/../config.yaml" )|| die "cannot read config.yaml";
    %Opt  = %{$yaml->[0]}; 
	GetOptions(
		\%Opt, qw(
        debug
		verbose
        version
        debug
        dryrun
	     now
        help
		  )
	) || pod2usage(0);
	if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
	if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
	if ( $Opt{version} ) { die $1, q$Revision:  $, "\n"; }
    if (!$Opt{now}) {pod2usage()} ; 
}

1; 

__END__
 
 
 
=head1 NAME

import_workflow_queue_report.pl 
import the workflow output in the corresponding workflow table
=head1 SYNOPSIS


import_workflow_config.pl -now [-dryrun] [-workflow file.yaml] 

i.e.

cat workflow_configs/casava_bcl_to_gvcf_workflow.yaml
---
workflow_name: casava_bcl_to_gvcf_workflow
workflow_version: v1
driver_location: /home/sajay/src/illumina/scripts/analysis_wrapper/wrapper.sh
sge_min_parameters: "qsub -cwd -V -pe threaded 12 -q prod-s.q -notify -b y "





=cut


1; 
