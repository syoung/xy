#! /usr/bin/perl 
use strict;
use Data::Dumper;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin qw($Bin); 
use lib "$Bin/../lib";
use lib "$Bin/../extlib/lib/perl5";
use YAML::Tiny;
use File::Spec::Functions ':ALL';
use Illumina::WGS::SampleSheet;
use Illumina::WGS::Flowcell;
use Illumina::WGS::Sample;
use Illumina::WGS::RequeueReport; 
our %Opt;

process_commandline();
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

#input 
my @inputs;
my @do_warn; 
if (@ARGV) {
    @inputs = @ARGV;
}
else {  
	my $q = 'select f.* from flowcell f 
	left join flowcell_samplesheet fs on f.flowcell_id = fs.flowcell_id 
	where fs.flowcell_id is null'; 
	my $dbh = Illumina::WGS::Flowcell->db_Main; 
	my $sth = $dbh->prepare($q); 
	$sth->execute; 
	@inputs = Illumina::WGS::Flowcell->sth_to_objects($sth);
}

## if there is a mapping between barcodes
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
if ( !@inputs ) {
    $Opt{debug} && print "nothing to do\n";
	exit; 
}
my %fc_content; 
my %notok_flowcells; 
foreach my $flowcell (@inputs) {
	my $loc;
	my $ss; 
	if ($Opt{centralized_samplesheets}){
		$loc = $Opt{centralized_samplesheets}; 
		if (!-d $loc){
			print "cannot find $loc ; next \n"; 
			next; 
		}
		$ss = catfile( $loc, join("_", 
			$flowcell->flowcell_barcode , 'SampleSheet.csv' ));
		if (!-s $ss){
			print "cannot find $ss ; next \n"; 
			next; 
		}		
	}
	else {
		$loc = $flowcell->location; 
		my @dirs = split /\//, $loc; 
		my $storage = $Opt{$hostname}{$dirs[1]};
		if (!-d $loc){
			print "cannot find $storage $loc ; next \n"; 
			next; 
		}
		$ss = catfile( $loc, 'SampleSheet.csv' );
		if (!-s $ss){
			print "cannot find $ss ; next \n"; 
			next; 
		}
	}		
    my $md5sum = `md5sum $ss | awk '{print \$1}'`;
    chomp $md5sum;
	#process the file content
	## validate sample sheet against database. 
	## if any flowcell does not validate 
	## don't add the samplesheet
    open( FH, $ss ) || die "$ss:" . $!;
    my %samples;
	my $lanes = 0; 
	my $ok_lanes = 0 ; 
    LANE: while (<FH>) {      
		my $notok_lane=0; 
		chomp;
        next LANE if /^FCID/;
        next LANE if /^$/;
        my (
            $FCID,     $Lane, $SampleID, $SampleRef,
            $Index,    $Description, $Control,  $Recipe,
            $Operator, $SampleProject
        ) = split /,/;  
        #$Opt{debug} && print "debug: $_ \n"; 
		if ($Opt{mapping_file} && $map{$SampleID}){
            $SampleID = $map{$SampleID}; 
        }
		if ($FCID ne $flowcell->flowcell_barcode){
			$notok_flowcells{$flowcell->flowcell_id}++; 
			next LANE; 
		}
        my @samples =
              Illumina::WGS::Sample->search( sample_barcode => $SampleID );    
		if ( !@samples ) {
            $Opt{debug} && print "$ss: could not find sample $SampleID in database\n";
			$notok_flowcells{$flowcell->flowcell_id}++; 
			next LANE; 
		}
		#sample barcode is unique
        my $sample = $samples[0];
		#add UCT and DTP parsing here
		my %hash = (
            flowcell_id  => $flowcell->flowcell_id,
            sample_id    => $sample->sample_id,
            ref_sequence => $SampleRef,
            lane         => $Lane,
            control      => $Control,
            indexval     => $Index ? $Index : undef,
            md5sum       => $md5sum,
            location     => $ss
        );
		if ($fc_content{$flowcell->flowcell_id}){ 
			push @{$fc_content{$flowcell->flowcell_id}}, \%hash;
		}
		else {
			my @tmp_ar= \%hash; 
			$fc_content{$flowcell->flowcell_id} = \@tmp_ar;
		}
    }
}


#write to disk flowcell lanes marked to be written
my @to_write = Illumina::WGS::SampleSheet->search(status_id => 60); 
my %fc_lanes; 
foreach my $lane (@to_write){
	if ($fc_lanes{$lane->flowcell_id}){
		push @{$fc_lanes{$lane->flowcell_id}}, $lane; 
	}
	else {
		my @s = $lane; 
		$fc_lanes{$lane->flowcell_id} =\@s; 
	}
}
foreach my $fcid (keys %fc_lanes){
	my $fc = Illumina::WGS::Flowcell->retrieve($fcid);
	my $ss_string = $fc->samplesheet_string; 
	my $dir = $fc->location; 
	my $ssfile = catfile($dir, 'SampleSheet.csv');  
	if ($Opt{dryrun}){
		print "will write sample sheet to $ssfile\n"; 
		print $ss_string. "\n"; 
	}
	else {
		if(my $fh= open(FH , ">$ssfile")){					
			print FH $ss_string . "\n"; 
			foreach my $lane (@{$fc_lanes{$fcid}}){
				$lane->status_id(0); 
				$lane->update; 
			}
		}
		else {
			warn "cannot write to $ssfile; next; ";
			next;
		}	
	}
}
foreach my $fc (sort keys %fc_content) {
	if ($notok_flowcells{$fc}){
		print "skipping flowcell $fc , not ok\n"; 
		next; 
	}
	if ($Opt{dryrun}){
		print "going to create entry for "; 
		print Dumper $fc_content{$fc}; 
	}
	else {
		my @lanes  = @{$fc_content{$fc}}; 
		foreach my $l (@lanes){
			my $fci = Illumina::WGS::SampleSheet->create($l);
			$Opt{debug} && print $fci->location ." " . $fci->lane
			  . " inserted with id "
			  . $fci->flowcell_samplesheet_id . "\n";
		}
		print " inserted " . (scalar @lanes) . "\n"; 
	}
}


sub process_commandline {
    my $yaml = YAML::Tiny->read( "$Bin/../config.yaml" )|| die "cannot read config.yaml";
    %Opt  = %{$yaml->[0]}; 
    GetOptions(
        \%Opt, qw(
          debug
          dryrun
			mapping_file=s 
         runs_root=s
          manual
          version
          verbose
          now
          help
          )
    ) || pod2usage(0);
    if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
    if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
    if ( $Opt{version} ) { die "import_manifest.pl, ", q$Revision:  $, "\n"; }
}
1;


=head1 NAME

import_samplesheet.pl import flowcell_samplesheets

=head1 USAGE

import_flowcell_samplesheet.pl [path]

This script now does NOT try to hard. If it finds the flowcell great , it 
will not try to find it again. 


=cut


