#! /usr/bin/perl

=pod


=head1 NAME

archive_runner.pl

=head1 SYNOPSIS

archive_runner.pl [-dryrun] --run_folder=/illumina/upload/services/120918_SN899_0216_BC17T1ACXX_23nMe_REHYB_2 --lane=6 --archive_tmp_dir=/illumina/archive/ussd-services-6month/archive/tmp --archive_dest_dir=/illumina/archive/ussd-services-6month/archive/ready

Script runs a tar job that compresses one lane of a run folder into a tarball for the archive system.


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
use Illumina::WGS::FlowcellLaneQC;
use Illumina::WGS::Sample;
use Illumina::WGS::SampleSheet;
use Illumina::WGS::Status;
use YAML::Tiny;
use JSON;
use POSIX qw/strftime/;
use HTML::Template;
our %Opt;
&process_commandline();

# This will make the entire pipeline of a system command fail if any memeber fails -- very important
$ENV{SHELL} = '/bin/bash -o pipefail';

# Get the status_id's
my $hr_status2id = Illumina::WGS::Status->hasref_status2id;
my $hr_id2status = Illumina::WGS::Status->hashref_id2status;

my $run_folder = $Opt{run_folder};
my $lane = $Opt{lane};

my $lane_archive_tmp_dir = $Opt{archive_tmp_dir};
my $lane_archive_dest_dir = $Opt{archive_dest_dir};

my $run_folder_base = basename($run_folder);
my $run_folder_dir_trunk = dirname($run_folder);
my $run_folder_base_clean = clean_run_folder($run_folder);
my $dest_archive_file = $run_folder_base_clean . "_LANE$lane" . ".tar";

my $temp_archive_file_fullpath = $lane_archive_tmp_dir . "/" . $dest_archive_file;
my $dest_archive_file_fullpath = $lane_archive_dest_dir . "/" . $dest_archive_file;
my $md5sum_fullpath = "$temp_archive_file_fullpath" . ".md5sum";
my $meta_fullpath = "$dest_archive_file_fullpath" . '.META';

my $exclude_base = "--exclude='*.cif' --exclude='**Thumbnail_Images**' --exclude='**Aligned**' --exclude='**Unaligned**' --exclude='*.tif' --exclude='*.tiff' --exclude='*.qseq.txt*' --exclude='**GERALD**' --exclude='**Logs**'";

my $lane_list = '12345678';
if( not $Opt{test} ) {
    $lane_list =~ s/$lane//g;
}

my $lane_excludes = '';
foreach my $excluded_lane ( split('',$lane_list) ) {
    $lane_excludes = $lane_excludes . "--exclude='**L00$excluded_lane**' ";
}

my $full_exclude = "$lane_excludes $exclude_base";
my $tar_cmd = "tar $full_exclude  -cf - '$run_folder_base'";
my $tar_tee_cmd = "tee '$temp_archive_file_fullpath'";
my $md5sum_cmd = "md5sum > '$md5sum_fullpath'";

# Some sql for further down...
my $flowcell_lane_qc_id_return = <<END;
SELECT
    *
FROM
    flowcell_lane_qc AS fqc
    LEFT JOIN
    (flowcell AS f, status AS s) ON (fqc.flowcell_id = f.flowcell_id
        AND fqc.status_id = s.status_id )
    WHERE flowcell_lane_qc_id = ?
END

# Change directory to the directory below the run folder
chdir($run_folder_dir_trunk) or die "$!";

# These are the pipe commands used for the process.
my $full_cmd = "$tar_cmd | $tar_tee_cmd | $md5sum_cmd";
my $mv_cmd = "mv -v $temp_archive_file_fullpath $dest_archive_file_fullpath";

my $flowcell_lane_qc_id = '';
my $flowcell_lane_qc_details = '';
my $flowcell_lane_comments = '';
my $dbh = '';
my $fc_update_sth = '';
my $fcid_sth = '';

if( $Opt{flowcell_lane_qc_id} ) {
    $dbh = Illumina::WGS::Sample->db_Main;
    $fc_update_sth = $dbh->prepare($flowcell_lane_qc_id_status_update);
    $fcid_sth = $dbh->prepare($flowcell_lane_qc_id_return);

    $flowcell_lane_qc_id = $Opt{flowcell_lane_qc_id};
    print "Retrieving details for flowcell_lane_qc_id: $flowcell_lane_qc_id\n";
    $fcid_sth->execute($flowcell_lane_qc_id) or die "Unable to get query for fc id for $flowcell_lane_qc_id BAILING!\n";
    my @fcid_query_results = Illumina::WGS::Sample->sth_to_objects($fcid_sth);
    $flowcell_lane_qc_details = shift @fcid_query_results;
    #print Dumper($flowcell_lane_qc_details);
    $flowcell_lane_comments = $flowcell_lane_qc_details->{comments};
}

