package Xy::Common::Flowcell;
use Moose::Role;
use Moose::Util::TypeConstraints;


use lib '../lib'; 
use lib '../extlib/lib/perl5';
use Carp;

use Data::Dumper;
use File::Spec::Functions;  
use File::stat;
use Time::localtime;
use Illumina::WGS::Flowcell; 
use Illumina::WGS::FlowcellReport; 
use Illumina::WGS::FlowcellHistory; 
use Illumina::WGS::Status; 
use SaffronApp::SampleSheet; 
use Illumina::WGS::Sample; 
use List::MoreUtils qw( uniq ); 
use POSIX 'strftime'; 



my $hr_status2id = Illumina::WGS::Status->hasref_status2id;
my $hr_id2status = Illumina::WGS::Status->hashref_id2status;


sub search_form : StartRunMode {
    my $self = shift; 
    my $template = $self->load_tmpl('flowcell_search_form.tmpl');
	my $layout = $self->load_tmpl('layout.tmpl');
	$layout->param('content', $template->output()); 
	return $layout->output(); 
}

sub search : RunMode {
    my $self = shift; 
    my $q = $self->query();
	my @allow = qw/ flowcell_id status_id flowcell_barcode fc_name /; 
	my $all = $q->param('all'); 
	my $fc_name = $q->param('fc_name'); 
	my @flowcells; 
	if ($all){
		@flowcells = Illumina::WGS::Flowcell->retrieve_all;
	}
	elsif ($fc_name) {
		@flowcells = Illumina::WGS::Flowcell->search_like(location => '%'.$fc_name. '%'); 
		!@flowcells && return "nothing found". $self->search_form; 
	}
	else {
		my %ha; 
		foreach my $al (@allow){
			next unless defined $q->param($al); 
			$ha{$al} = $q->param($al); 
		}
		@flowcells = Illumina::WGS::Flowcell->search(%ha); 
	}
	!@flowcells && return "nothing found". $self->search_form; 
	$self->_return_list(\@flowcells); 
}


sub _return_list {
	my $self = shift;
	my $temp = shift; 
	my @t = @{$temp}; 
	my @rows; 
	foreach my $s (@t){
		my @locs = split /\//,  $s->location; 
		my $loc = $locs[-1]; 
	
		### samplesheet
		my @samplesheet = Illumina::WGS::SampleSheet->search(flowcell_id => $s->flowcell_id); 
		my $c_lanes=@samplesheet ?  scalar @samplesheet : undef; 
		#can add other stats like current cycle etc
		my @report = Illumina::WGS::FlowcellReport->search(flowcell_id => $s->flowcell_id);
		my @cycles =  map {$_->qscore_cycle} @report;
		my $ccycle; 
		if (@cycles){
			my @ds= sort @cycles; 
			$ccycle = shift @ds; 
		}	
		my %h = (
			flowcell_id => $s->flowcell_id, 
			location => $loc, 
			fc_status => $hr_id2status->{$s->status_id} , 
			min_qscore_cycle => $ccycle ? $ccycle : 'NA', 
			machine => $s->machine_name, 
			flowcell_position => join(",",  uniq map {$_->flowcell_position}  @report), 
			date_started => join(",",  uniq map {$_->date}  @report), 
			lane_count => $c_lanes
		);
		push @rows, \%h;
	}
	my $template = $self->load_tmpl('flowcell_list.tmpl');       
	$template->param('flowcells', \@rows); 
	my $layout = $self->load_tmpl('layout.tmpl');
	$layout->param('content', $template->output()); 
	return $layout->output(); 
}


