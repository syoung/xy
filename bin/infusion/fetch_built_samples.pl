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
use Illumina::WGS::Status;
use Illumina::WGS::BuildReport;
use YAML::Tiny;
our %Opt;

process_commandline();


my $hr_status2id = Illumina::WGS::Status->hasref_status2id;
my $hr_id2status = Illumina::WGS::Status->hashref_id2status;

my $idstatus = $hr_status2id->{$Opt{sample_status}}; 
if (!$idstatus){
	print "Unknown Status : $Opt{sample_status} \n"; 
}

my $sql = qq! select s.* from sample s , project p 
			where s.project_id = p.project_id and s.status_id = $idstatus !; 

if ($Opt{sample_barcode}){
	$sql .= qq! and s.sample_barcode = '$Opt{sample_barcode} ' !; 
}
if ($Opt{project_name}){
	$sql .= qq! and p.project_name = '$Opt{project_name} ' !; 
}
my $dbh= Illumina::WGS::Sample->db_Main; 
my $sth = $dbh->prepare($sql); 
$sth->execute(); 


my @samples = Illumina::WGS::Sample->sth_to_objects($sth); 


my @header = Illumina::WGS::BuildReport->file_header(); 


unshift @header, 'sample', 'sample_status', 'target_fold_coverage', 'cancer'	; 
my $date = `date`; 
print "#$date"; 
print "#". join("\t", @header) . "\n"; 

foreach my $s (@samples){
	my @br = Illumina::WGS::BuildReport->search(sample_id => $s->sample_id); 
	print join("\t", $s->sample_barcode, 
		$hr_id2status->{$s->status_id},
		$s->target_fold_coverage, 
		$s->cancer, 
		$br[0]->to_string_extended) . "\n"; 
}



sub process_commandline {
    my $yaml = YAML::Tiny->read( "$Bin/../config.yaml" )
        || die "cannot read config.yaml";
        
    %Opt = (
		sample_status => 'qc_pass'
    );     
	GetOptions(
		\%Opt, qw(
        debug
		sample_status=s
		sample_barcode=s
		project_name=s
        version
		now
        help
		  )
	) || pod2usage(0);
	if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
	if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
	if ( $Opt{version} ) { die "fetch_samplesheet.pl, ", q$Revision:  $, "\n"; } 
    !$Opt{now} && pod2usage(0); 
}



1; 

=head1 NAME

fetch_built_sample.pl 

=head1 SYNOPSIS

fetch_built_sample.pl -now [-project_name PROJECT_NAME ] 
[-sample_barcode SAMPLE] [-sample_status qc_pass]

Fetches the sample build information for the appropriate query. 
sample status is by default qc_pass but can be overwritten

=cut


