#! /usr/bin/perl 
use strict; 
use warnings; 
use FindBin qw($Bin); 
use lib "$Bin/../lib";
use lib "$Bin/../extlib/lib/perl5";
use Data::Dumper; 
use Getopt::Long;
use Pod::Usage; 
use File::Spec::Functions ':ALL';
use Illumina::WGS::BuildQueue;
use Illumina::WGS::Sample;
use Illumina::WGS::SampleSheet;
use Illumina::WGS::Status;
use YAML::Tiny;
our %Opt; 
&process_commandline(); 

##
# delete all files in Assembly > 40M
# delete Consensus 
# delete Genotying 
# delete bcls per lane 
# mv Aligned to pending
#

 
my $hr_status2id = Illumina::WGS::Status->hasref_status2id;
my $hr_id2status = Illumina::WGS::Status->hashref_id2status;
  
my $dbh = Illumina::WGS::Sample->db_Main;   


#fetch samples qc pass or delivered
## NOTE if new bcls for a qc pass are generated those get deleted too
#
#65 qc pass
# 20 delivered
# 50 archive_pending
my $q = qq/ select sample_id, sample_barcode 
	from sample s , project p 
	where p.project_id = s.project_id /; 	
if ( $Opt{sample_barcode} ) {
    $q .= qq! and s.sample_barcode = '$Opt{sample_barcode}' !;
}
if ( $Opt{project_name} ) {
    $q .= qq! and p.project_name = '$Opt{project_name}' !;
}
$q .= qq/  
	and s.status_id in(65,50,20) order by p.project_id, s.delivered_date asc/;  
$Opt{debug} && print $q . "\n"; 
my $sth = $dbh->prepare($q); 
$sth->execute() || die "cannot execute $!";


### gather samples
my @samples; 
while (my $scode = $sth->fetchrow_hashref){
	my $sample = Illumina::WGS::Sample->retrieve($scode->{sample_id}); 
	push @samples, $sample; 
}
my $sc=@samples; 
$Opt{verbose} && print "found $sc samples delivered or archived\n"; 

### delete bcls
my @lanes_to_delete;
if (!$Opt{skip_lane_deletion}){

	#get all lanes to delete the bcls
	foreach my $sample (@samples){
		my @sas = Illumina::WGS::SampleSheet->search(
			sample_id => $sample->sample_id
		); 
	
		foreach my $lane (@sas){
			my $loc = $lane->location; 
			$loc =~ s/\/SampleSheet\.csv//; 
			#print $loc ."\n"; 
			if ($loc =~ /RUO/){
				next; 
			}	
			my $fc = Illumina::WGS::Flowcell->retrieve($lane->flowcell_id); 
			if ($fc->status_id == 1 ){
				$Opt{debug} && print $fc->location ." still running; skip deletion\n "; 
				next;
			}
			if ( -e catfile($loc, 'ARCHIVE_SKIP.txt')){
				$Opt{verbose} && print "#### found ARCHIVE_SKIP.txt\n"; 
				next; 
			}
			my $del = catdir($loc, 'Data/Intensities/BaseCalls/L00'.$lane->lane); 		
			if (!-d $del){
				$Opt{debug} && print "cannot find $del\n"; 
			}
			else {
				push @lanes_to_delete, $lane; 
				$Opt{verbose} && print "deleting $del\n"; 
			}
		}
	}
}

### move aligned
my %loc2samples; 		
if (!$Opt{skip_mv_aligned}){	
	my $xz=0;
	foreach my $sample (@samples){
		my $project = Illumina::WGS::Project->retrieve($sample->project_id);
		my $location = catdir($Opt{build_root}, $project->project_name, $sample->sample_barcode, 'Aligned');		
		if (-e catfile($Opt{build_root}, $project->project_name, 'ARCHIVE_SKIP.txt')){
			$Opt{verbose} && print "#### skip project: " . $project->project_name . " ; found ARCHIVE_SKIP.txt\n"; 
			next;
		}
		if (-e catfile($Opt{build_root}, $project->project_name, $sample->sample_barcode, 'ARCHIVE_SKIP.txt')){
			$Opt{verbose} && print "#### skip sample: " . $sample->sample_barcode . "  found ARCHIVE_SKIP.txt\n"; 
			next;
		}
		$Opt{debug} && print join("  ", $project->project_name, 
			$sample->sample_barcode, $sample->delivered_date). "\n"; 
		#mv Aligned to backup
		if (!-d $location){
			$Opt{debug} && print "$location no longer exists; use force to update sample to archived\n"; 	
			#special case for samples already archived 
			if ($Opt{force} && !$Opt{dryrun}){
				#$sample->status_id($hr_status2id->{archive_pending});
				#$sample->update; 
				$xz++; 
			}
		}
		else {
			$loc2samples{$location} = $sample; 
		}
	}
	$xz && print "updated force $xz\n"; 
	
	
}

