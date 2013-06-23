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
use POSIX 'strftime'; 
use File::stat;
use Time::localtime;
use Date::Parse; 
our %Opt; 


&process_commandline(); 

`dos2unix $Opt{project_manifest}`; 

open(DH, $Opt{project_manifest}) || die "cannot open ". $Opt{project_manifest}; 
while(<DH>){
	chomp; 
	next if /^Project/; 
	my ($project_name, $build, $dbsnp, $npf) = split /\t/; 
	if (!$npf){
		print  "npf is not set for $project_name"; 
		next; 
	}
	elsif ($npf !~ /[YN]/){
		print  "unrecognized $npf for $project_name";
		next; 
	}
	if (!$build){
		print  "build not defined for $project_name" ;
		next; 
	}
	elsif ($build !~ /NCBI3[67]/){
		print  "unrecognized $build for $project_name";
		next; 
	}
	if (!$dbsnp){
		print  "dbsnp not defined for $project_name" ;
		next; 
	}
	elsif ($dbsnp !~ /129|131/){
		print  "unrecognized dbsnp $dbsnp for $project_name";
		next; 
	}
	
	my @proj = Illumina::WGS::Project->search(project_name => $project_name); 
	if (@proj){
		my $p = $proj[0]; 
		$p->build_version($build); 
		$p->dbsnp_version($dbsnp); 
		$p->include_NPF($npf); 
		if (!$Opt{dryrun}){
			$p->update(); 
		}
		else {
			print STDERR "dry run"; 
		}
	}
	else {
		my %h = (
			project_name => $project_name, 
			build_version => $build, 
			dbsnp_version => $dbsnp,
			include_NPF => $npf , 
			status_id => 63
		); 
		if (!$Opt{dryrun}){
			my $sp = Illumina::WGS::Project->create(\%h); 
		}
		else {
			print Dumper \%h; 
		}
	}
}
close DH; 

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
		project_manifest=s
        now
        help
		  )
	) || pod2usage(0);
	if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
	if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
	if ( $Opt{version} ) { die "import_simple_manifest.pl, ", q$Revision:  $, "\n"; }
    if (!$Opt{now}) {pod2usage()} ; 
	if (!$Opt{project_manifest}){pod2usage()}; 
}

1; 

__END__
 
 
 
=head1 NAME

import_project.pl

import project limited set of columns

=head1 SYNOPSIS


import_project.pl -now [-dryrun] [-project_manifest FILE3.tsv]



=cut


1; 
