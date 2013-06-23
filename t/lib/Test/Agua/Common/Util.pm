package Test::Agua::Common::Util;
use Moose::Role;
use Method::Signatures::Simple;

use Test::More;
use Test::DatabaseRow;
use Data::Dumper;

#### SETUP
method setUpDirs ($sourcedir, $targetdir) {
	$self->logCaller("");
	$self->logNote("sourcedir", $sourcedir);
	$self->logNote("targetdir", $targetdir);

	$self->logNote("rm -fr $targetdir");
	`rm -fr $targetdir`;
	$self->logNote("cp -r $sourcedir $targetdir");
	`cp -r $sourcedir $targetdir`;
	
	$self->logError("Can't find targetdir: $targetdir") and exit if not -d $targetdir;

	#### REDIRECT STDERR TO MASK 'No such file or directory' ERROR
	my $olderr;
	open $olderr, ">&STDERR";	
	open(STDERR, ">/dev/null") or die "Can't redirect STDERR to /dev/null\n";
	
	my $command = 	"cd $targetdir; find . -type d -exec chmod 0755 {} \\;; find . -type f -exec chmod 0644 {} \\;;";
	$self->logNote("command", $command);
	`$command`;
	
	#### RESTORE STDERR
	open STDERR, ">&", $olderr;
}

method setUpFile ($sourcefile, $targetfile) {
	#$self->logNote("") if $self->can('logNote');
	`cp $sourcefile $targetfile`;
	`chmod 644 $targetfile`;	
}


#### COMPARISON
method diff ($sourcefile, $targetfile) {
	$self->logNote("sourcefile not defined") and return 0 if not defined $sourcefile;
	$self->logNote("targetfile not defined") and return 0 if not defined $targetfile;
	$self->logNote("sourcefile not found") and return 0 if not -f $sourcefile;
	$self->logNote("targetfile not defined") and return 0 if not -f $targetfile;
	my $diff = `diff -wb $sourcefile $targetfile`;
	
	return 1 if $diff eq "";
	
	return 0;
}

method identicalArray ($actuals, $expecteds) {
	return 1 if not defined $actuals and not defined $expecteds;
	return 0 if defined $actuals xor defined $expecteds;
	return 0 if scalar(@$actuals) != scalar(@$expecteds);
	for ( my $i = 0; $i < @$actuals; $i++ ) {
		return 0 if $$actuals[$i] ne $$expecteds[$i];
	}

	$self->logNote("returning 1");
	return 1;
}

#### FILES
method listFiles ($directory) {
	opendir(DIR, $directory) or $self->logNote("Can't open directory", $directory);
	my $files;
	@$files = readdir(DIR);
	closedir(DIR) or $self->logNote("Can't close directory", $directory);

	for ( my $i = 0; $i < @$files; $i++ ) {
		if ( $$files[$i] =~ /^\.+$/ ) {
			splice @$files, $i, 1;
			$i--;
		}
	}

	for ( my $i = 0; $i < @$files; $i++ ) {
		my $filepath = "$directory/$$files[$i]";
		if ( not -f $filepath ) {
			splice @$files, $i, 1;
			$i--;
		}
	}

	return $files;
}

method printFile ($outfile, $contents) {
	$self->logError("outfile not defined") if not defined $outfile;

	open(OUT, ">$outfile") or die "Can't open outfile: $outfile\n";
	print OUT $contents;
	close(OUT);
}


1;
