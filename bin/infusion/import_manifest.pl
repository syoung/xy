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
use Illumina::WGS::Project; 
use YAML::Tiny;
our %Opt; 

   #Row     Sample Name     Barcode Species 
    #Sex(M/F/U)     Volume (ul)     
    #Concentration (ng/ul)   
    #OD 260/280      Tissue Source   
    #Extraction Method       Ethnicity       
    #Parent 1 Barcode        Parent 2 Barcode       
    #Replicate(s) Barcode(s) Cancer sample (Y/N)     
    #Matched Pair Barcode(s) Matched Pair Type       
    #Project    Genome Build    
    #dbSNP Version  Fold coverage Comment 
    #GT Gender 
    

use constant {
    ROW                 => 0,
	GROUP				=> 1,
    SAMPLE_NAME         => 2,   
	PLATE_BARCODE       => 3, 
	WELL				=> 4, 
    SAMPLE_BARCODE      => 5,
    SPECIES             => 6,
    SEX                 => 7,
    VOLUME              => 8,
    CONCENTRATION       => 9,
    OD_260_280          => 10,
    TISSUE_SOURCE       => 11,
    EXTRACTION_METHOD   => 12,
    ETHNICITY           => 13,
    PARENT1_BARCODE     => 14,
    PARENT2_BARCODE     => 15,
    REPLICATES          => 16, 
    CANCER              => 17,
    MATCH_PAIR          => 18,
    MATCH_PAIR_TYPE     => 19,
    PROJECT             => 20,
    GENOME_BUILD        => 21,
    DBSNP_VERSION       => 22,
    FOLD_COVERAGE       => 23,
    DUE_DATE            => 24,
    COMMENT             => 25,
    GT_GENDER           => 26,
	COMMENTS2			=> 27,
	ANALYSIS 			=> 28
}; 
 
process_commandline();

my @allprojs_p = Illumina::WGS::Project->retrieve_all; 

my %projs_p; 
foreach my $p (@allprojs_p){
    $projs_p{$p->project_name} = $p;
 }

open(FH, $ARGV[0]) || die $!; 
my @to_proj_store; 
my %seen; 
while (my $l  = <FH>){
    chomp $l; 
    my @line = split /\t/, $l; 
    next if ($l =~ /^\s*$/);     
    next if ($l =~ /^Row/); 
    $line[PROJECT] =~ s/\s//g; 	
	if ($projs_p{$line[PROJECT]}){
		$Opt{verbose} && print "project stored " . $line[PROJECT] . "\n";
		next; 
	}
	if ($line[DBSNP_VERSION] =~ /^131|129$/){
		$Opt{verbose} && print "snp ok\n"; 
	}
	else {
		print "unknown dbsnp" .$line[DBSNP_VERSION] . "\n"; 
		next; 
	}
	if ($line[GENOME_BUILD] =~ /^36|37$/){
		$line[GENOME_BUILD] = 'NCBI'.$line[GENOME_BUILD]; 
	}
	else {
		print "unknown genome ". $line[GENOME_BUILD] . "\n"; 
		next; 
	}
	if ($seen{$line[PROJECT]}){
		next; 
	}
	my %hash = (
		project_name => $line[PROJECT],  
		dbsnp_version => $line[DBSNP_VERSION], 
		build_version => $line[GENOME_BUILD], 
		project_policy => "---\nbuild_type: local\n", 
		status_id => 63
	);
	$seen{$line[PROJECT]}++; 
	push @to_proj_store, \%hash; 
	
}
close FH; 

if ($Opt{now}){
	foreach my $p (@to_proj_store){
		my $p = Illumina::WGS::Project->create($p); 
		my $proj_dir = "/illumina/build/services/Projects/".$p->project_name; 
		
		my $c1 =  "mkdir $proj_dir" ; 
		my $c2 = "cp /illumina/build/services/Projects/Templates/Build_Wrappers/v2.0/" . $p->build_version.'/*  ' .$proj_dir ; 
		print $c1. "\n"; 
		system($c1) == 0 || die $!; 
		system($c2) == 0 || die $!; 
		
	}
}
else {
	print Dumper \@to_proj_store; 
}

my @allprojs = Illumina::WGS::Project->retrieve_all; 
my %projs; 
my %revproj; 
foreach my $p (@allprojs_p){
    $projs{$p->project_name} = $p;
    $revproj{$p->project_id}  = $p->{project_name}; 
}



open(FH, $ARGV[0]) || die $!; 

