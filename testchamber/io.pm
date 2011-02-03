package io;
use strict;

#####
#
#####
sub noRead {
	die("Failed to open `" . $_[0] . "' for reading");
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
sub openMany {
	my @fhs = ();
	for my $file (@_) {
		push @fhs, openRead($file);
	}
	return @fhs;
}

#####
#
#####
sub closeMany {
	for my $fh (@_) {
		close($fh);
	}
}

#####
#
#####
sub getWordFactor {
	my ($word, $factor) = @_;
	
	my $result = $word->[$factor];
	
	unless ($result) {
		$result = $word->[0];
	}
	
	return $result;
}

#####
#
#####
sub parseSentence {
	my ($string, $caseSensitive) = @_;
	my @result;
	
	if (!$caseSensitive) {
		$string = lc($string);
	}
	
	my @tokens = split(/ /, $string);
	
	for my $token (@tokens) {
		push @result, [ split(/\|/, $token) ];
	}
	
	return \@result;
}

#####
#
#####
sub parseAlignment {
	my $string = shift;
	my @result;
	
	my @tokens = split(/ /, $string);
	
	for my $token (@tokens) {
		my @alPts = split(/-/, $token);
		
		unless (scalar @alPts == 2) {
			die("Alignment points expected to be formatted as `idx-idx'");
		}
		
		unless ($alPts[0] =~ /^[0-9]+$/ and $alPts[1] =~ /^[0-9]+$/) {
			die("Alignment point indexes should be non-negative numeric");
		}
		
		push @result, { 'hyp' => $alPts[0], 'ref' => $alPts[1] };
	}
	
	return \@result;
}

#####
#
#####
sub readSentence {
	my $fh = shift;
	
	my $string = <$fh>;
	
	if ($string) {
		$string =~ s/\n//g;
		$string =~ s/[ \t]{2,}/ /g;
		$string =~ s/^ //g;
		$string =~ s/ $//g;
		
		return $string;
	}
	else {
		return undef;
	}
}

#####
#
#####
sub readSentences {
	my @fhArr = @_;
	my @sntArr = ();
	
	my $allFinished = 1;
	my $allSucceeded = 1;
	
	for my $fh (@fhArr) {
		my $snt = readSentence($fh);
		
		if (defined($snt)) {
			$allFinished = undef;
		}
		else {
			$allSucceeded = undef;
		}
		
		push @sntArr, $snt;
	}
	
	if ($allSucceeded) {
		return \@sntArr;
	}
	elsif ($allFinished) {
		return undef;
	}
	else {
		die("Unequal number of lines in the input files");
	}
}

#####
#
#####
sub hashFactors {
	my ($snt, $alFactor) = @_;
	
	#make a hash/bag of ref word factors
	my $result = {};
	for my $w (@$snt) {
		$result->{getWordFactor($w, $alFactor)} = 1;
	}
	
	return $result;
}

#####
#
#####
sub str4xml {
	my $str = shift;
	
	$str =~ s/"/\\"/g;
	
	return $str;
}

#####
#
#####
sub tok2str4xml {
	my ($token) = @_;
	
	return str4xml(join("|", @$token));
}

1;
