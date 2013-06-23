#! /usr/bin/perl 
use strict; 
use FindBin qw($Bin); 
use lib "$Bin/../lib";
use lib "$Bin/../extlib/lib/perl5";
use Data::Dumper; 
use warnings;
use Getopt::Long;
use Pod::Usage; 
use Illumina::WGS::SampleSheet;
use Illumina::WGS::Sample;
use Illumina::WGS::Flowcell;
our %Opt;
process_commandline();

my @fc = Illumina::WGS::Flowcell->search(
    location => $ARGV[0]
); 

if (scalar @fc != 1){
    print " $ARGV[0] not known or too many\n"; 
    print Dumper \@fc; 
    exit; 
}

my $f = $fc[0]; 
my @fcs = Illumina::WGS::SampleSheet->search(flowcell_id => $f->flowcell_id); 

if (scalar @fcs !=8 ){
    print STDERR "NOTE probably there should be 8 lanes for this flowcell; be sure that is expected!!\n"; 
}

my @header =
      qw/FCID Lane SampleID SampleRef 
      Index Description Control Recipe 
      Operator SampleProject/;
print join(",", @header). "\n";       
      
      
foreach my $lane (sort {$a->lane <=> $b->lane} @fcs){
    my $sample = Illumina::WGS::Sample->retrieve($lane->sample_id); 
    my $project = Illumina::WGS::Project->retrieve($sample->project_id); 
    my $label='U'; 
    if ($sample->gt_gender){
        if ($sample->gt_gender eq 'M'){
            $label = 'XY'; 
        }
        else {
            $label = 'XX'; 
        }    
    }
    print join( ",",
            $f->flowcell_barcode,   
            $lane->lane,
            $sample->sample_barcode,  
            join("_", $sample->species.$project->build_version,$label) ,
            '',
            "TARGET_COV:".$sample->target_fold_coverage,
            'N',
            'NOREC',
            'NA',
            $project->project_name )."\n";
}


sub process_commandline {
    %Opt = (
    );     
	GetOptions(
		\%Opt, qw(
        debug
        manual
        version
        run_length=s
        help
		  )
	) || pod2usage(0);
	if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
	if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
	if ( $Opt{version} ) { die "fetch_samplesheet.pl, ", q$Revision:  $, "\n"; } 
    !$ARGV[0] && pod2usage(); 
}



1; 

=head1 NAME

fetch_sample_config.pl - fetches a samplesheet for a given flowcell full path 


=head1 SYNOPSIS


fetch_sample_config.pl FLOWCELL_LOCATION [-force]

force to print when there != 8 lanes per flowcell

fetches the samplesheet for a full path (unique) from the saffronDB 

=cut


