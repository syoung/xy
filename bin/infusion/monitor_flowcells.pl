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
use Illumina::WGS::Flowcell;
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
print "running on $hostname \n"; 

my $hr_status2id = Illumina::WGS::Status->hasref_status2id;
my $hr_id2status = Illumina::WGS::Status->hashref_id2status;

my %search  = ( 
	status_id => $hr_status2id->{run_started}
);

my @started = Illumina::WGS::Flowcell->search(%search,);
$Opt{debug} && print "found "
  . ( scalar @started )
  . " flowcells in run_started status\n";
my @flowcells;
my $finished = 0;
my $started = scalar @started; 

foreach my $flowcell (@started) {
    my $path = $flowcell->location;
	if (!-d $path ){
		next; 
	}
	my $rta = catfile($path, 'RTAComplete.txt'); 
    $Opt{debug}
      && print $flowcell->flowcell_barcode . ' '
      . $hr_id2status->{ $flowcell->status_id }
      . ' set on '
      . $flowcell->update_timestamp." ### ";
    if ( -e $rta) {
        $Opt{debug} && print qq!run finished; updating status  \n!;
        $flowcell->status_id( $hr_status2id->{run_finished} );
        push @flowcells, $flowcell;
        $finished++; 
        next;
    }
    else {
        $Opt{debug} && print "did not find RTA finished \n"; 
	}
}

print "flowcells started $started ; finished $finished \n"; 

# check if all failed flowcells have a RUN_FAILED.txt file in the location
# the RUN_FAILED.txt will lead to it being moved to ../failed_runs
# if the folder does not exist, it is because it was already moved. 

my %searchfailed  = ( 
	status_id => $hr_status2id->{run_failed},
	server => $hostname
);

my @fcs_failed  = Illumina::WGS::Flowcell->search(%searchfailed); 
my @mark_failed; 
foreach my $f (@fcs_failed){
	if (!-d $f->location){
		#$Opt{debug} && print $f->location . "does not exist anymore ; next; \n"; 
	}
	elsif (-e catfile($f->location, 'RUN_FAILED.txt')) {
		$Opt{debug} && print catfile($f->location, 'RUN_FAILED.txt') . " already exists; next; \n"; 
	}
	else {
		push @mark_failed, $f; 
	}
}
my $mf = scalar @mark_failed; 
my $f_failed = scalar @fcs_failed; 
print "failed flowcell $f_failed ;  marked failed in this run $mf\n"; 

## DRY RUN 
if ($Opt{dryrun}){
	foreach my $fc_failed (@mark_failed){
		print "will mark as failed : ". $fc_failed->location . "\n"; 
	}
	foreach my $fc (@flowcells){
		print "will mark as finished: ". $fc->location ."\n";
		$fc->discard_changes; 
	}
    print "!!!!! DRY RUN!!!!";
    exit; 
}

## finished , mark finished 
foreach my $fc (@flowcells) {
    $fc->update();
	print $fc->flowcell_barcode
      . qq! update to !
      . $hr_id2status->{$fc->status_id} . "\n";
}

#failed , mark failed 
foreach my $fc_marked (@mark_failed){
	my $loc = catfile($fc_marked->location, 'RUN_FAILED.txt');  
	open (FH, ">>$loc") || warn "cannot open $loc to write "; 
	my $update = $fc_marked->update_timestamp ?  $fc_marked->update_timestamp : 'NA'; 
	my $by = $fc_marked->user_code_and_ip ? $fc_marked->user_code_and_ip : 'NA'; 
	my $fail = $fc_marked->fail_code_id ? $hr_id2status->{$fc_marked->fail_code_id} : 'NA'; 
	my $comments = $fc_marked->comments ? $fc_marked->comments : 'NA'; 
	my $rehyb = $fc_marked->attempting_rehyb ? $fc_marked->attempting_rehyb : 'N'; 
	print FH "date_failed: $update\n"; 
	print FH "failed_by: $by\n"; 
	print FH "reason: $fail\n"; 
	print FH "comments: $comments\n"; 
	print FH "rehyb: $rehyb\n"; 
	close FH; 
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

monitor_flowcells.pl 

=head1 SYNOPSIS

monitor_flowcells.pl  -now

Monitors flowcells that are in “run_started”. Right now it just tries to find 
the path for all the flowcell in all servers. If the path exists it looks for 
the  ‘RTAComplete.txt’ flag and if present it marks the flowcell as “run_finished”. 
It also queries the database for flowcells in “run_failed” status and created 
a file in them called “RUN_FAILED.txt” with the reasons for the failure. 
This gets picked up by an independent clean up script and monitored by the LCM team. 


=cut

