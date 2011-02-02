#!/usr/bin/perl
use strict;
use File::Spec;
use Getopt::Long;

BEGIN {
	#include packages from same folder where the
	#script is, even if launched from elsewhere
	
	my @dirs = File::Spec->splitdir(File::Spec->rel2abs(File::Spec->canonpath($0)));
	pop @dirs;
	push(@INC, File::Spec->catdir(@dirs));
}

use io;
use counter;
use unscramble;

binmode(STDOUT, ":utf8");

my ($srcfile, $reffile, $hypfile, $alifile, $caseSensitive) =
	processInputArgsAndOpts();

my ($fhSrc, $fhRef, $fhHyp, $fhAli) = io::openMany($srcfile, $reffile, $hypfile, $alifile);
my $tuple;
my $cnt = counter::init();

while($tuple = io::readSentences($fhSrc, $fhRef, $fhHyp, $fhAli)) {
	my $srcSnt = io::parseSentence($tuple->[0], $caseSensitive);
	my $refSnt = io::parseSentence($tuple->[1], $caseSensitive);
	my $hypSnt = io::parseSentence($tuple->[2], $caseSensitive);
	my $alignment = io::parseAlignment($tuple->[3]);
	
	displayErrors($cnt->{'val'}, $srcSnt, $refSnt, $hypSnt, $alignment);
	
	counter::update($cnt);
}

counter::finish($cnt);

io::closeMany($fhRef, $fhHyp);

#####
#
#####
sub processInputArgsAndOpts {
	my $caseSensitive;
	
	GetOptions('c' => \$caseSensitive);
	
	my ($srcfile, $reffile, $hypfile, $alifile) = @ARGV;

	if (!$srcfile or !$alifile or !$reffile or !$hypfile) {
		die("Required arguments: source file, reference file, hypothesis file, alignment file");
	}
	
	return ($srcfile, $reffile, $hypfile, $alifile, $caseSensitive);
}

#####
#
#####
sub displayErrors {
	my ($sntIdx, $srcSnt, $refSnt, $hypSnt, $al) = @_;
	
	sntStart($sntIdx);
	sntInfo($srcSnt, $refSnt, $hypSnt, $al);
	
	#incorrect (not in ref)
	displayIncorrectHypTokens($srcSnt, $hypSnt, $al);
	
	#missing (not in hyp)
	displayMissingRefTokens($refSnt, $al);
	
	#matched, not same (like same lemma, wrong surface form)
	displayMatchedUnequalTokens($refSnt, $hypSnt, $al);
	
	#word/phrase order
	displayOrderErrors($refSnt, $hypSnt, $al);
	
	sntFinish();
}

#####
#
#####
sub hashAlignment {
	my ($al, $id) = @_;
	my $result = {};
	
	for my $pair (@$al) {
		$result->{$pair->{$id}} = 1;
	}
	
	return $result;
}

#####
#
#####
sub max {
	my ($a, $b) = @_;
	
	return ($a < $b)? $b: $a;
}

#####
#
#####
sub displayMatchedUnequalTokens {
	my ($refSnt, $hypSnt, $al) = @_;
	
	for my $pair (@$al) {
		my $hypToken = $hypSnt->[$pair->{'hyp'}];
		my $refToken = $refSnt->[$pair->{'ref'}];
		
		my @uneqFactors = ();
		
		my $maxidx = max($#$hypToken, $#$refToken);
		for my $i (0..$maxidx) {
			my $hypFact = io::getWordFactor($hypToken, $i);
			my $refFact = io::getWordFactor($refToken, $i);
			
			if ($hypFact ne $refFact) {
				push @uneqFactors, $i;
			}
		}
		
		if (@uneqFactors > 0) {
			my $rawRefToken = join("|", @$refToken);
			my $rawHypToken = join("|", @$hypToken);
			my $uneqFactorList = join(",", @uneqFactors);
			print "\t<unequal_aligned_tokens hyp_token=\"$rawHypToken\" ref_token=\"$rawRefToken\" " .
				"unequal_factor_list=\"$uneqFactorList\"/>\n";
		}
	}
}

#####
#
#####
sub displayMissingRefTokens {
	my ($refSnt, $al) = @_;
	
	my $alHash = hashAlignment($al, 'ref');
	
	for my $i (0..$#$refSnt) {
		if (!$alHash->{$i}) {
			my $surfForm = $refSnt->[$i]->[0];
			my $rawToken = join("|", @{$refSnt->[$i]});
			
			print "\t<missing_ref_word idx=\"$i\" " .
				"surface_form=\"$surfForm\" " . 
				"raw_token=\"$rawToken\"";
			print "/>\n";
		}
	}
}

#####
#
#####
sub displayIncorrectHypTokens {
	my ($srcSnt, $hypSnt, $al) = @_;
	
	my $srcHash = io::hashFactors($srcSnt, 0);
	my $alHash = hashAlignment($al, 'hyp');
	
	for my $i (0..$#$hypSnt) {
		if (!$alHash->{$i}) {
			my $surfForm = $hypSnt->[$i]->[0];
			my $rawToken = join("|", @{$hypSnt->[$i]});
			
			print "\t<incorrect_hyp_word idx=\"$i\" " .
				"surface_form=\"$surfForm\" " . 
				"raw_token=\"$rawToken\"";
			if ($srcHash->{$surfForm}) {
				print " untranslated=\"yes\"";
			}
			print "/>\n";
		}
	}
}

#####
#
#####
sub getHypRefAlMap {
	my ($al) = @_;
	
	my @result = ();
	
	for my $pt (@$al) {
		$result[$pt->{'ref'}] = $pt->{'hyp'};
	}
	
	return \@result;
}

#####
#
#####
sub displayOrderErrors {
	my ($refSnt, $hypSnt, $al) = @_;
	
	my $permList = unscramble::getListOfPermutations($al);
	
	my $hypIdxMap = getHypRefAlMap($al);
	
	for my $permutation (@$permList) {
		if ($permutation->{'switch'}) {
			print "switched positions " . $permutation->{'from'} . " and " . $permutation->{'to'} .
				", hyp idxs " . $hypIdxMap->[$permutation->{'refidx1'}] . " and " . $hypIdxMap->[$permutation->{'refidx2'}] . ";\n";
		}
		else {
			print "shifted hyp idx " . $hypIdxMap->[$permutation->{'refidx'}] . " from " . $permutation->{'from'} .
				" to " . $permutation->{'to'} . ";\n";
		}
	}
}

#####
#
#####
sub sntStart {
	my $idx = shift;
	print "<sentence index=\"$idx\">\n";
}

#####
#
#####
sub sntFinish {
	print "</sentence>\n\n";
}

#####
#
#####
sub sntInfo {
	my ($srcSnt, $refSnt, $hypSnt, $al) = @_;
	
	my $numOfAligned = scalar @$al;
	
	print "\t<source length=\"" . scalar @$srcSnt . "\"/>\n";
	print "\t<reference length=\"" . scalar @$refSnt . "\" aligned=\"$numOfAligned\"/>\n";
	print "\t<hypothesis length=\"" . scalar @$hypSnt . "\" aligned=\"$numOfAligned\"/>\n";
}