my @parsed; 
my @already_stored; 
while (my $l = <FH>){

    chomp $l; 
    my @line = split /\t/, $l; 
    next if ($l =~ /^\s*$/);     
    next if ($l =~ /^Row/); 
    $Opt{verbose} && print  "PROCESSING ". $line[SAMPLE_BARCODE] . "\t=>";    
    $Opt{verbose} &&  print "--->" . $line[SAMPLE_BARCODE] . "<---\t"; 
    #strip non characters and numbers	
    if ($line[SAMPLE_NAME]){
        $line[SAMPLE_NAME] =~ s/\W+/_/; 
    }
	my $sample_barcode = &validate_sample_barcode($line[SAMPLE_BARCODE]); 
	if (!$sample_barcode){
		print "not valid sample barcode: " . $line[SAMPLE_BARCODE] . "\n"; 
		next; 
    }
 
    #sex
    $line[SEX] = uc $line[SEX];
    if ($line [SEX] =~ /female/i){
        $line[SEX] = 'F'; 
    }
    if ($line[SEX] =~ /male/i){
        $line[SEX] = 'M'; 
    }
    if ( $line[SEX] && ($line[SEX] eq 'M'||$line[SEX] eq 'F' || $line[SEX] eq 'U')    ){
        $Opt{verbose} && print "gender_ok:". $line[SEX] . "\t"; 
    } 
    elsif ($line[SEX] && $line[SEX] ne 'N/A'){
        print  "$sample_barcode : problem with SEX : not M or F or U ; ". $line[SEX]. "next\n";
        next;
    }
	elsif ($line[SEX] eq 'N/A'){
		    $line[SEX] = 'U'; 
    }
    else {
        $Opt{verbose} && print "$sample_barcode  :  SEX is blank!!! setting to U\n"; 
        $line[SEX] = 'U'; 
    }
    #species
    if ($line[SPECIES] ne 'Human' && $line[SPECIES] ne 'Homo Sapiens'){
        $Opt{verbose} && print  "$sample_barcode  : expected Human;";
        if ($line[SPECIES] eq ''){
            $Opt{verbose} && print "setting to Human!! \t"; 
            $line[SPECIES] = 'Human'; 
        }
        else {
            print "skipping because it is "  . $line[SPECIES] . "FIX IT\n"; 
            next; 
        }
    }
    else {
        $Opt{verbose} &&  print "got Human \t"; 
    }
	#cancer 
	$line[CANCER] = uc $line[CANCER];
	if ($line[CANCER] eq 'N' || $line[CANCER] eq 'NO' || $line[CANCER] =~ /^N/){
		$line[CANCER] = 'N'; 
	}
	elsif ($line[CANCER] eq 'Y' || $line[CANCER] eq 'YES' || $line[CANCER] =~ /^Y/){
		$line[CANCER] = 'Y'; 
	}
	else {
		$line[CANCER] = 'N'; 
	}
	
	
	
	
    #gt_gender
    if ($line[GT_GENDER] && ($line[GT_GENDER] eq 'Female' || $line[GT_GENDER] eq 'F')){
        $line[GT_GENDER] = 'F';
        $Opt{verbose} && print "gt_gender_ok:" . $line[GT_GENDER] . "\t"; 
    }
    elsif ($line[GT_GENDER] && ($line[GT_GENDER] eq 'Male' || $line[GT_GENDER] eq 'M')){
        $line[GT_GENDER] = 'M'; 
        $Opt{verbose} && print "gt_gender_ok:" . $line[GT_GENDER] . "\t"; 
    }
    elsif ($line[GT_GENDER]){
		$line[GT_GENDER] = undef; 
        $Opt{verbose} && print "$sample_barcode  : gender is not Female, Male or blank!!! ->". $line[GT_GENDER] . "<- making undef\n"; 
    }
    else {
		$line[GT_GENDER] = undef; 
        $Opt{verbose} && print "$sample_barcode  : gt_gender not defined yet\n";      
		
    }
    if (!$line[FOLD_COVERAGE]){
        $line[FOLD_COVERAGE] =30; 
    }
    if ($line[DUE_DATE]){
		if ($line[DUE_DATE]=~ /(\d{1,2})\/(\d{1,2})\/(\d{4})/){
			$line[DUE_DATE] = $3.'-'.sprintf("%02d",$1).'-'.$2; 
		}
		else {
			$line[DUE_DATE] =undef;  
		}
	}
	else {
		$line[DUE_DATE] = undef; 
	}
	
	#$line[DUE_DATE] && print $line[DUE_DATE] . "\n"; 
    #keep volume and concentration as floats only
    # tr modifiers
    # c complete
    # d delete unreplaced
    $line[VOLUME] =~ tr/0-9\.//cd; 
    $line[CONCENTRATION]  =~ tr/0-9\.//cd; 
    $line[OD_260_280] =~ tr/0-9\.//cd; 
    $line[FOLD_COVERAGE] =~ tr/0-9//cd; 
    

    
    $line[PROJECT] =~ s/\s//g; 
    
    ### analysis ; allow LOX only for now
	$line[ANALYSIS] =~ s/\s//g; 
	$line[ANALYSIS] = uc $line[ANALYSIS]; 
	if ($line[ANALYSIS] && $line[ANALYSIS] eq 'LOX'){
		$Opt{verbose} && print "analysis_ok:" . $line[ANALYSIS] . "\n"; 
	}
	elsif ($line[ANALYSIS]){
		print "ANALYSIS NOT KNOWN " . $line[ANALYSIS ] . "; next \n"; 
		next; 
	}
	else {
		$line[ANALYSIS] = undef;
	}
	
	### match pair 
	## if the matched par is not stored skip it. it means you need to run it twice to 
	## get all samples , if they are new. 	
	$line[MATCH_PAIR] =~ s/\s//g; 
	$line[MATCH_PAIR] =~ s/-CSS.*//; 
 	$line[MATCH_PAIR] = uc $line[MATCH_PAIR]; 
	my $pairID= undef;
	if ($line[MATCH_PAIR] && !($line[MATCH_PAIR] eq 'N/A' 
	|| $line[MATCH_PAIR] eq 'NONE' 
	|| $line[MATCH_PAIR] eq 'NA')){
		my $match_bc= &validate_sample_barcode($line[MATCH_PAIR]); 
		if (!$match_bc){
			print "invalid barcode ". $line[MATCH_PAIR]  ."\n"; 
		}
		else {
			my @sample_p = Illumina::WGS::Sample->search(sample_barcode => $match_bc); 
			if (!@sample_p){
				print "known known yet. may have to run twice the import: ". $match_bc . "\n"; 
				next; 
			}
			else {
				$pairID= $sample_p[0]->sample_id; 
			}
		}
	}
		
		
    if (!$projs{$line[PROJECT]}){
            print  "$sample_barcode : project " . $line[PROJECT]. " not in the database; MUST STORE PROJECT FIRST ; next\n"; 
            next; 
    }
    my $project = $projs{$line[PROJECT]}; 
    ###### check if in the database and if important fields have changed
    my $changed=0; 
    
    my @sample = Illumina::WGS::Sample->search((sample_barcode => $sample_barcode));
    if (!@sample){
        $Opt{verbose} && print  "Sample NOT known $sample_barcode; Storing\t"; 
        my %new = (
                sample_name => $line[SAMPLE_NAME],  
                sample_barcode => $sample_barcode, 
                species => $line[SPECIES], 
                gender => $line[SEX], 
                volume => $line[VOLUME], 
                concentration => $line[CONCENTRATION], 
                od_260_280 => $line[OD_260_280],
                tissue_source => $line[TISSUE_SOURCE], 
                extraction_method => $line[EXTRACTION_METHOD], 
                ethnicity => $line[ETHNICITY], 
                cancer => $line[CANCER], 
                comment => $line[COMMENT],
                target_fold_coverage => $line[FOLD_COVERAGE], 
                project_id => $project->project_id, 
                gt_gender => $line[GT_GENDER], 
				due_date => $line[DUE_DATE], 
				analysis => $line[ANALYSIS],
				match_sample_ids => $pairID,
				match_sample_type => $line[MATCH_PAIR_TYPE],
				status_id => 63
                ); 
        push @parsed, \%new;         
    }
    else {
        my $s = $sample[0]; 
        if ($s->gender ne $line[SEX]){
            $s->gender($line[SEX]); 
            print "$sample_barcode : ERROR: DATABASE gender not equal to file sex !!!!\n"; 
            if ($Opt{override_db}){
                $s->gender($line[SEX]); 
            }
        }
        
        #gender update
        if ($s->gt_gender && $line[GT_GENDER] && ($s->gt_gender eq $line[GT_GENDER])){
            $Opt{verbose} && print "db gt_gender OK\t"; 
        }
        elsif ($s->gt_gender && $line[GT_GENDER] && ($s->gt_gender ne $line[GT_GENDER])) {
             print "$sample_barcode : ERROR db gt_gender NOT OK\t". $s->gt_gender .' != '. $line[GT_GENDER] . "\n"; 
              if ($Opt{override_db}){
                $s->gt_gender($line[GT_GENDER]); 
            }
        }
        elsif (!$s->gt_gender && $line[GT_GENDER]){
            print "$sample_barcode : gt_gender is now available:" . $line[GT_GENDER] . "\n"; 
            $s->gt_gender($line[GT_GENDER]); 
        }
        else {
			$line[GT_GENDER] = undef; 
            $Opt{verbose} && print "gt_gender still not available\t"; 
        }
        #fold coverage
        if ($s->target_fold_coverage && $line[FOLD_COVERAGE] 
            && ($s->target_fold_coverage == $line[FOLD_COVERAGE])){
            $Opt{verbose} && print "fold coverage OK\t"; 
        }
        elsif ($s->target_fold_coverage && $line[FOLD_COVERAGE] 
            && ($s->target_fold_coverage != $line[FOLD_COVERAGE])){
            $Opt{verbose} && print "fold coverage NOT_OK\t";    
            if ($Opt{override_db}){
                $s->target_fold_coverage($line[FOLD_COVERAGE]); 
            }
        }
        elsif (!$s->target_fold_coverage && $line[FOLD_COVERAGE]){
                $s->target_fold_coverage($line[FOLD_COVERAGE]); 
        }
        else {
            $Opt{verbose} && print "fold coverage not available \t"; 
        }
		
		#due date
		  if ($s->due_date && $line[DUE_DATE] 
            && ($s->due_date eq $line[DUE_DATE])){
            $Opt{verbose} && print "due date OK\t"; 
        }
        elsif ($s->due_date && $line[DUE_DATE] 
            && ($s->due_date ne $line[DUE_DATE])){
            $Opt{verbose} && print "due date NOT_OK\t";    
            if ($Opt{override_db}){
                $s->due_date($line[DUE_DATE]); 
            }
        }
        elsif (!$s->due_date && $line[DUE_DATE]){
                $s->due_date($line[DUE_DATE]); 
        }
        else {
            $Opt{verbose} && print "due date not available \t"; 
        }
        #sample name 
        if ($s->sample_name && $line[SAMPLE_NAME] 
            && ($s->sample_name eq $line[SAMPLE_NAME])){
            $Opt{verbose} && print "$sample_barcode  sample name OK\t"; 
        }
        elsif ($s->sample_name && $line[SAMPLE_NAME] 
            && ($s->sample_name ne $line[SAMPLE_NAME])){
            $Opt{verbose} && print " $sample_barcode sample name NOT_OK\t";    
            if ($Opt{override_db}){
                $s->sample_name($line[SAMPLE_NAME]); 
            }
        }
        elsif (!$s->sample_name && $line[SAMPLE_NAME]){
                $s->sample_name($line[SAMPLE_NAME]); 
                print "$sample_barcode  : sample_name available\n";
        }
        else {
            $Opt{verbose} && print "$sample_barcode sample name not available\t"; 
        } 
        
        #comment 
        if ($s->comment && $line[COMMENT] 
            && ($s->comment eq $line[COMMENT])){
            $Opt{verbose} && print "comment OK\t"; 
        }
        elsif ($s->comment && $line[COMMENT] 
            && ($s->comment ne $line[COMMENT])){
            $Opt{verbose} && print " comment NOT_OK\t";    
            if ($Opt{override_db}){
                $s->comment($line[COMMENT]); 
            }
        }
        elsif (!$s->comment && $line[COMMENT]){
                $s->comment($line[COMMENT]); 
                print "comment available\t";
        }
        else {
            #print "comment not available\t"; 
        } 
        #cancer
        if ($s->cancer && $line[CANCER] 
            && ($s->cancer eq $line[CANCER])){
            $Opt{verbose} && print "cancer OK\t"; 
        }
        elsif ($s->cancer && $line[CANCER] 
            && ($s->cancer ne $line[CANCER])){
            $Opt{verbose} && print " cancer NOT_OK\t";    
            if ($Opt{override_db}){
                $s->cancer($line[CANCER]); 
            }
        }
        elsif (!$s->cancer && $line[CANCER]){
                $s->cancer($line[CANCER]); 
                print "cancer available : $sample_barcode \n";
        }
        else {
            #print "cancer not available\t"; 
        } 
        #analysis update
		if ($s->analysis && $line[ANALYSIS] &&
			($s->analysis eq $line[ANALYSIS])){
			$Opt{verbose} && print "analysis ok\t"; 
		}
		elsif ($s->analysis && $line[ANALYSIS] &&
			($s->analysis ne $line[ANALYSIS])){
			print "analysis NOT_OK\t". $line[PLATE_BARCODE] . "\n"; 			
			if ($Opt{override_db}){
                $s->analysis($line[ANALYSIS]); 
            }
		}
		elsif (!$s->analysis && $line[ANALYSIS]){
			$s->analysis($line[ANALYSIS]); 
		}
		else {
			## not available
		}
		if ($s->match_sample_ids && $line[MATCH_PAIR]){
			my $match_bc= &validate_sample_barcode($line[MATCH_PAIR]); 
			if (!$match_bc){
				print "invalid barcode ". $line[MATCH_PAIR]  ."\n"; 
			}
			else {
				my @sample_p = Illumina::WGS::Sample->search(sample_barcode => $match_bc); 
				if (!@sample_p){
					print "PROBLEM !!! not known : ". $match_bc . "\n"; 
					next; 
				}
				if ($s->match_sample_ids == $sample_p[0]->sample_id){
					$Opt{verbose} && print "match sample id  ok\t"; 
				}
				elsif ($s->match_sample_ids != $sample_p[0]->sample_id){
					print "MATCH SAMPLE id NOT_OK\t". $sample_barcode . "next\n"; 			
					next; 
				}
				else {
					#do nothing
				}
			}
		}
		elsif ($line[MATCH_PAIR] 
		&& !($line[MATCH_PAIR] eq 'N/A' 
		|| $line[MATCH_PAIR] eq 'NONE' 
		|| $line[MATCH_PAIR] eq 'NA')){
			my $match_bc= &validate_sample_barcode($line[MATCH_PAIR]); 
			if (!$match_bc){
				print "invalid barcode ". $line[MATCH_PAIR]  ."\n"; 
			}
			else {
				my @sample_p = Illumina::WGS::Sample->search(sample_barcode => $match_bc); 
				if (!@sample_p){
					print "known known yet. may have to run twice the import: ". $match_bc . "\n"; 
					next; 
				}
				else {
					$s->match_sample_ids($sample_p[0]->sample_id); 
				}
			}
		}
        push @already_stored, $s; 
    }    
    #print "\n"; 
}
close FH; 


