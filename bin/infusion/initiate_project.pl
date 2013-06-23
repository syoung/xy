#! /usr/bin/perl 
use strict;
use FindBin qw($Bin); 
use lib "$Bin/../lib";
use lib "$Bin/../extlib/lib/perl5";
use Data::Dumper;
use warnings;
use Getopt::Long;
use Pod::Usage;
use File::Spec::Functions ':ALL';
use Illumina::WGS::Project;
use YAML::Tiny;
our %Opt;
process_commandline();


my @options = qw / 
          align_root
          build_root
          build_version
          build_type
          dbsnp_version
          project_name
          description
          includeNPF
          filesystem
          encryption/; 
          
          
my $yaml = YAML::Tiny->new;

my @more_options; 
if ($Opt{other_options}){
    my @tmp = split /;/, $Opt{other_options};   
    foreach my $s (@tmp){
        my @d = split /:/, $s;
        $d[0] =~ s/\s.//;
        $d[1] =~ s/\s.//;
        $Opt{$d[0]} = $d[1];    
        push @options, $d[0]; 
    }
}
          
foreach my $option (@options){
    if ($Opt{$option}){
        $yaml->[0]->{$option} = $Opt{$option}; 
    }
}


my $pconf =  $yaml->write_string; 

my %hash = (
    project_name => $yaml->[0]->{project_name}, 
    dbsnp_version => $yaml->[0]->{dbsnp_version}, 
    build_version => $yaml->[0]->{build_version}, 
    description => $Opt{description}, 
    build_location => $yaml->[0]->{build_location}, 
    project_policy => $pconf, 
	status_id => 63
); 

print Dumper \%hash; 


if ($Opt{now}){
    my $proj = Illumina::WGS::Project->create(\%hash); 
    print "created project id " . $proj->project_id . "\n"; 
    
    
}
else {
    print "DRY RUN!\n"; 
    print "use -now to store in database\n"; 
}


sub process_commandline {
    my $yaml = YAML::Tiny->read( "$Bin/../config.yaml" )|| die "cannot read config.yaml";
    %Opt = %{$yaml->[0]}; 
    GetOptions(
        \%Opt, qw(
          debug
          dryrun
          now
          align_root=s
          build_root=s
          build_version=s
          dbsnp_version=s
          project_name=s
          description=s
          includeNPF=s
          filesystem=s
          encryption=s
          other_options=s
          help
          )
    ) || pod2usage(0);
    if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
    if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
    if ( $Opt{version} ) { die "import_manifest.pl, ", q$Revision:  $, "\n"; }
    !$Opt{project_name} && pod2usage();
}
__END__


=head1 NAME
    
    initiate_project.pl : reads a config and stores the project policy
    
=head1 SYNOPSIS

    initiate_project.pl -project_name NAME 
    
        default values in config.yaml
          [-align_root ]
          [-build_root CONFIG]
          [-build_version NCBI37]
          [-dbsnp_version 131]
          [-description "project description"] 
          [-includeNPF n]
          [-filesystem undef]
          [-encryption undef]
          [-other_options example:value;example2:value2]
          [-now]

    reads the config.yaml and allow to override those variables. writes the output to the 
    project.project_policy. 
	
=cut

1; 
