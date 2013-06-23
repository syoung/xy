#! /usr/bin/perl 

=pod


=head1 NAME

archive_builds.pl

=head1 SYNOPSIS

archive_runs.pl -now [-dryrun]

# Default behaivor
    find status_id=qc_passed from flowcell_lane_qc
    unless flowcell_lane_qc.archive_status_id set to 'lane_archive_skip'
    kick off backup job using template
# Backup job tar's the script


=cut

use strict; 
use warnings; 
use FindBin qw($Bin);
our $saffron_lib;
BEGIN {
    $saffron_lib = "$Bin/../lib";
}
use lib "$saffron_lib";
use Data::Dumper; 
use File::Basename;
use Getopt::Long;
use Pod::Usage; 
use Log::Log4perl qw(:easy);
use File::Spec::Functions ':ALL';
use Illumina::WGS::BuildQueue;
use Illumina::WGS::Sample;
use Illumina::WGS::SampleSheet;
use Illumina::WGS::Status;
use YAML::Tiny;
use HTML::Template;
our %Opt; 
&process_commandline(); 

my $archive_bin = "$Bin/archive_runner.pl";
my $sge_queue = $Opt{sge_queue};

my $sge_command = "qsub -b y -q $sge_queue";

# Check to see if the tmp and dest folders are there
my $lane_archiving_tmp = $Opt{archive_pending};
my $lane_archive_dest = $Opt{lane_archive_dest};
if (not -d $lane_archiving_tmp) {
    die "Unable to reach archving directories: $lane_archiving_tmp or $lane_archive_dest";
}

# Get the status_id's
my $hr_status2id = Illumina::WGS::Status->hasref_status2id;
my $hr_id2status = Illumina::WGS::Status->hashref_id2status;
  
# If it's a dry run... just bail!
if ($Opt{dryrun}){
    print "DRY RUN\n";
    exit;
}

# To get a status_id use
#$hr_status2id->{lane_archive_skip};

my $flowcell_lane_qc_id_status_update = <<END;
UPDATE
    flowcell_lane_qc
SET
    archive_status_id=?,
    archive_file_name=?,
    comments=?
WHERE
    flowcell_lane_qc_id = ?
END


my $qc_pass_sql = <<END;
SELECT 
    *
FROM
    flowcell_lane_qc AS fqc
    LEFT JOIN
    (flowcell AS f, status AS s) ON (fqc.flowcell_id = f.flowcell_id
        AND fqc.status_id = s.status_id )
    WHERE status = 'lane_qc_pass' AND fqc.archive_status_id IS NULL
END

my $dbh= Illumina::WGS::Sample->db_Main;
my $sth = $dbh->prepare($qc_pass_sql);
$sth->execute() or die "Unable to execute query $qc_pass_sql : $! \n";
my @lane_qc_query_results = Illumina::WGS::Sample->sth_to_objects($sth);

foreach my $lane_qc_row ( @lane_qc_query_results ) 
{
    print Dumper($lane_qc_row), "\n|\n";

    # Check to make sure everything is ok..
    my $location = $lane_qc_row->{location};
    my $lane = $lane_qc_row->{lane};
    my $flowcell_id = $lane_qc_row->{flowcell_id};
    my $flowcell_lane_qc_id = $lane_qc_row->{flowcell_lane_qc_id};
    if( not defined $location ) { print STDERR "Error: Unable to find location for entry ", Dumper($$lane_qc_row),"\n"; next; }
    if( not defined $lane ) { print STDERR "Error: Unable to find lane for entry ", Dumper($$lane_qc_row),"\n"; next; }
    if( not defined $flowcell_id ) { print STDERR "Error: Unable to find flowcell_id for entry ", Dumper($$lane_qc_row),"\n"; next; }
    if( not defined $flowcell_lane_qc_id ) { print STDERR "Error: Unable to find flowcell_lane_qc_id for entry ", Dumper($$lane_qc_row),"\n"; next; }

    # Make the template
    my $archive_cmd = prep_archive_cmd($location, $lane, $flowcell_lane_qc_id);
    print "Archive command: $archive_cmd\n";
    my $archive_qsub = "$sge_command $archive_cmd\n";
    print "QSub Archive command: $archive_qsub\n";
    #exit;

}

#---- Subroutines ---- 

## prep_archive_cmd
sub prep_archive_cmd {
    my $run_folder = shift;
    my $lane = shift;
    my $flowcell_lane_qc_id = shift;

    my $saffron_bin = $Bin;
    my $lane_archive_tmp = $Opt{lane_archive}{tmp};
    my $lane_archive_dest = $Opt{lane_archive}{dest};

    # Figure out where to write the template out to
    my $run_fodler_base = basename($run_folder);
    my $run_folder_base_clean = clean_run_folder($run_folder);

    # This contains the name of the final tar file. basename
    my $dest_archive_file = $run_folder_base_clean . '.tar';

    # This contains the name of the perl script we're generating
    if( not -f "$archive_bin" ) {
        die "Warning!: archive script $archive_bin doesn't exist\n";
    }

    my $archive_cmd = "perl $archive_bin --run_folder=$run_folder --flowcell_lane_qc_id=$flowcell_lane_qc_id --lane=$lane --archive_tmp_dir=$lane_archive_tmp --archive_dest_dir=$lane_archive_dest";

    return $archive_cmd;
}

##
sub clean_run_folder {
    my $run_folder = shift;
    my $run_folder_base = basename($run_folder);
    my $run_folder_base_clean = $run_folder_base;

    $run_folder_base_clean =~ s/[^a-zA-Z0-9\_\-]*//g;
    if($run_folder_base_clean =~ /(.*?_.*?_.*?_.*?)_.*/) {
        $run_folder_base_clean = $1;
    }
    return $run_folder_base_clean;
}


##
sub process_commandline {
     
    my $yaml = YAML::Tiny->read( "$Bin/../config.yaml" )|| die "cannot read config.yaml";
    %Opt = %{$yaml->[0]}; 
    $Opt{status} = 'building'; 
    GetOptions( \%Opt, 
            qw(
                debug
                now
                dryrun
                help
                force
                verbose
            )
        ) || pod2usage(0);
    if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
    if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
    #if ( !$Opt{now}) { pod2usage( ); }
}


1; 
