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
use Illumina::WGS::Status;
use Cwd 'abs_path';

our %Opt; 
process_commandline();
my $hashref_status2id = Illumina::WGS::Status->hasref_status2id;
my $hashref_id2status = Illumina::WGS::Status->hashref_id2status;

if (! defined $hashref_status2id->{$Opt{new_status}}){
	print "Status $Opt{new_status} is not known to the database\n"; 
	print Dumper $hashref_status2id; 
	exit; 
}	

open(FHZ, $ARGV[0]) || die "cannot open file : $!" ; 



my $date; 

if ($Opt{delivered_date}){
	$date = $Opt{delivered_date}; 
}
else {
	$date = `date "+%Y-%m-%d"`;
}


my %map; 
if ($Opt{mapping_file}){
    open(FH, $Opt{mapping_file})|| die $!; 
    while(<FH>){
        chomp; 
        next if /^$/;
        next if /^#/; 
        my ($current , $old) = split /\s+/; 
        $old =~ s/-CSS//; 
        $current =~ s/-CSS//; 
        $map{$old}=$current; 
    }
}
close FH; 


my @in; 
my @ok_samps; 
my @missing; 
my $flag=0; 
while (<FHZ>){
    chomp; 
    next if /^#/; 
    next if /^$/; 
    my @ar = split /\s+/;
    my $s = $ar[0]; 
    ### remapping the name if needed 
    if ($Opt{mapping_file} && $map{$s}){
        $s = $map{$s}; 
    }
    my @obj = Illumina::WGS::Sample->search(
       sample_barcode => $s
    );
    if (scalar @obj ==1 ){
        push @ok_samps, $obj[0]; 
		print $obj[0]->sample_barcode . " current : ". 
		$hashref_id2status->{$obj[0]->status_id} . " new : "  . $Opt{new_status} . "\n"; 
    }
    else {
        $flag=1; 
        push @missing, $_; 
        print "unknown samples : $s\n"; 
    }
}



print "samples in $ARGV[0]:  " . (scalar @ok_samps). "\n"; 
    
if ($flag && !$Opt{force}){
    print "some samples were not found in the database ,cannot proceed without -force; \nStart unknown\n"; 
    print join("\n", @missing). "\nEnd unknown\n"; 
    exit; 
}

if ($Opt{dry}){
	print "date $date\n"; 
    print "will update the following samples to ". $Opt{new_status} . ":\n"; 
    foreach my $s (@ok_samps){
		$s->discard_changes; 
    } 
    print "DRY RUN!!!\n"; 
    exit; 
}


foreach my $s (@ok_samps){
    $s->status_id($hashref_status2id->{$Opt{new_status}}); 
	if ($Opt{new_status} eq 'delivered'){
		$s->delivered_date($date); 
	}
    $s->update();
}
print "update done\n"; 



sub process_commandline {
	GetOptions(
		\%Opt, qw(
		new_status=s
		mapping_file=s
		delivered_date=s
		debug
		manual
		version
		force
		dry
		help
		)
	)|| pod2usage(0); 
	if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
	if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
	if ( $Opt{version} ) { die "update_sample_status.pl, ", q$Revision:  $, "\n"; } 
    !$ARGV[0] && pod2usage();
	!$Opt{new_status} && pod2usage(); 
}


1; 

=head1 NAME

update_sample_status.pl - update sample table to a new status; parses the first 
columns of a tab delimeted file ONLY!!!!


=head1 SYNOPSIS

given a list of sample barcodes in a file update the sample to NEW STATUS

update_sample_status.pl FILE_SAMPLE_BARCODES.txt [-dry] [-force] -new_status delivered|loading_to_hd|loaded_to_hd 
	[-delivered_date "YYYY-MM-DD" ]
 
If a given sample is not in the database --force is required to update the other samples

=cut


