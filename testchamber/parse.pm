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
	else {
		die("Failed to parse XML from string `$str'");
	}
}

1;