sub details : RunMode {
    my $self = shift; 
    my $q = $self->query(); 
    my $fc_id = $q->param('flowcell_id'); 
    !$fc_id && return "no fc_id passed " . $self->search_form; 
	my $fc = Illumina::WGS::Flowcell->retrieve($fc_id);
	my @columns = $fc->columns;
	my @rows;  
	foreach my $c (@columns){
		next if $c =~ /operator|run_start_date|priority|md5sum/; 
		if ($c =~ /status_id|fail_code_id/){
			my $ca= $c; 
			$c =~ s/_id//; 
			my %h = (  
				key => $c, 
				value => $hr_id2status->{$fc->$ca}
			); 
			push @rows, \%h; 
			next; 
		}
		my %h = (
				key =>  $c, 
				value => $fc->$c
		);
		push @rows, \%h;  
	}
	#can add other stats like current cycle etc
	 
	my @fc_hist = Illumina::WGS::FlowcellHistory->search(flowcell_id => $fc_id); 
	my @hrows; 
	foreach my $h (@fc_hist){
		my %h = (
			update_timestamp => $h->update_timestamp,
			flowcell_history_id => $h->flowcell_history_id, 
			hist_status => $hr_id2status->{$h->status_id}, 
			comments => $h->comments, 
			user_code_and_ip => $h->user_code_and_ip
		); 
		push @hrows, \%h;
	}
	#flowcell report 
	my @reports = Illumina::WGS::FlowcellReport->search(flowcell_id => $fc_id);
	my @fcreports; 
	my $samplesheet_ok=0;
	foreach my $r (sort {$a->lane <=> $b->lane} @reports){
		my @ssl  = Illumina::WGS::SampleSheet->search(flowcell_id => $fc_id, lane => $r->lane); 
		my $sample_barcode= 'NA'; 
		my $project_name = 'NA'; 
		my $sample_id = undef; 
		my $project_id = undef; 
		if (@ssl){
			$samplesheet_ok++; 
			my $ss=$ssl[0]; 
			my $sample = Illumina::WGS::Sample->retrieve($ss->sample_id);
			my $project = Illumina::WGS::Project->retrieve($sample->project_id);
			my $label='U';
			if ($sample  && $sample->gt_gender){
				if ($sample->gt_gender eq 'M'){
					$label = 'XY';
				}
				else {
					$label = 'XX';
				}
			}
			$sample_barcode = $sample->sample_barcode; 
			$project_name = $project->project_name; 
			$sample_id = $sample->sample_id; 
			$project_id = $project->project_id; 
		}
		my  %hash = ( 	
			lane => $r->lane,
			sample_barcode =>  $sample_barcode,
			sample_id => $sample_id , 
			project_name =>  $project_name, 
			project_id => $project_id, 
		);  
	
		my @cols = qw/ extract_cycle qscore_cycle phasing_read1 prephasing_read1 phasing_read2 
		prephasing_read2 cluster_density_raw cluster_density_pf 
		clusters_raw clusters_per_pf read1_phiX_error_rate read2_phiX_error_rate insert_median insert_sd_low insert_sd_high/; 
		foreach my $c (@cols){
			if ($r->can($c)){; 
				$hash{$c}= $r->$c; 
			}
		}
        push @fcreports, \%hash;
	}

	my $temphist = $self->load_tmpl('flowcell_history_list.tmpl');
	$temphist->param('flowcells', \@hrows);
	my $template = $self->load_tmpl('flowcell_details.tmpl');	
	if ($samplesheet_ok != scalar @reports){
		$template->param('enable_ss_upload',1); 
	}
	my $fcreport_tmpl = $self->load_tmpl('flowcell_report_list.tmpl'); 
	$fcreport_tmpl->param('rows', \@fcreports); 
	$template->param('rows',\@rows);  
	$template->param('lane_count', scalar @fcreports); 
	$template->param('flowcell_id',$fc_id);
	my $layout = $self->load_tmpl('layout.tmpl');
	$layout->param('content', $template->output() . $fcreport_tmpl->output(). $temphist->output()); 
	return $layout->output(); 
}
   

