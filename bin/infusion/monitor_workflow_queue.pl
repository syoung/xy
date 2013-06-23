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
use Illumina::WGS::Status; 
use Illumina::WGS::WorkflowQueue;
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

## I will have to check all compute servers for now for the ouput folder
# not perfect but should work as long as the output folder is pointing to /illumina
# only and not illumina2

my %q = (
	status_id => 15
); 
	
my @wfq = Illumina::WGS::WorkflowQueue->search(%q); 	

# the presence of the output folder is a sign that the workflow worked!


foreach my $w (@wfq){
	if ( -d $w->output_dir){
		print $w->output_dir . " found;  marking as done; "; 
		$w->status_id($hr_status2id->{build_finished});		
	}
	else {
		$Opt{debug} && print " not found " .  $w->output_dir . "\n";
	}
}


if (!$Opt{dryrun}){
	foreach my $w (@wfq){
		$w->update;
	}
}
else {
	foreach my $w (@wfq){
		$w->discard_changes;
	}
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

1;

 __END__
 
 
 
=head1 NAME

monitor_workflow_queue.pl

=head1 SYNOPSIS

monitor_workflow_queue.pl -now [-dryrun]

simply checks if the output dir in the output server exists and marks those as done. 

=cut
