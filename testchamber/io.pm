package io;
use strict;

#####
#
#####
sub openFiles {
	my ($srcfile, $reffile, $hypfile) = @_;
	my $fh = {};
	
	$fh->{'src'} = openRead($srcfile);
	$fh->{'ref'} = openRead($reffile);
	$fh->{'hyp'} = openRead($hypfile);
	
	return $fh;
}

#####
#
#####
sub noRead {
	die("Failed to open `" . $_[0] . "' for reading");
}

#####
#
#####
sub closeFiles {
	my $fh = shift;
	
	close($fh->{'src'});
	close($fh->{'ref'});
	close($fh->{'hyp'});
}

#####
#
#####
sub openRead {
	my $filename = shift;
	
	my $fh;
	
	open($fh, $filename) or noRead($filename);
	binmode($fh, ":utf8");
	
	return $fh;
}

#####
#
#####
sub getSnt {
	my $fh = shift;
	
	my $raw = <$fh>;
	
	if ($raw) {
		$raw =~ s/\n//g;
		$raw =~ s/[ \t]{2,}/ /g;
		$raw =~ s/^ //g;
		$raw =~ s/ $//g;
		
		my @words = split(/ /, $raw);
		
		return \@words;
	}
	else {
		return undef;
	}
}

#####
#
#####
sub readSentences {
	my $fh = shift;
	
	my $srcsnt = getSnt($fh->{'src'});
	my $refsnt = getSnt($fh->{'ref'});
	my $hypsnt = getSnt($fh->{'hyp'});
	
	if ($srcsnt and $refsnt and $hypsnt) {
		return { 'src' => $srcsnt, 'ref' => $refsnt, 'hyp' => $hypsnt };
	}
	elsif (!$srcsnt and !$refsnt and !$hypsnt) {
		return undef;
	}
	elsif (!$srcsnt) {
		die ("Source file ended prematurely");
	}
	elsif (!$refsnt) {
		die ("Reference file ended prematurely");
	}
	elsif (!$hypsnt) {
		die ("Hypothesis file ended prematurely");
	}
	else {
		die ("Well that's really strange");
	}
}

1;
