#! /usr/bin/perl
use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/../extlib/lib/perl5";
use Data::Dumper;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Illumina::WGS::model;
use Illumina::WGS::Status;
use List::MoreUtils qw(uniq);
use Cwd 'abs_path';

our %Opt;

process_commandline();

my $hashref_status2id = Illumina::WGS::Status->hasref_status2id;
my $hashref_id2status = Illumina::WGS::Status->hashref_id2status;
my $date              = `date "+%Y-%m-%d-%H:%M"`;
my ( $flowcell_location, $flowcell_id );

## Get Builds which are Qc_failed and have GT concordance less than 0.98

my $GTConc_cutoff = 0.98;
print "Begin:$date";
## SQL QUERIES

my $q1 = qq!
		select f.location,f.flowcell_id 
		from flowcell f , flowcell_lane_qc q , 
		build_report b , 
		sample s, 
		project p, 
		flowcell_samplesheet fs 
		where 
		s.sample_id  = b.sample_id and 
		p.project_id = s.project_id and 
		f.flowcell_id = q.flowcell_id and 
		fs.flowcell_id = q.flowcell_id and 
		fs.lane = q.lane and
		b.sample_id = s.sample_id and 
		s.sample_id = fs.sample_id and 
		b.gt_gen_concordance < 0.98 and 
		s.status_id = $hashref_status2id->{"qc_fail"}
		group by flowcell_id!;

my $q2 = qq!
		Update flowcell_lane_qc 
		set fingerprint_status_id=$hashref_status2id->{'fingerprinting_queue'}  
		where flowcell_id=? 
		and status_id=$hashref_status2id->{'lane_qc_pass'}
		and fingerprint_status_id is null!;

## Fetch FlowCell ID to mark for fingerprinting
my $dbh = Illumina::WGS::model->db_Main;
my $q1prep = $dbh->prepare($q1) || die $DBI::errstr;
$q1prep->execute() || die $!;
$q1prep->bind_columns( undef, \$flowcell_location, \$flowcell_id );
my $q2prep = $dbh->prepare($q2) || die $DBI::errstr;

if ( !$Opt{dry} ) {
 while ( $q1prep->fetch() ) {
  $q2prep->execute($flowcell_id) or die $DBI::errstr;

   print "$flowcell_location\n";
  if ( -d "$flowcell_location/Logs" ) {
   if (! -f "$flowcell_location/Logs/FINGERPRINT.txt"){
   open( TOUCH, ">$flowcell_location/Logs/FINGERPRINT.txt" ) or die $!;
   print TOUCH "";
   close(TOUCH);
  }}

  else {
   print "Flowcell doesnt Exist or cant be written into: $flowcell_location\n";
  }
 }

}
else {

 print "Following Flowcell need FingerPrinting\n";
 while ( $q1prep->fetch() ) {
  print "$flowcell_id\t$flowcell_location\n";
 }

}

sub process_commandline {
 GetOptions(
  \%Opt, qw(
    dry
    help
    )
 ) || pod2usage(0);
 if ( $Opt{help} ) { pod2usage( verbose => $Opt{help} - 1 ); }
}

=head1 NAME

FingerPrintOnQcFail.pl - update flowcell laneQc table with mark for running Fingerprint on that flowcell.


=head1 SYNOPSIS

Running as cron every hour to mark all flowcell from Qc_fail samples for running fingerprinting.

=cut

