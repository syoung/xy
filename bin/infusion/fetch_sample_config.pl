#! /usr/bin/perl 
use strict; 
use FindBin qw($Bin); 
use lib "$Bin/../lib";
use lib "$Bin/../extlib/lib/perl5";
use Data::Dumper; 
use warnings;
use Getopt::Long;
use Pod::Usage; 
use Illumina::WGS::Sample; 
our %Opt; 

process_commandline(); 
 
print "# generated on:  " . `date`; 



my $q = qq!select  
            p.project_name, 
            s.sample_barcode, 
            s.sample_id, 
            s.sample_name, 
            s.gender, 
            s.gt_gender, 
            p.build_version, 
            p.dbsnp_version, 
            s.ethnicity, 
            s.tissue_source, 
            s.cancer, 
            s.comment
            from project p, sample s 
            where p.project_id = s.project_id
            AND s.sample_barcode  ='$ARGV[0]' 
!; 
        
        
my $dbh = Illumina::WGS::Sample->db_Main;
 
my $sth = $dbh->prepare($q); 
$sth->execute || die $!; 


my $r = $sth->fetchrow_hashref; 

=pod

samplebarcode=SS6004161
sampleid=467964
manifestgender=Male
sequencedgender=Male
arraygender=Male
assemblydirectory=`pwd`/Assembly
arraygenotypefile=`echo Genotyping/*.txt`
genome=ncbi37

=cut

#manifest
my $mgender = 'Undefined'; 
if ($r->{gender} eq 'M'){
    $mgender  = 'Male'; 
}
elsif ($r->{gender} eq 'F'){
    $mgender = 'Female'; 
}
#array
my $gt_gender = 'Undefined'; 
if ($r->{gt_gender} eq 'M'){
    $gt_gender  = 'Male'; 
}
elsif ($r->{gt_gender} eq 'F'){
    $gt_gender = 'Female'; 
}
#sequence gender will be available soon

print join("\n", 
'## compatibility - wgspipe ## ', 
'samplebarcode='.$r->{sample_barcode}, 
'sampleid="'. $r->{sample_name}.'"', 
'manifestgender='.$mgender, 
'arraygender='.$gt_gender, 
'sequencedgender='. $gt_gender, 
'genome='.(lc $r->{build_version}), 
'assemblydirectory=`pwd`/Assembly', 
'arraygenotypefile=`echo Genotyping/*.txt`'
). "\n" ; 
 

sub process_commandline {
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
	if ( $Opt{version} ) { die "fetch_sample_config.pl, ", q$Revision:  $, "\n"; } 
    !$ARGV[0] && pod2usage(0); 
}


1; 

=head1 NAME

fetch_sample_config.pl - fetches a config for a sample in the saffron db


=head1 SYNOPSIS

fetches a config for a sample in the saffron db

fetch_sample_config.pl SAMPLE_BARCODE


Manifest gender is the gender provided by the customer in the manifest. 
Sequenced gender and array gender are the same, from the genotyping track.  

=cut