my $ar_builds ; 
if (!$Opt{skip_3weeks_deletion}){
	$ar_builds = &check_to_delete_from_builds();
}

my $c=@lanes_to_delete; 
print "found $c lanes ready to delete\n"; 
my $cc = keys %loc2samples; 
print "found $cc Aligned folders ready to archive\n"; 
my $qq= $ar_builds ? @$ar_builds : 0 ; 
print "found  $qq assembly folders ready to clean\n"; 

if ($Opt{dryrun}){
	print "DRY RUN\n"; 
	exit; 
}
##########################################
# DELETION
##########################################
## actually moving
my $w=0; 
my $destination = $Opt{archive_pending};
foreach my $ori_path (keys %loc2samples){
	my $sample_obj = $loc2samples{$ori_path}; 
	my $dest_sample = catdir($destination, $sample_obj->sample_barcode); 
	my @args2 = ('cp', catdir($ori_path, 'alignment_check.txt'), "$ori_path/../"); 
	my @args = ('mv',  $ori_path, $dest_sample);
	$Opt{debug} && print join(" " , @args2) . "\n"; 
	$Opt{debug} && print join(" " , @args) . "\n"; 
	system(@args2)==0 || warn "system @args2 failed : $! \n"; 
	system(@args)==0 || warn "system @args failed : $! \n"; 
	#$sample_obj->status_id($hr_status2id->{archive_pending});
	#$sample_obj->update; 
	$w++; 
}	
my $msg = "moved $w Aligned folders"; 
$Opt{verbose} && print $msg. "\n"; 		

#actually deleting lanes
my $z=0; 
foreach my $lane (@lanes_to_delete){
	my $loc = $lane->location; 
	$loc =~ s/\/SampleSheet\.csv//; 
	my $lane_num = $lane->lane; 
	my $del = catdir($loc, 'Data/Intensities/BaseCalls/L00'.$lane_num); 		
	my $cmd = qq! qsub -terse -o $del.deleted.stdout -e $del.deleted.stderr -b y -N delbcl.$lane_num rm -rf $del !; 
	$Opt{debug} && print $cmd . "\n";
	my $jid = `$cmd`; 
	$z++;	
	$lane->status_id($hr_status2id->{bcl_deleted}); 
	$lane->update; 
}
my $msg2 = "deleted $z lanes "; 
$Opt{verbose} && print $msg2. "\n"; 	

#actually delete stuff in builds
my $y=0; 
foreach my $build (@{$ar_builds}){
	#del sh is now in the root of the folder 
	my $del = catfile($build, 'del.sh'); 
	if (-e $del && !$Opt{force}){
		next;
	}
	open FH , ">$del" || die "cannot open $del"; 
	my $cmd =  " find Assembly -type f -size +40M | grep -v vcf | tee -a DELETED.txt | xargs rm -f  "; 
	my $cmd1 =  " find Consensus  | tee -a DELETED.txt | xargs rm -rf  "; 
	my $cmd2 =  " find Genotyping |  tee -a DELETED.txt | xargs rm -rf  "; 
	my $cmd3 = "find Logs -type f -size +10M | tee -a DELETED.txt | xargs rm -f "; 
	my $cmd4 = "find Variations -type d -name '*dbSNP*' | tee -a DELETED.txt | xargs rm -rf "; 
	print FH "#! /bin/bash \n";
	print FH $cmd . "\n"; 
	print FH $cmd1 . "\n"; 
	print FH $cmd2 . "\n"; 
	print FH $cmd3 . "\n"; 	
	print FH $cmd4 . "\n"; 
	close FH; 	
	print "WORKING ON $build\n";
	my $e = ` cd $build; qsub -p 1024 -N deletion del.sh  `;
	$Opt{debug} && print $e . "\n"; 
	$y++; 
}
my $msg3 = "deleted files and folders in $y builds\n"; 
print "DONE\n"; 