if ($Opt{now}){    
	foreach my $p (@parsed){
		my $s = Illumina::WGS::Sample->create($p); 
	}

	foreach my $s (@already_stored){
		my $x = $s->update(); 
	}    
}
else {
	foreach my $s (@already_stored){
		$s->discard_changes; 
	}    
	print "DRY RUN\n"; 
}


sub process_commandline {
	GetOptions(
		\%Opt, qw(
        debug
        now
        verbose
        manual
        version
        override_db
        help
		  )
	) || pod2usage(0);
	if ( $Opt{manual} ) { pod2usage( verbose => 2 ); }
	if ( $Opt{help} )   { pod2usage( verbose => $Opt{help} - 1 ); }
	if ( $Opt{version} ) { die "import_manifest.pl, ", q$Revision:  $, "\n"; }
    !$ARGV[0] && pod2usage; 
}


sub validate_sample_barcode {
	my $s = shift; 
	$s =~ s/[^[:print:]]+//g;
    $s =~ s/-CSS.*//; 
	$s =~ s/[^A-Z0-9_-]*//g; 
    $s =~ s/\s//g; 
	if ($s =~ /^SS6\d{6}$/){
         $Opt{verbose} && print " STS lims ok \t";
    }
    elsif ($s =~ /^LP\d{7}-DNA_[A-H][0-1][0-9]$/){
        $Opt{verbose} && print "solex lims ok \t"; 
    }
    elsif ($s =~ /^NA\d{5}$/){
	$Opt{verbose} && print "coriel ok \t";
    }
    elsif ($s =~ /^PG\d{7}$/){
        $Opt{verbose} && print "clia ok \t";
    }
    elsif ($s =~ /^VAL\d{7}$/){
        $Opt{verbose} && print "clia ok \t";
    }
    else {
        print "$s: LIMS barcode not recognized\n";
        return 0; 
    }
	return $s; 
}

=head1 NAME

import_manifest.pl import master manifest creating samples

=head1 USAGE

import_sample_manifest.pl -manifest file.txt [-override_db]  

=cut

#read all projects from the database


