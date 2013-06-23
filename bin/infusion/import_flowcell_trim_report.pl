#! /usr/bin/perl 
use strict; 
use warnings; 
use FindBin qw($Bin); 
use lib "$Bin/../lib";
use lib "$Bin/../extlib/lib/perl5";
use Data::Dumper; 
use Getopt::Long;
use Pod::Usage; 
use Illumina::WGS::TrimReport;
use Illumina::WGS::Flowcell;
use File::Spec::Functions ':ALL';
use YAML::Tiny;
our %Opt; 


&process_commandline(); 
#will be used by the multi-site work
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
print "running on $hostname \n"; 



my $h_fl = Illumina::WGS::TrimReport->all_md5sum_href; 
my $dbh = Illumina::WGS::TrimReport->db_Main; 
my $q = 'select f.location , flowcell_id
        from flowcell f 
		where f.status_id in( 1,2)'; 
my $sth = $dbh->prepare($q); 
$sth->execute(); 


my @need_update; 
while (my $r = $sth->fetchrow_hashref){
	my $loc = $r->{location}; 
	if (!-d $loc){
		$Opt{verbose} && print " INFO $loc no longer present\n"; 
		next; 
	}
	my $report = catdir($loc, 'Logs', 'trim_report.tsv'); 
	if (-s $report ){
		my $md5sum = `md5sum $report | awk '{print \$1}'`;
		chomp $md5sum;
		my %hash = (flowcell_id => $r->{flowcell_id},
					check_md5sum => $md5sum
					); 
		if (!$h_fl->{$r->{flowcell_id}}){
			push @need_update, \%hash; 
		}
		elsif ($h_fl->{$r->{flowcell_id}} && $h_fl->{$r->{flowcell_id}} ne $md5sum){
			push @need_update, \%hash; 
		}
	}
	else {
		$Opt{verbose} && print "did not find $report\n"; 
	}	
}
print "found " . (scalar @need_update) . " reports that need update\n"; 

#foreach existent input check md5sum

foreach my $fc (@need_update){
	my $flowcell = Illumina::WGS::Flowcell->retrieve($fc->{flowcell_id});
	my $report = catfile($flowcell->location, 'Logs', 'trim_report.tsv'); 
	my $hr_lane = parse_report($report); 
  	if (!$hr_lane){
		$Opt{verbose} && print "cannot parse $report; next\n";  
		next; 
	}
	foreach my $lane (@{$hr_lane}){
		#hack 
		if ($lane->{lane} <1 ){
			$Opt{debug} && print "found irregular lane $lane \n"; 
			next; 
		}
	
		my @reports = Illumina::WGS::TrimReport->search(
				flowcell_id => $flowcell->flowcell_id,
				lane => $lane->{lane}
			); 	
		if (@reports){
			#unique key inforced in DB
			my $dx = $reports[0]; 
			foreach my $k (keys %{$lane}){
				next unless ($dx->can($k)); 
				$dx->$k($lane->{$k}); 
			}
			$dx->check_md5sum($fc->{check_md5sum}); 
			if (!$Opt{dryrun}){
				$dx->update(); 
			}
			$Opt{verbose} && print "updating " . $dx->to_string . "\n"; 
		}
		else {
			my %temp; 
			foreach my $k (keys %{$lane}){
				#put in next if does not work.
				$temp{$k} = $lane->{$k}; 
			}
			$temp{check_md5sum} = $fc->{check_md5sum}; 
			$temp{flowcell_id} = $flowcell->flowcell_id; 
			if (!$Opt{dryrun}){
				my $c = Illumina::WGS::TrimReport->create(\%temp); 
			}
			$Opt{verbose} && print "creating " . $flowcell->location ."  ". $temp{lane}.   " from trim report\n"; 
		}
	}
}


sub parse_report {
    my $f = shift;
	if (!open(FH, $f)){
		print "failed to open $!\n"; 
		return 0; 
	} 
    my @header ; 
    my @lanes; 
    while (<FH>){ 
        chomp; 
        my %hash; 
        next if /^$/; 
        next if /^#/; 
        if (/^flowcell/){
            @header = split /\t/, $_; 
            next; 
        }
        if (!@header){
            print "$f : report header not present!\n"; 
            last;
        }
        my @line = split /\t/, $_; 
        for (my $i = 0; $i < scalar @header ; $i++){
            next unless $line[$i]; 
            if ($line[$i] eq 'NA' || $line[$i] eq 'None'){
                next; 
            }
            $hash{$header[$i]} = $line[$i]; 
        }
        push @lanes, \%hash;   
    }
    close FH;
    return \@lanes; 
}



sub process_commandline { 
    my $yaml = YAML::Tiny->read( "$Bin/../config.yaml" )|| die "cannot read config.yaml";
    %Opt  = %{$yaml->[0]}; 
	GetOptions(
		\%Opt, qw(
        debug
		verbose
        version
        debug
        dryrun
        now
        help
		  )
	) || pod2usage(0);
	if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
	if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
	if ( $Opt{version} ) { die "import_flowcell_report.pl, ", q$Revision:  $, "\n"; }
    if (!$Opt{now}) {pod2usage()} ; 
}

1; 

__END__
 
 
 
=head1 NAME

import_flowcell_trim.pl - checks if a running or finished flowcell
report trim has been updated and if yes updates the columns  



=head1 SYNOPSIS

import_flowcell_trim.pl [-now]


=cut


1; 
