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
use Illumina::WGS::Sample;
use YAML::Tiny;
our %Opt; 
&process_commandline(); 


my $hr_status2id = Illumina::WGS::Status->hasref_status2id;
my $hr_id2status = Illumina::WGS::Status->hashref_id2status;

my $q = qq! select * from sample s where s.status_id = 63 and  (genotype_report is null or gt_deliv_src is null)!; 
my $dbh = Illumina::WGS::Sample->db_Main;
my $sth = $dbh->prepare($q); 
$sth->execute; 
my @active_samples = Illumina::WGS::Sample->sth_to_objects($sth); 
my $dir = $Opt{genotype_source_dir}; 
my $gt_del_src = $Opt{gt_deliv_src}; 
my $gt_vcf = $Opt{gt_vcf}; 
my $changed=0;
foreach my $s (@active_samples){
	my $sname = $s->sample_barcode; 
	
	#gt report
	my @locs = glob "$dir/*$sname*";
	chomp @locs; 
	if (!@locs){
		$Opt{debug} && print "$sname genotype not yet available\n"; 
		next; 
	}
	elsif(scalar @locs > 1){
		print "odd that more than one file for $sname \n"; 
	}
	else {
		$Opt{debug} && print "found one gt for $sname\n" ;
		$s->genotype_report($locs[0]); 	
		$changed++;
	}	
	#idats
	my @locs_idats = glob "$gt_del_src/*$sname*";
	chomp @locs_idats; 
	if (!@locs_idats){
		$Opt{debug} && print "$sname genotype idats not yet available\n"; 
	}
	elsif(scalar @locs_idats > 1){
		print "odd that more than one idats for $sname \n"; 
	}
	else {
		$Opt{debug} && print "found one idats for $sname\n" ;
		$s->gt_deliv_src($locs_idats[0]); 
		$changed++;
	}
	#gvcf
	#idats
	my @locs_vcf = glob "$gt_vcf/*$sname*";
	chomp @locs_vcf; 
	if (!@locs_vcf){
		$Opt{debug} && print "$sname genotype vcf not yet available\n"; 
	}
	elsif(scalar @locs_idats > 1){
		print "odd that more than one vcf for $sname \n"; 
	}
	else {
		$Opt{debug} && print "found one vcf for $sname\n" ;
		$s->gt_vcf($locs_vcf[0]); 
		$changed++;
	}
}

if (!$Opt{dryrun}){
	if ($changed){
		foreach my $s (@active_samples){
			$s->update; 
		}
		print "updated $changed\n"; 
	}
	else {
		print "nothing to update \n"; 
	}
}
else {
	print "to updated: $changed \n"; 
	print "DRY RUN";
}

sub process_commandline {
    
    my $yaml = YAML::Tiny->read( "$Bin/../config.yaml" )|| die "cannot read config.yaml";
    %Opt  = %{$yaml->[0]}; 
  	GetOptions(
		\%Opt, qw(
        debug
        version
        dryrun
        verbose
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

monitor_samples.pl 

=head1 SYNOPSIS

monitor_samples.pl -now [-dryrun]

log can be found in ../log/monitor_samples.log

checks if gt reports are available and updates sample table with path

=cut


1; 
