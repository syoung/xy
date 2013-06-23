#! /usr/bin/perl 
use strict; 
use warnings;
use FindBin qw($Bin); 
use lib "$Bin/../lib";
use lib "$Bin/../extlib/lib/perl5";
use Data::Dumper; 
use Getopt::Long;
use Pod::Usage; 
use XML::Simple; 
use File::Spec::Functions ':ALL'; 
use Illumina::WGS::Flowcell;
use Illumina::WGS::Status;
use Date::Manip qw(ParseDate UnixDate); 
use YAML::Tiny;
use Digest::MD5 qw(md5 md5_hex md5_base64);
our %Opt; 
process_commandline(); 
#will be used by the multi-site work
# get the actual isilon data server from mount 

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
my $hr_status2id = Illumina::WGS::Status->hasref_status2id;
my $hr_id2status = Illumina::WGS::Status->hashref_id2status;

#caches the locations in the database
my $md5locs = Illumina::WGS::Flowcell->md5loc_href; 

### read run_parameters.xml to populate the 
### flowcell columns
my $xs = XML::Simple->new(); 

my @inputs; 
if (@ARGV){
    @inputs = @ARGV; 
}
else {
    foreach my $run_root (@{$Opt{run_root}}){
        opendir(my $dh, $run_root) || die $!; 
        my @tmpinputs = map {catdir($run_root, $_)} grep { -d "$run_root/$_" && /^1/ } readdir($dh);        
        push @inputs, @tmpinputs; 
        closedir $dh; 
    }
}

if (!@inputs){
    print STDERR "nothing to do\n"; 
    pod2usage; 
}


##### get flowcells in to_rehyb state
my %rehyb; 
my @to_rehyb = Illumina::WGS::Flowcell->search(status_id => $hr_status2id->{'to_rehyb'}); 
print "found ". (scalar @to_rehyb) . " flowcells \n"; 
foreach my $r (@to_rehyb){
	if (!$rehyb{$r->flowcell_barcode}){
		my @arr = ($r); 
		$rehyb{$r->flowcell_barcode} = \@arr; 
	}
	else {
		push @{$rehyb{$r->flowcell_barcode}}, $r;
	}
}

my @flowcells; 
my @msgs; 
my $c_alreadystored=0; 
my $c_new = 0; 
my $c_parsed = 0; 
my %c_failparse;  

