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
use Illumina::WGS::Sample;
use File::Spec::Functions ':ALL';
use YAML::Tiny; 
our %Opt; 


&process_commandline(); 

`dos2unix $Opt{gt_genders}`; 


open(FH, $Opt{gt_genders}) || die "cannot open ". $Opt{gt_genders}. "\n";
while(<FH>){
	chomp; 
	next if /^ID/;
	next if /^$/; 
	next if /^#/;
	my ( $barcode,$gt_gender, $gt_call_rate, $gt_p99_cr, $comments )  = split /\t/; 
	if ($gt_gender && $gt_gender !~ /Male|Female/){
		print "unknown gt gender $gt_gender for $barcode \n";
		next; 
	}
	
	#gt gender
	if ($gt_gender eq 'Male'){
		$gt_gender = 'M'; 
	}
	elsif ($gt_gender eq 'Female'){
		$gt_gender = 'F'; 
	}
	else {
		print "gt gender not defined : $barcode \n"; 
		$gt_gender= undef;
	}
	my @samples = Illumina::WGS::Sample->search(sample_barcode=> $barcode); 
	if ($gt_gender && @samples){
		my $s = $samples[0]; 
		if ($s->gt_gender && $s->gt_gender ne $gt_gender){
			print "PROBLEM: previous defined gt gender not the same as in this file ; " . $s->sample_barcode . " ". 
			$s->gt_gender   . " now " . $gt_gender  . "\n"; 
			next;
		}
		else {
			$s->gt_gender($gt_gender); 
			if ($comments && $comments !~ /^$/){
				$s->comment(($s->comment ? $s->comment : '') . "\n" . "NOTE:" . $comments);
			}
			if ($gt_call_rate){
				$s->gt_call_rate($gt_call_rate); 
			}
			else {
				$gt_call_rate = 'NA'; 
			}
			if ($gt_p99_cr){
				$s->gt_p99_cr($gt_p99_cr);
			}
			else {
				$gt_p99_cr = 'NA'; 
			}
			if (!$Opt{dryrun}){
				$s->update(); 
			}
			else {	
				print "OK: $barcode ,  $gt_gender , $gt_call_rate, $gt_p99_cr, $comments\n";  
				$s->discard_changes; 
			}
		}
	}
	else {	
		print "unknown sample $barcode ; next\n"; 
		next; 
	}
}
close FH; 
$Opt{dryrun} && print "DRY RUN\n"; 


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
		gt_genders=s
        now
        help
		  )
	) || pod2usage(0);
	if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
	if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
	if ( $Opt{version} ) { die "import_simple_manifest.pl, ", q$Revision:  $, "\n"; }
    if (!$Opt{now}) {pod2usage()} ; 
	if (!$Opt{gt_genders}) {pod2usage()}; 
}

1; 

__END__
 
 
 
=head1 NAME

import_gt_genders.pl 

=head1 SYNOPSIS

import_gt_genders.pl -now [-dryrun] -gt_genders GENDERS.txt

LP... Male


=cut


1; 