# Check to see if the lane has been deleted... update the status if it has..
my $flowcell_lane_dir = $run_folder . "/Data/Intensities/BaseCalls/L00" . $lane;
if( not -d "$flowcell_lane_dir" ) {
    my $error_comment = "archive_lane error: Flowcell bcl folder $flowcell_lane_dir doesn't exist!";
    if( $Opt{flowcell_lane_qc_id} ) {
        my $status_id = $hr_status2id->{'lane_archive_error'};
        Illumina::WGS::FlowcellLaneQC->update_flowcell_lane_qc_status($flowcell_lane_qc_id, $status_id, '', $flowcell_lane_comments, $error_comment );
    }
    die "$error_comment\n";
}

# Run the Tar pipe command
print "Running tar: $full_cmd\n";
my $tar_return_code = '';
unless( $Opt{dryrun} ) {
    # Update database
    if( $Opt{flowcell_lane_qc_id} ) {
        my $running_status_id = $hr_status2id->{'lane_archive_running'};
        my $running_comment = sprintf("archive_lane_running: date=%s", get_datetime_str() );
        Illumina::WGS::FlowcellLaneQC->update_flowcell_lane_qc_status($flowcell_lane_qc_id, $running_status_id, '', $flowcell_lane_comments, $running_comment );
    }    
    $tar_return_code = system($full_cmd);
    print "Tar returned: $tar_return_code\n";
}

# Check for tar errors!
if( $tar_return_code ) { 
    my $error_comment = "archive_lane error: Tar command $full_cmd returned with non-0 exit status!";
    if( $Opt{flowcell_lane_qc_id} ) {
        my $status_id = $hr_status2id->{'lane_archive_error'};
        Illumina::WGS::FlowcellLaneQC->update_flowcell_lane_qc_status($flowcell_lane_qc_id, $status_id, '', $flowcell_lane_comments, $error_comment );
    }
    die "$error_comment\n";
}

# Move the temporary archive.
print "Running mv: $mv_cmd\n";
my $mv_return_code = '';
unless( $Opt{dryrun} ) {
    $mv_return_code = system($mv_cmd);
    print "mv returned: $mv_return_code\n";
}

# Check for mv errors... probably rare but what the hell
if( $mv_return_code ) {
    my $error_comment = "archive_lane error: mv command $mv_cmd returned with non-0 exit status!";
    if( $Opt{flowcell_lane_qc_id} ) {
        my $status_id = $hr_status2id->{'lane_archive_error'};
        Illumina::WGS::FlowcellLaneQC->update_flowcell_lane_qc_status($flowcell_lane_qc_id, $status_id, '', $flowcell_lane_comments, $error_comment );
    }
    die "$error_comment\n";
}

# If you get here. All went well :)
if( $Opt{flowcell_lane_qc_id} ) {
    my $success_comment = sprintf("archive_lane_success: date=%s", get_datetime_str() );
    my $status_id = $hr_status2id->{'lane_archive_complete'};
    Illumina::WGS::FlowcellLaneQC->update_flowcell_lane_qc_status($flowcell_lane_qc_id, $status_id, $dest_archive_file, $flowcell_lane_comments, $success_comment );
}

my $md5sum = '';

unless( $Opt{dryrun} ) {
    $md5sum = read_md5sum($md5sum_fullpath);
    print "Found md5sum $md5sum\n";
    # Clean up md5sum
    print "Cleaning up md5sum file\n";
    unlink($md5sum_fullpath);

    if( $md5sum ) {
        my %md5sum_hash = ( 'md5' => $md5sum );
        print "Outputting META to to $meta_fullpath\n";
        open(META_OUT, '>', $meta_fullpath) or die "Unable to open META file: $meta_fullpath\n";
        my $json = encode_json \%md5sum_hash;
        print META_OUT "data=$json\n";
        close(META_OUT);
    }
}

#---- Subroutines ----


##
sub get_datetime_str {
    return ( strftime "%m/%d/%Y %H:%M", localtime );
}

## 
sub read_md5sum {
    my $md5sum_file = shift;
    my $md5sum = '';
    open(MD5SUM, '<', $md5sum_file) or die "Error: unable to open md5sum file $md5sum_file\n";
    my $md5sum_line = <MD5SUM>;
    chomp($md5sum_line);
    if($md5sum_line =~ /(\S+)\s/) {
        $md5sum = $1;
    }
    close(MD5SUM);
    return $md5sum;
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
                run_folder=s
                lane=s
                flowcell_lane_qc_id=s
                archive_dest_dir=s
                archive_tmp_dir=s
                no_update
                test
                help
                force
                verbose
            )
        ) || pod2usage(0);
    if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
    if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }

    if ( not $Opt{run_folder} or not -d $Opt{run_folder} ) { 
        print STDERR "Error: Please specify a valid run_folder\n";
        pod2usage( );
    }
    if ( not $Opt{lane} ) {
        print STDERR "Error: Please specify a valid lane\n";
        pod2usage( );
    }
    if ( not $Opt{archive_dest_dir} or not -d $Opt{archive_dest_dir} ) {
        print STDERR "Error: Please specify a valid archive_dest_dir\n";
        pod2usage( );
    }
    if ( not $Opt{archive_tmp_dir} or not -d $Opt{archive_tmp_dir} ) {
        print STDERR "Error: Please specify a valid archive_tmp_dir\n";
        pod2usage( );
    }

    #if ( !$Opt{now}) { pod2usage( ); }
}