my @fc_need_update; 
foreach my $path (@inputs){   
    $Opt{verbose} && print "scanning : $path \n"; 
	if ($path =~ /^[[a-zA-Z0-9\/_-]+$/){
		#$Opt{debug} && print "$path looks ok\n"; 
	}
	else {
		$Opt{debug} && print "PROBLEM :  $path looks not ok\n"; 
		next; 
	}
    $c_parsed++;
	my @dirs = split /\//, $path; 
	my $storage = $Opt{$hostname}{$dirs[1]}; 
	if (!$storage){
		print "PROBLEM: not known isilon storage server for $path and $hostname\n";
		next;
	}
	$Opt{debug} && print "storage $storage \n"; 
	
    my $location_md5sum = md5_hex($path);
    if ($md5locs->{$location_md5sum}){
        $c_alreadystored++; 
        next;
    }
    if (! -d $path){
        my $m =   "path $path does not exist"; 
        push @msgs, $m; 
        $c_failparse{$path}++; 
        next; 
    }
    if (! -s catfile($path, 'runParameters.xml')){
        my $m  = catfile($path, 'runParameters.xml') . "does not exist \n";
        push @msgs, $m; 
        $c_failparse{$path}++; 
        next; 
    }
    if (!open(my $fh, catfile($path, 'runParameters.xml'))){
        print "cannot read files in $path!!\n"; 
        next; 

    }
    my $x = $xs->XMLin(catfile($path, 'runParameters.xml'));      
    if (ref($x->{Setup}{Reads}{Read}) ne 'ARRAY'){
        my $m = "something fishy here $path runParameters.xml\n";
		$Opt{debug} && print $m . "\n"; 
        $c_failparse{$path}++; 
        next; 
    } 
           
    my $flowcell_barcode = uc $x->{Setup}{Barcode}; 
    
    #I only need to update status if a new flowcell appears and the old on 
    # is in run status rehyb
	if ($rehyb{$flowcell_barcode}){
		$Opt{debug} && print "need to upated old rehybs to fail \n"; 
		my @fc_rehyb = @{$rehyb{$flowcell_barcode}}; 
		foreach my $fc (@fc_rehyb){
			$fc->status_id($hr_status2id->{'run_failed'}); 
			push @fc_need_update, $fc; 
		}
	}
    my $i=0; 
    my @arrlen; 
    foreach my $read (@{$x->{Setup}{Reads}{Read}}){
        push @arrlen, $x->{Setup}{Reads}{Read}->[$i]->{NumCycles}; 
        $i++;
    }
    my %hash = (
        flowcell_barcode => $flowcell_barcode, 
        fpga_version => $x->{Setup}{FPGAVersion}, 
        rta_version => $x->{Setup}{RTAVersion}, 
        machine_name => $x->{Setup}{ScannerID},
        run_length => join(",", @arrlen), 
        status_id => 1, 
        run_start_date => $x->{Setup}{RunStartDate}, 
        location => $path, 
        location_md5sum => $location_md5sum, 
		server => $storage
        );
    push @flowcells, \%hash;  
    $c_new++;         
} 
my $msg = qq! Previously Stored: $c_alreadystored; New: $c_new; Parsed: $c_parsed ;  Failed_Parsing: !.  (values %c_failparse) . "\n"; 
push @msgs, $msg; 


my $v=0;   
foreach my $fc (@flowcells){
	$v++; 
	if ($Opt{dryrun}){
		$Opt{debug} && print "will create " . $fc->{location} . "\n"; 
	}
	else {
		my $fci= Illumina::WGS::Flowcell->create($fc); 
		my $msgs =  $fci->flowcell_barcode . "  inserted with id  " . $fci->flowcell_id ; 
		push @msgs, $msgs; 
	}
}
print "created $v flowcells \n"; 
my $z=0;  
foreach my $fc (@fc_need_update){
	if ($Opt{dryrun}){
		$Opt{debug} && print "will update " . $fc->location . " to ". $hr_id2status->{$fc->status_id} . "\n"; 
		$fc->discard_changes; 	
	}
	else {
		$fc->update(); 
	}
	$z++; 
}
print "updated rehybs $z\n"; 
$Opt{dryrun} && print "DRY RUN !!!! \n"; 
   

   
$Opt{debug} && print join( "\n", @msgs ) . "\n"; 



    
sub process_commandline {
     my $yaml = YAML::Tiny->read( "$Bin/../config.yaml" )|| die "cannot read config.yaml";
     %Opt  = %{$yaml->[0]}; 
    GetOptions(
		\%Opt, qw(
        debug
        now
        dryrun
        version
        verbose
        help
		  )
	) || pod2usage(0);
	if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
	if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
	if ( $Opt{version} ) { die "import_manifest.pl, ", q$Revision:  $, "\n"; }
    if (!$Opt{now}) { pod2usage(); }
}



1; 


__END__

=head2 API

=head1 NAME

import_flowcell.pl             

=head1 USAGE

import_flowcell.pl -now [/illumina/upload/services/120111_SN887_0128_AD0KRTACXX_CRUKDiv1]

PURPOSE

This script reads the config.yaml for the locations being tracked.

It assigns a isilon storage cluster based on pre-defined mappings listed in the config. This information is used for rsyncd across different  isislon clusters. It also validates a flowcell unix location and if it is readable for the user running the script. It looks for the runParameters.xml file at the base of the flowcell run and if the file is valid parses it. For each flowcell it stores the following information. 

For flowcells that are in the state “to_rehyb” it tries to find the new incoming flowcell with the same barcode and mark the “to_rehyb” to fail state. 

INPUTS

	flowcell_barcode:
		type		:	String
		discretion	:	required
		description	: 	As listed on the runParameters.xml. This may not be unique across the system if the same flowcell is rehybed.
	fpga_version:
		type		:	String
		discretion	:	required
		description	: 	As listed in the runParameters.xml
	rta_version:
		type		:	String
		discretion	:	required
		description	: 	As listed in the runParameters.xml 
	machine_name:
		type		:	String
		discretion	:	required
		description	: 	As listed in the runParameters.xml
	run_length:
		type		:	String
		discretion	:	required
		description	: 	As listed in the runParameters.xml
	status_id:
		type		:	String
		discretion	:	required
		description	:	Status ID with corresponding status field in 'status' table
		value		:	"run_started"
	run_start_date:
		type		:	String
		discretion	:	required
		description	:	As listed in the runParameters.xml
	location:
		type		:	String
		discretion	:	required
		description	:	Truly unique for one file system. If appears in several filesystems (copied over) it will be ignored.  
	location_md5sum:
		type		:	String
		discretion	:	required
		description	:	Really the same as the location, it is unique, being used to check if the flowcell location is already known
	server:
		type		:	String
		discretion	:	required
		description	:	Mapped between the cluster it is in and the location it is mounted


OUTPUTS

	data:
		type		:	JSON
		description	:	Replica of the flowcell table entry composed of all of the inputs, with all required keys populated
		
=cut
