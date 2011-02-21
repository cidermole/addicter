#!/usr/bin/perl
use strict;
use utf8;

my ($flaggedFile, $tokenizedFile) = @ARGV;

open(FL, $flaggedFile) or die("no flagged");
binmode(FL, ":utf8");
open(TK, $tokenizedFile) or die("no tokenized");
binmode(TK, ":utf8");
binmode(STDOUT, ":utf8");

my $currTokId = "blaaah";
my $tkLine;

while (<FL>) {
	my $flLine = readData($_);
	
	if ($flLine->{'id'} ne $currTokId) {
		my $newstr = <TK>;
		$tkLine = readData($newstr);
		$currTokId = $tkLine->{'id'};
	}
	
	if ($flLine->{'id'} ne $currTokId) {
		my $flId = $flLine->{'id'};
		die("enough is enough (flagged: $flId, tokenized: $currTokId)");
	}
	
	my $lastFlIdx = $#{$flLine->{'hyp'}};
	my $lastTkIdx = $#{$tkLine->{'hyp'}};
	
	my ($tkStartPos, $tkEndPos) = (-1, -1);
	
	my @outputTokens = ();
	
	for my $flPos (0..$lastFlIdx) {
		my $flToken = $flLine->{'hyp'}->[$flPos];
		my $flSurfForm = getSurfForm($flToken);
		
		$tkStartPos = $tkEndPos + 1;
		
		#print "matching token $flPos ($flToken):\n";
		
		my $tkToken;
		
		do {
			$tkEndPos++;
			$tkToken = join("", @{$tkLine->{'hyp'}}[$tkStartPos..$tkEndPos]);
			
			#print "trying $tkStartPos - $tkEndPos ($tkToken)\n";
		} while (!matches($tkToken, $flSurfForm) and $tkEndPos < $lastTkIdx);
		
		if (!matches($tkToken, $flSurfForm)) {
			die("Still `$tkToken' != `$flSurfForm', $currTokId");
		}
		
		push @outputTokens, tokenizeFlagged($flToken, @{$tkLine->{'hyp'}}[$tkStartPos..$tkEndPos]);
		
		#print "ok\n";
	}
	
	print $flLine->{'id'} . "\t" . join(" ", @{$flLine->{'missed'}}) . "\t" . join(" ", @outputTokens) . "\n";
}

close(FL);
close(TK);

#####
#
#####
sub tokenizeFlagged {
	my $rawFlTok = shift;
	$rawFlTok = clean($rawFlTok);
	my @cleanToks = @_;
	my @result;
	
	for my $cleanTok (@cleanToks) {
		my $cleanTokForMatching = clean($cleanTok);
		
		if ($rawFlTok =~ /^(([A-Za-z]+::)*)\Q$cleanTokForMatching\E(.*)$/) {
			my $flags = $1;
			$rawFlTok = $3;
			
			if ($flags =~ /punct::/ and $rawFlTok =~ /^(([A-Za-z]+::)*)([[:punct:]].*)$/) {
				my ($newflags, $remainder) = ($1, $3);
				$flags =~ s/punct:://g;
				$rawFlTok = $newflags . "punct::" . $remainder;
			}
			
			push @result, "$flags$cleanTok";
		}
		else {
			die("bastard $rawFlTok vs $cleanTokForMatching");
		}
	}
	
	return @result;
}

#####
#
#####
sub clean {
	my $str = shift;
	$str =~ s/[„“]/"/g;
	$str =~ s/‚/`/g;
	$str =~ s/‘/'/g;
	$str =~ s/–/-/g;
	$str =~ s/`/'/g;
	return $str;
}

#####
#
#####
sub matches {
	my ($s1, $s2) = @_;
	my ($s1x, $s2x) = (clean($s1), clean($s2));
	
	return ($s1x eq $s2x);
}

#####
#
#####
sub getSurfForm {
	my $rawToken = shift;
	my $result = $rawToken;
	
	$result =~ s/[A-Za-z]+:://g;
	
	return $result;
}

#####
#
#####
sub readData {
	my $str = shift;
	$str =~ s/\n//g;

	#ugly hack
	$str =~ s/2 400/2400/g;
	$str =~ s/2, 1/2,1/g;
	$str =~ s/18, 286.90/18,286.90/g;
	$str =~ s/12, 595.75/12,595.75/g;
	$str =~ s/23, 6/23,6/g;
	$str =~ s/3, 9/3,9/g;
	$str =~ s/([45]00) (000)/$1$2/g;
	
	if ($str =~ /^([0-9]+\t[^ ]+)\t([^\t]*)\t([^\t]*)$/) {
		my ($id, $missedStr, $hypStr) = ($1, $2, $3);
		
		my @missArr = split(/ /, $missedStr);
		
		my @hypToks = split(/ /, $hypStr);
		
		push @missArr, grep(/^miss.::/, @hypToks);
		
		@hypToks = grep(!/^miss.::/, @hypToks);
		
		return { 'id' => $id, 'missed' => \@missArr, 'hyp' => \@hypToks };
	}
	else {
		die("Failed to parse `$str'");
	}
}