################################################
# SUBS
################################################
sub check_to_delete_from_builds {
	my $q2 = qq/SELECT sample_id, sample_barcode , p.project_id , p.project_name
	FROM sample s , project p 
	where 
	p.project_id = s.project_id AND 
	datediff(now(),s.delivered_date) >= 18  and s.status_id in (20, 50)
	and delivered_date is not null /	; 	
	if ( $Opt{sample_barcode} ) {
		$q2 .= qq! and s.sample_barcode = '$Opt{sample_barcode}' !;
	}
	if ( $Opt{project_name} ) {
		$q2 .= qq! and p.project_name = '$Opt{project_name}' !;
	}
	$q2 .= qq/ order by p.project_id, s.delivered_date  asc	/; 
	$Opt{debug} && print $q2 . "\n";	
	my $sth1 = $dbh->prepare($q2); 
	$sth1->execute(); 
	my $i=0; 
	my @to_del; 
	while (my $r = $sth1->fetchrow_hashref){
		my $projloc = catdir($Opt{build_root}, $r->{project_name}); 
		my $buildloc = catdir($Opt{build_root}, $r->{project_name}, $r->{sample_barcode}); 
		my $genome = catdir($buildloc, 'Assembly', 'genome');
		my $genomebam = catdir($buildloc, 'Assembly', 'genome', 'bam', 'sorted.bam');
		my $assembly = catdir($buildloc, 'Assembly'); 
		if (-e catfile($projloc, 'ARCHIVE_SKIP.txt')){
			$Opt{verbose} && print "#### skip project: " . $projloc. " ; found ARCHIVE_SKIP.txt\n"; 
			next;
		}
		if (-e catfile($buildloc, 'ARCHIVE_SKIP.txt')){
			$Opt{verbose} && print "#### skip sample: " . $buildloc . "  found ARCHIVE_SKIP.txt\n"; 
			next;
		}
		$Opt{debug} && print $buildloc . "\n"; 
		#if these exist then target the sample folder 
		# bam in the assembly folder 
		# consensus folder 
		# genotyping
		my $consensusloc = catdir($buildloc, 'Consensus'); 
		my $genotypingloc = catdir($buildloc, 'Genotyping'); 
		if (-e $genomebam || -d $consensusloc || -d $genotypingloc ){
			push @to_del,  $buildloc; 
			$i++; 
		}
		else {
			$Opt{debug} && print "targets cannot be found \n"; 
		}
		if ($i == 1000){
			last; 
		
		}
	}
	return \@to_del; 
}


##
sub process_commandline {
     
    my $yaml = YAML::Tiny->read( "$Bin/../config.yaml" )|| die "cannot read config.yaml";
    %Opt = %{$yaml->[0]}; 
	$Opt{status} = 'building'; 
  	GetOptions(
		\%Opt, qw(
        debug
		now
		dryrun
	    nolimit
        project_name=s
		sample_barcode=s
		skip_lane_deletion
		skip_mv_aligned
		skip_3weeks_deletion
        help
		force
		verbose
		)
	) || pod2usage(0);
	if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
	if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
    if (!$Opt{now}) { pod2usage( ); }
}
 __END__
 
 
 
=head1 NAME

archive_builds.pl 

=head1 SYNOPSIS

archive_builds.pl  -now [-dryrun] [-skip_lane_deletion] [-skip_mv_aligned] [-skip_3weeks_deletion] 
					[-project_name PROJ] [-sample_name SAMPLE]
					


# find delivered from database
# move aligned to build , rename to sample name and copy alignment check to run folder
# remove associated lanes bcls
# update sample to pending_archive
# update samplesheet status to bcl_deleted
# after 3 weeks of delivery date delete bam TODO


log can be found in ../log/archive_builds.log

=cut


1; 