sub edit : RunMode {
    my $self = shift;
    my $q = $self->query();
    my $fc_id = $q->param('flowcell_id');
	!$fc_id && return "no fc_id passed " . $self->search_form; 
	my $fc = Illumina::WGS::Flowcell->retrieve($fc_id);
	my $comments = $fc->comments; 
	my @columns = $fc->columns;
	my @rows;
	foreach my $c (@columns){
		next if $c =~ /comments|operator|priority|md5sum|user_code|attempt/; 
		if ($c =~ /status_id|fail_code_id/){
			my $ca= $c;
			$c =~ s/_id//;
			my %h = (
				key => $c,
				value => $hr_id2status->{$fc->$ca}
			);
			push @rows, \%h;
			next;
		}
		my %h = (
				key =>  $c,
				value => $fc->$c
		);
		push @rows, \%h;
	}
	my @fc_hist = Illumina::WGS::FlowcellHistory->search(flowcell_id => $fc_id);
	my @hrows;
	foreach my $h (@fc_hist){
		my %h = (
			update_timestamp => $h->update_timestamp,
			flowcell_history_id => $h->flowcell_history_id,
			fail_code => $hr_id2status->{$h->fail_code_id}, 
			hist_status => $hr_id2status->{$h->status_id},
			comments => $h->comments,
			user_code_and_ip => $h->user_code_and_ip
		);
		push @hrows, \%h;
	}
	my $temphist = $self->load_tmpl('flowcell_history_list.tmpl');
	$temphist->param('flowcells', \@hrows);
	my $template = $self->load_tmpl('flowcell_edit.tmpl');
	$template->param('rows',\@rows);
	$template->param('flowcell_id',$fc_id);
	$template->param('comments', $comments);     
	#codes 
	my @fail_codes; 
	my @cd = qw/
				q30ErrorRate
				ClusterDensity
				Intensity
				Freeze
				ResynthFailure
				Diversity
				HighPhase_PrePhase
				Other/;
	foreach my $f (sort @cd){
		my $selected = ' '; 
		if ($hr_status2id->{$f} == $fc->fail_code_id){
			$selected = ' selected=selected ';
		}
		my %h = (
			value => $hr_status2id->{$f} . $selected, 
			key => $f 
		); 
		push @fail_codes, \%h;              
	}
	my %first = (key => '--choose one--', value=> ''); 
	unshift @fail_codes, \%first; 
	$template->param('fail_codes', \@fail_codes); 
	my $layout = $self->load_tmpl('layout.tmpl');
	$layout->param('content', $template->output() . $temphist->output());
	return $layout->output();
}


sub save  : RunMode {
    my $self = shift; 
    my $q = $self->query();
	my $fc_status_id = $q->param('status_id'); 
    my $fc_id = $q->param('flowcell_id'); 
    my $user = $q->param('user_code_and_ip'); 
    my $newcomment = $q->param('newcomments'); 
    my $fail_code_id = $q->param('fail_code_id'); 
    if (!$fc_id){
        return "unknown $fc_id flowcell"; 
    }
    my $fc = Illumina::WGS::Flowcell->retrieve($fc_id); 
    if ($fail_code_id &&  $hr_id2status->{$fail_code_id} && $fc_status_id && $hr_id2status->{$fc_status_id}){
        $fc->status_id($fc_status_id); 
        $fc->fail_code_id($fail_code_id); 
    }
	else {
		return "you must provide a fail code and a status (fail or to_rehyb) ". $self->edit; 
	}
    my $fc = Illumina::WGS::Flowcell->retrieve($fc_id); 
    $fc->user_code_and_ip($user ? ($user.'/'.$q->remote_host) : $q->remote_host); 
    $fc->comments($newcomment); 
	if ($fc_status_id == 75 ){
		$fc->attempting_rehyb('Y'); 
	}
	$fc->update; 
	return 'updated' . $self->redirect('flowcell.cgi?rm=details&flowcell_id='.$fc_id);
}


1;
