#! /usr/bin/perl 
use strict; 
use Data::Dumper; 
use FindBin qw($Bin); 
use lib "$Bin/../lib";
use lib "$Bin/../extlib/lib/perl5";
use warnings;
use Getopt::Long;
use Pod::Usage; 
use Illumina::WGS::Harddisk;
use Illumina::WGS::HarddiskSample;
use Illumina::WGS::Status; 
use YAML::Tiny;
our %Opt;
process_commandline();



#this caches the statuses from the database
my $hr_status2id = Illumina::WGS::Status->hasref_status2id;
my $hr_id2status = Illumina::WGS::Status->hashref_id2status;



my @hds = Illumina::WGS::Harddisk->retrieve_all(); 

print Dumper \@hds; 
### example!!! 
my %hd1 = (
    serial_number => 'bkasdjfksad', 
    mount_point => '/mnt/volume1', 
    max_usable_size_GB => 1800, 
    diskloader_ip => '10.10.10.10', 
    status_id => 8
);             

#my $hd = Illumina::WGS::Harddisk->create(%hd1); 


my $hd = Illumina::WGS::Harddisk->find_or_create(%hd1); 

my $dbh = Illumina::WGS::Harddisk->db_Main;

my $q = 'select count(*) from harddisk'; 

my $sth= $dbh->prepare($q);
$sth->execute;

my $d  =  $sth->fetchrow_hashref; 


print Dumper $d; 

exit; 

my @hds2 = Illumina::WGS::Harddisk->retrieve_all();

print Dumper \@hds2; 

$hds2[0]->delete; 

my @hds3 = Illumina::WGS::Harddisk->retrieve_all();

print Dumper \@hds3; 



sub process_commandline {
    my $yaml = YAML::Tiny->read( "$Bin/../config.yaml" )
        || die "cannot read config.yaml";
        
    %Opt = (
    );     
	GetOptions(
		\%Opt, qw(
        debug
        manual
        version
        
        help
		  )
	) || pod2usage(0);
	if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
	if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
	if ( $Opt{version} ) { die "fetch_samplesheet.pl, ", q$Revision:  $, "\n"; } 
   # !$ARGV[0] && pod2usage(); 
}



1; 

=head1 NAME

fetch_sample_config.pl - fetches a samplesheet for a given flowcell barcode 


=head1 SYNOPSIS


fetch_sample_config.pl FLOWCELL_BARCODE

fetches the samplesheet for a given barcode from the saffronDB 

=cut
__END__


Table harddisk

==============

serial_number    varchar(100)

mount_point      varchar(245)

max_usuable_size_GB int(11)

diskloader_ip    varchar(45)

status_id        int(10)

project_id       varchar(45)

truecrypt_volume enum('Y','N')

filesystem       enum('NTFS','ext3')
