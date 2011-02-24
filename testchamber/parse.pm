package parse;
use strict;

#####
#
#####
sub sentence {
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
sub alignment {
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
sub xmlTagFields {
	my $str = shift;
	my $resultHash = {};
	
	while ($str =~ /^\s+([^=[:space:]]+)="([^"]+)"(.*)\s*$/) {
		my $fieldName = $1;
		my $fieldValue = $2;
		$str = $3;
		
		#in case the field value includes a \"
		while ($fieldValue =~ /\\$/) {
			if ($str =~ /([^"]*)"(.*)\s*$/) {
				$fieldValue .= "\"" . $1;
				$str = $2;
			}
			else {
				die("Failed to parse a field value with a double quote inside: `$str'");
			}
		}
		
		$resultHash->{$fieldName} = $fieldValue;
	}
	
	if ($str !~ /^\s*$/) {
		die ("String left-overs from parsing xml tag fields: `$str'");
	}
	
	return $resultHash;
}

#####
#
#####
sub xml {
	my $str = shift;
	
	$str =~ s/\n//g;
	$str =~ s/\/(>\s*)$/$1/g;
	
	if ($str =~ /^\s*<\s*(\S+)(.*)>\s*$/) {
		my $tagId = $1;
		my $fieldStr = $2;
		
		return {'id' => $tagId,
			'fields' => xmlTagFields($fieldStr) };
	}
	elsif ($str =~ /^\s*$/) {
		return undef;
	}
	else {
		die("Failed to parse XML from string `$str'");
	}
}

#####
#
#####
sub parseFlaggTokFlags {
	my $flagStr = shift;
	
	my $isMissingRef = undef;
	my $pos = undef;
	my $isWrongHyp = undef;
	
	my $flags = {};
	
	if ($flagStr ne "") {
		my @flagList = split(/::/, $flagStr);
		
		for my $flag (@flagList) {
			if ($flag eq "neg") {
				$flag = "form";
			}
			$flags->{$flag} = 1;
			
			if ($flag =~ /^miss(.)$/) {
				$pos = $1;
				$isMissingRef = 1;
			}
			else {
				$isWrongHyp = 1;
			}
		}
	}
	
	if ($isMissingRef and $isWrongHyp) {
		die("Conflicting flags for `$flagStr': cannot tag word as missing and erroneous at the same time");
	}
	
	return ($flags, $pos);
}

#####
#
#####
sub flagg {
	my ($snt) = @_;
	
	$snt =~ s/\n//g;
	
	my $missHash = {};
	my $hypErrList; #[ { 'factors' => [], 'flags' => [] } ]
	
	for my $token (split(/ +/, $snt)) {
		if ($token =~ /^(([^ :]+::)*)([^ ]+)$/) {
			my $tokStr = $3;
			my $flagStr = $1;
			
			my ($flags, $pos) = parseFlaggTokFlags($flagStr);
			
			if ($pos) {
				$missHash->{"$tokStr|$pos"}++;
			}
			else {
				push @$hypErrList, { 'factors' => [$tokStr], 'flags' => $flags };
			}
		}
		else {
			die("Failed to parse `$token' into a token");
		}
	}
	
	return { 'hyp' => $hypErrList, 'missed' => $missHash };
}

1;
