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
use ordersim;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my ($srcfile, $reffile, $hypfile, $alifile, $caseSensitive, $orderSimMethod) =
	processInputArgsAndOpts();

my ($fhSrc, $fhRef, $fhHyp, $fhAli) = io::openMany($srcfile, $reffile, $hypfile, $alifile);
my $tuple;
my $cnt = counter::init();

while($tuple = io::readSentences($fhSrc, $fhRef, $fhHyp, $fhAli)) {
	my $srcSnt = io::parseSentence($tuple->[0], $caseSensitive);
	my $refSnt = io::parseSentence($tuple->[1], $caseSensitive);
	my $hypSnt = io::parseSentence($tuple->[2], $caseSensitive);
	my $alignment = io::parseAlignment($tuple->[3]);
	
	displayErrors($cnt->{'val'}, $srcSnt, $refSnt, $hypSnt, $alignment, $orderSimMethod);
	
	counter::update($cnt);
}

counter::finish($cnt);

io::closeMany($fhRef, $fhHyp);

#####
#
#####
sub processInputArgsAndOpts {
	my ($caseSensitive, $orderSimMethod);
	
	GetOptions('c' => \$caseSensitive, 'd=s' => \$orderSimMethod);
	
	if ($orderSimMethod) {
		ordersim::testMethodId($orderSimMethod);
	}
	else {
		$orderSimMethod = ordersim::getDefaultMethod();
	}
	
	my ($srcfile, $reffile, $hypfile, $alifile) = @ARGV;

	if (!$srcfile or !$alifile or !$reffile or !$hypfile) {
		die("Required arguments: source file, reference file, hypothesis file, alignment file");
	}
	
	return ($srcfile, $reffile, $hypfile, $alifile, $caseSensitive, $orderSimMethod);
}

#####
#
#####
sub displayErrors {
	my ($sntIdx, $srcSnt, $refSnt, $hypSnt, $al, $orderSimMethod) = @_;
	
	sntStart($sntIdx);
	sntInfo($srcSnt, $refSnt, $hypSnt, $al);
	
	#incorrect (not in ref)
	displayIncorrectHypTokens($srcSnt, $hypSnt, $al);
	
	#missing (not in hyp)
	displayMissingRefTokens($refSnt, $al);
	
	#matched, not same (like same lemma, wrong surface form)
	displayMatchedUnequalTokens($refSnt, $hypSnt, $al);
	
	#word/phrase order
	ordersim::display($refSnt, $hypSnt, $al, $orderSimMethod);
	
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
	
	my $printedSome = undef;
	
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
			my $rawRefToken = io::tok2str4xml($refToken);
			my $rawHypToken = io::tok2str4xml($hypToken);
			my $uneqFactorList = join(",", @uneqFactors);
			
			if (!$printedSome) {
				print "\n";
				$printedSome = 1;
			}
			
			print "\t<unequalAlignedTokens hypToken=\"$rawHypToken\" refToken=\"$rawRefToken\" " .
				"unequalFactorList=\"$uneqFactorList\"/>\n";
		}
	}
}

#####
#
#####
sub displayMissingRefTokens {
	my ($refSnt, $al) = @_;
	
	my $alHash = hashAlignment($al, 'ref');
	
	my $printedSome = undef;
	
	for my $i (0..$#$refSnt) {
		if (!$alHash->{$i}) {
			my $surfForm = io::str4xml($refSnt->[$i]->[0]);
			my $rawToken = io::tok2str4xml($refSnt->[$i]);
			
			if (!$printedSome) {
				print "\n";
				$printedSome = 1;
			}
			
			print "\t<missingRefWord idx=\"$i\" " .
				"surfaceForm=\"$surfForm\" " . 
				"rawToken=\"$rawToken\"";
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
	
	my $printedSome = undef;
	
	for my $i (0..$#$hypSnt) {
		if (!$alHash->{$i}) {
			my $surfForm = io::str4xml($hypSnt->[$i]->[0]);
			my $rawToken = io::tok2str4xml($hypSnt->[$i]);
			
			if (!$printedSome) {
				print "\n";
				$printedSome = 1;
			}
			
			my $tagId = ($srcHash->{$surfForm})? "untranslated": "extra";
			
			print "\t<" . $tagId . "HypWord idx=\"$i\" " .
				"surfaceForm=\"$surfForm\" " . 
				"rawToken=\"$rawToken\"/>\n";
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
