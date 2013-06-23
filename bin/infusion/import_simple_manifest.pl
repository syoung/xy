#! /usr/bin/perl 
use strict; 
use warnings; 
use FindBin qw($Bin); 
use lib "$Bin/../lib";
use lib "$Bin/../extlib/lib/perl5";
use Data::Dumper; 
use Getopt::Long;
use Pod::Usage; 
use Illumina::WGS::Project;
use Illumina::WGS::Workflow; 
use Illumina::WGS::Sample;
use Illumina::WGS::SampleWorkflow;
use File::Spec::Functions ':ALL';
use YAML::Tiny;
use POSIX 'strftime'; 
use File::stat;
use Time::localtime;
use Date::Parse; 
our %Opt; 


&process_commandline(); 


`dos2unix $Opt{sample_manifest}`; 

my %an_temp; 
open(FH, $Opt{sample_manifest}) || die "cannot open ". $Opt{sample_manifest}. "\n";
SAMPLE: while(<FH>){
	chomp; 
	next if /^Project/;
	my ($project_name, $barcode, $fold_cov, $gt_gender , $analysis, $sex)  = split /\t/; 
	my @project = Illumina::WGS::Project->search(project_name=> $project_name); 
	if (!@project){
		print  "$project_name not known\n"; 
		next; 
	}
	my @analysis = split /;/, $analysis; 
	
	foreach my $an (@analysis){
		my ($analysisName , $analysisVer) = split /:/, $an; 
		my @workflow = Illumina::WGS::Workflow->search(
			workflow_name => $analysisName, 
			workflow_version => $analysisVer
		); 
		if (!@workflow){
			print "$analysisName version $analysisVer is unknown !\n"; 
			next SAMPLE;
		}
		$an_temp{$barcode} = $workflow[0]; 
	}
	if ($gt_gender && $gt_gender !~ /[FMU]/){
		print  "unknown gt gender $gt_gender for $barcode ";
		next; 
	}
	if ($sex && $sex !~ /[FMU]/){
		print  "unknown sex $sex for $barcode "; 
		next; 
	}
	if (!$fold_cov){
		print  "unknown fold coverage not defined $barcode "; 
		next; 
	}
	elsif ($fold_cov !~ /^\d+$/){
		print  "not in expected fold coverage format : $fold_cov $barcode"; 
		next; 
	}
	my %h = (
		project_id => $project[0]->project_id, 
		sample_barcode => $barcode , 
		target_fold_coverage => $fold_cov, 
		gt_gender => $gt_gender, 
		analysis => $analysis, 
		gender => $sex, 
		gt_gender => $gt_gender, 
		status_id => 63
	); 
		
	
		
	my @samples = Illumina::WGS::Sample->search(sample_barcode=> $barcode); 
	if (@samples){
		print "NOTE sample already exists, use force to update; analysis are not updated this way!!\n"; 
		my $s = $samples[0]; 
		$s->target_fold_coverage($fold_cov); 
		$s->gt_gender($gt_gender); 
		$s->gender($sex); 
		$s->analysis($analysis); 
		if (!$Opt{dryrun} && $Opt{force}){
			$s->update(); 
		}
		else {
			print Dumper \%h; 
			print STDERR "dry run or you must use force\n"; 
		}
	}
	else {
		if (!$Opt{dryrun}){
			my $sp = Illumina::WGS::Sample->create(\%h); 
			if ($an_temp{$sp->sample_barcode}){
				my $wf = $an_temp{$sp->sample_barcode}; 
				my %ht = (
					sample_id => $sp->sample_id,  
					workflow_id => $wf->workflow_id
				); 				
				my $sw = Illumina::WGS::SampleWorkflow->create(\%ht); 
			}
			else {
				print "no workflow association for "  . $sp->sample_barcode . "\n"; 
			}
		}
		else {
			print Dumper \%h; 
		}	
	}
}
close FH; 


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
		sample_manifest=s
		force
        now
        help
		  )
	) || pod2usage(0);
	if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
	if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
	if ( $Opt{version} ) { die "import_simple_manifest.pl, ", q$Revision:  $, "\n"; }
    if (!$Opt{now}) {pod2usage()} ; 
	if (!$Opt{sample_manifest}) {pod2usage()}; 
}

1; 

__END__
 
 
 
=head1 NAME

import_simple_manifest.pl 

import sample manifest for a limited set of columns

=head1 SYNOPSIS


import_simple_manifest.pl -now [-dryrun] [-sample_manifest FILE.tsv] 

sample manifest should be configured in the master config.yaml

=cut


1; 
