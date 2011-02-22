#!/usr/bin/perl
use strict;
use utf8;

my ($flaggedFile, $tokenizedFile) = @ARGV;

open(FL, $flaggedFile) or die("no flagged");
binmode(FL, ":utf8");
open(TK, $tokenizedFile) or die("no tokenized");
binmode(TK, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

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
		
		#print "matching token $flPos ($flToken/$flSurfForm):\n";
		
		my $tkToken;
		
		do {
			$tkEndPos++;
			$tkToken = join("", @{$tkLine->{'hyp'}}[$tkStartPos..$tkEndPos]);
			
			#print "trying $tkStartPos - $tkEndPos ($tkToken)\n";
		} while (!matches($tkToken, $flSurfForm) and $tkEndPos < $lastTkIdx);
		
		if (!matches($tkToken, $flSurfForm)) {
			die("Still `$tkToken' != `$flSurfForm', $currTokId");
		}
		
		push @outputTokens, tokenizeFlagged($flToken, $flLine->{'missed'}, @{$tkLine->{'hyp'}}[$tkStartPos..$tkEndPos]);
		
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
	my $missList = shift;
	my @cleanToks = @_;
	my @result;
	
	for my $cleanTok (@cleanToks) {
		my $cleanTokForMatching = clean($cleanTok);
		
		if ($rawFlTok =~ /^(([A-Za-z]+::)*)\Q$cleanTokForMatching\E(([A-Za-z]+::)*)(.*)$/) {
			my ($flags, $nextFlags, $nextToks) = ($1, $3, $5);
			
			redistributeFlags($cleanTok, $nextToks, $missList, \$flags, \$nextFlags);
			
			$rawFlTok = $nextFlags . $nextToks;
			
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
sub shiftFlags {
	my $flagsRef = shift;
	my $nextFlagsRef = shift;
	my $removeFromCurrent = shift;
	my @flags = @_;
	
	if (scalar @flags > 0) {
		my $flag = pop @flags;
		
		if ($$flagsRef =~ /($flag)::/ and $$nextFlagsRef !~ /($flag)::/) {
			$$nextFlagsRef .= $flag . "::";
			
			if ($removeFromCurrent) {
				$$flagsRef =~ s/($flag):://g;
			}
		}
		
		shiftFlags($flagsRef, $nextFlagsRef, $removeFromCurrent, @flags);
	}
}

#####
#
#####
sub redistributeFlags {
	my ($cleanTok, $nextToks, $missList, $flagsRef, $nextFlagsRef) = @_;
	
	#tokenization is imposed in this script, so we lose the tag for tokenization errors
	$$flagsRef =~ s/tok:://g;
	
	my $thisTokIsPunct = ($cleanTok =~ /^[[:punct:]]+$/);
	my $nextTokIsEmpty = ($nextToks eq "");
	my $nextTokIsPunct = ($nextToks =~ /^[[:punct:]]/);
	
	if ($nextTokIsEmpty) {
		# punct::word means missing punctuation, shifting it into the missed token list;
		# "missP::???" means unknown punctuation is missing
		if (!$thisTokIsPunct and $$flagsRef =~ /punct::/) {
			push @$missList, "missP::???";
			$$flagsRef =~ s/punct:://g;
		}
	}
	else {
		#extra::XY actually means extra::X and extra::Y
		shiftFlags($flagsRef, $nextFlagsRef, undef, "extra");
	
		if (!$thisTokIsPunct and $nextTokIsPunct) {
			shiftFlags($flagsRef, $nextFlagsRef, 1, "punct");
		}
		elsif ($thisTokIsPunct and !$nextTokIsPunct) {
			#shift everything except "punct::", "extra::" and "miss?::"
			shiftFlags($flagsRef, $nextFlagsRef, 1,
				"case", "form", "neg", "ows", "owl", "ops", "opl", "unk", "lex", "disam", "garbled", "idiom");
		}
	}
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
