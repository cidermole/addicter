package io;
use strict;
use const;

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
	
	if (!$result or $result =~ /^@.*@$/ or $result eq "<unknown>") {
		$result = $word->[0];
	}
	
	return $result;
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

#####
#
#####
sub displayFlagged {
	my $flaggedHyp = shift;
	
	displayFlaggedMissingRef($flaggedHyp);
	
	displayFlaggedHyp($flaggedHyp);
	
	print "\n";
}

#####
#
#####
sub displayFlaggedHyp {
	my $flaggedHyp = shift;
	
	for my $hypWord (@{$flaggedHyp->{'hyp'}}) {
		my $surfForm = $hypWord->{'factors'}->[0];
		
		for my $flag (@{$hypWord->{'flags'}}) {
			print $flag . "::";
		}
		
		print $surfForm . " ";
	}
}

#####
#
#####
sub displayFlaggedMissingRef {
	my $flaggedHyp = shift;
	
	for my $missRefWord (@{$flaggedHyp->{'missed'}}) {
		my @factors = split(/\|/, $missRefWord);
		my $surfForm = $factors[0];
		my $pos = $factors[1];
		my $auxFlag;
		
		if ($pos eq "content" or $pos eq "C") {
			$auxFlag = "C";
		}
		elsif ($pos eq "aux" or $pos eq "A") {
			$auxFlag = "A";
		}
		else {
			$auxFlag = "X";
		}
		
		print "miss" . $auxFlag . "::" . $surfForm . " ";
	}
}

1;
