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
use Illumina::WGS::model;
use YAML::Tiny;

our %Opt;
process_commandline();

my $hr_status2id = Illumina::WGS::Status->hasref_status2id;
my $hr_id2status = Illumina::WGS::Status->hashref_id2status;

our ( $flowcell_lane_qc_id, $location, $lane );
my $date              = `date "+%Y-%m-%d-%H:%M"`;
print "Begin:$date";
## SQL Queries

my $q1 = qq!
  SELECT fqc.flowcell_lane_qc_id,f.location,fqc.lane FROM 
  flowcell_lane_qc fqc,flowcell f where 
  f.flowcell_id=fqc.flowcell_id and 
  fqc.fingerprint_status_id in ($hr_status2id->{'fingerprinting_queue'},$hr_status2id->{'fingerprinting_running'},$hr_status2id->{'fingerprinting_failed'})!;

my $q2 = qq!
    update flowcell_lane_qc set
    fingerprint_status_id=? where
    flowcell_lane_qc_id=? !;

my $q3 = qq!
   update flowcell_lane_qc 
   set status_id=? where
   flowcell_lane_qc_id=?!;

my $sge    = &cache_sge();
my $dbh    = Illumina::WGS::model->db_Main;
my $q1prep = $dbh->prepare($q1) || die $!;
$q1prep->execute() or die $DBI::errstr;
$q1prep->bind_columns( undef, \$flowcell_lane_qc_id, \$location, \$lane );
my $q2prep = $dbh->prepare($q2) || die $!;
my $q3prep = $dbh->prepare($q3) || die $!;

while ( $q1prep->fetch() ) {
 my $Return = complete( $location, $lane );

 if ( !$Opt{dry} ) {

  if ( $Return eq "RIGHT" ) {
   $q2prep->execute( $hr_status2id->{'fingerprinting_finished'},
    $flowcell_lane_qc_id )
     or die $DBI::errstr;
  }
  elsif ( $Return eq "WRONG" ) {
   $q2prep->execute( $hr_status2id->{'fingerprinting_finished'},
    $flowcell_lane_qc_id )
     or die $DBI::errstr;
   $q3prep->execute( $hr_status2id->{'lane_swap'}, $flowcell_lane_qc_id )
     or die $DBI::errstr;
  }
  elsif ( $Return eq "Running" ) {
   $q2prep->execute( $hr_status2id->{'fingerprinting_running'},
    $flowcell_lane_qc_id )
     or die $DBI::errstr;
  }
  elsif ( $Return eq "Queue" ) {
   $q2prep->execute( $hr_status2id->{'fingerprinting_queue'},
    $flowcell_lane_qc_id )
     or die $DBI::errstr;
  }
  elsif ( $Return eq "Failed" ) {
   $q2prep->execute( $hr_status2id->{'fingerprinting_failed'},
    $flowcell_lane_qc_id )
     or die $DBI::errstr;
  }
  elsif ( $Return eq "UnKnownError" ) {
   print
"Somthing has gone wrong for Location: $location\tLane: $lane\tResult: $Return\tLaneQcID: $flowcell_lane_qc_id\n";
   $q2prep->execute( $hr_status2id->{'fingerprinting_failed'},
    $flowcell_lane_qc_id )
     or die $DBI::errstr;
  }
  else { }
 }
 else {
  print
"Location: $location\tLane: $lane\tResult: $Return\tLaneQcID: $flowcell_lane_qc_id\n";
 }

}

sub complete {
 my $location = $_[0];
 my $lane     = $_[1];
 my ( $ran, $done, $inSGE, $answer );
 my $failed  = "Failed";
 my $running = "Running";
 my $queue   = "Queue";
 my $Error   = "UnKnownError";

 # if ( -f "$location/Fingerprint/Done" ) {
 
 if ( -f "$location/Fingerprint/concordance_analysis.lane_$lane.txt" ) {
  open( RESULT, "$location/Fingerprint/concordance_analysis.lane_$lane.txt" );
  my $output = <RESULT>;
  my $result = ( split( /\t/, $output ) )[1];
  chomp($result);
  if ( $result eq "RIGHT" || $result eq "WRONG" ) {
   return ($result);
  }
  else {
   return ($failed);
  }
 }

 elsif ( -d "$location/Fingerprint" ) {
  if ( $sge->{"$location/Fingerprint"} ) {
   return ($running);
  }
  else {
   return ($failed);
  }
 }
 elsif ( -d $location ) {
  return ($queue);
 }
 else {
  return ($Error);
 }

}

sub cache_sge {
 my $cmd = q!
for i in `qstat -u '*' | grep "fp"  | awk '{print \$1}'`
do
        qstat -j $i | grep sge_o_workd
done
!;
 my $w = `$cmd`;
 my @q = split /\n/, $w;
 my %all;
 foreach my $c (@q) {
  my ( $s, $p ) = split /\s+/, $c;
  $all{$p}++;
 }
 return \%all;
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

Monitor_FingerPrints.pl - update safforn about current status of Fingerprints.


=head1 SYNOPSIS

Running as cron it updates the staus of fingerprints: Running , in queue, failed or completed.
if completed it flags the lane as lane_swap, if determing by fingerprinting.

MonitorFingerPrints.pl -dry to run script without updating database.
=cut
