#! /usr/bin/perl 
use strict; 
use warnings; 
use FindBin qw($Bin); 
use lib "$Bin/../lib";
use lib "$Bin/../extlib/lib/perl5";
use Data::Dumper; 
use Getopt::Long;
use Pod::Usage; 
use Illumina::WGS::Workflow;
use File::Spec::Functions ':ALL';
use YAML::Tiny;
use POSIX 'strftime'; 
use File::stat;
use Time::localtime;
use Date::Parse; 
our %Opt; 

&process_commandline(); 

my $yaml = YAML::Tiny->read( $Opt{workflow})|| die "cannot read ". $Opt{workflow};


my %config = %{$yaml->[0]}; 

my %thresholds = %{$config{report_thresholds}}; 

my $threshold_text = YAML::Tiny->Dump(\%thresholds); 

$config{report_thresholds} = $threshold_text; 


if (!$Opt{dryrun}){
	my $new = Illumina::WGS::Workflow->create(\%config); 
	print "created " . $new-> workflow_name . " ; version ". $new->workflow_version . "\n"; 
}
else {
	print Dumper \%config;
	print "dry run; will store config\n"; 
}





sub process_commandline { 
	GetOptions(
		\%Opt, qw(
        debug
		verbose
        version
        debug
        dryrun
		workflow=s
        now
        help
		  )
	) || pod2usage(0);
	if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
	if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
	if ( $Opt{version} ) { die "import_workflow.pl, ", q$Revision:  $, "\n"; }
    if (!$Opt{now}) {pod2usage()} ; 
	if (!$Opt{workflow}) {pod2usage()}; 
}

1; 

__END__
 
 
 
=head1 NAME

import_workflow_config.pl 

import an yaml file with the basic parameters to run the workflow

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
