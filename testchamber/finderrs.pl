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
use parse;
use counter;
use ordersim;
use const;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my ($srcfile, $reffile, $hypfile, $alifile, $caseSensitive, $outputFormat) =
	processInputArgsAndOpts();

my ($fhSrc, $fhRef, $fhHyp, $fhAli) = io::openMany($srcfile, $reffile, $hypfile, $alifile);
my $tuple;
my $cnt = counter::init();

while($tuple = io::readSentences($fhSrc, $fhRef, $fhHyp, $fhAli)) {
	my $srcSnt = parse::sentence($tuple->[0], $caseSensitive);
	my $refSnt = parse::sentence($tuple->[1], $caseSensitive);
	my $hypSnt = parse::sentence($tuple->[2], $caseSensitive);
	my $alignment = parse::alignment($tuple->[3]);
	
	displayErrors($cnt->{'val'}, $srcSnt, $refSnt, $hypSnt, $alignment, $outputFormat);
	
	counter::update($cnt);
}

counter::finish($cnt);

io::closeMany($fhRef, $fhHyp);

#####
#
#####
sub processInputArgsAndOpts {
	my ($caseSensitive, $outputFormat);
	
	GetOptions('c' => \$caseSensitive, 'f=s' => \$outputFormat);
	
	if (!defined($outputFormat)) {
		$outputFormat = $const::FMT_FLAG;
	}
	
	my ($srcfile, $reffile, $hypfile, $alifile) = @ARGV;

	if (!$srcfile or !$alifile or !$reffile or !$hypfile) {
		die("Required arguments: source file, reference file, hypothesis file, alignment file");
	}
	
	return ($srcfile, $reffile, $hypfile, $alifile, $caseSensitive, $outputFormat);
}

#####
#
#####
sub displayErrors {
	my ($sntIdx, $srcSnt, $refSnt, $hypSnt, $al, $outputFormat) = @_;
	
	my $flaggedHyp = parse::factoredToFlaggable($hypSnt);
	
	if ($outputFormat eq $const::FMT_XML) {
		sntStart($sntIdx);
		sntInfo($srcSnt, $refSnt, $hypSnt, $al);
	}
	
	#incorrect (not in ref)
	displayIncorrectHypTokens($srcSnt, $hypSnt, $al, $outputFormat, $flaggedHyp);
	
	#missing (not in hyp)
	displayMissingRefTokens($refSnt, $al, $outputFormat, $flaggedHyp);
	
	#matched, not same (like same lemma, wrong surface form)
	displayMatchedUnequalTokens($refSnt, $hypSnt, $al, $outputFormat, $flaggedHyp);
	
	#word/phrase order
	ordersim::display($refSnt, $hypSnt, $al, $outputFormat, $flaggedHyp);
	
	if ($outputFormat eq $const::FMT_XML) {
		sntFinish();
	}
	elsif ($outputFormat eq $const::FMT_FLAG) {
		ordersim::displayFlagged($flaggedHyp);
	}
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
	my ($refSnt, $hypSnt, $al, $outputFormat, $flaggedHyp) = @_;
	
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
			
			if ($outputFormat eq $const::FMT_XML) {
				if (!$printedSome) {
					print "\n";
					$printedSome = 1;
				}
				
				print "\t<unequalAlignedTokens hypIdx=\"" . $pair->{'hyp'} .
					"\" hypToken=\"$rawHypToken\" refIdx=\"" . $pair->{'ref'} .
					"\" refToken=\"$rawRefToken\" unequalFactorList=\"$uneqFactorList\"/>\n";
			}
			elsif ($outputFormat eq $const::FMT_FLAG) {
				push @{$flaggedHyp->{'hyp'}->[$pair->{'hyp'}]->{'flags'}}, "form";
			}
		}
	}
}

#####
#
#####
sub displayMissingRefTokens {
	my ($refSnt, $al, $outputFormat, $flaggedHyp) = @_;
	
	my $alHash = hashAlignment($al, 'ref');
	
	my $printedSome = undef;
	
	for my $i (0..$#$refSnt) {
		if (!$alHash->{$i}) {
			#my $surfForm = io::str4xml($refSnt->[$i]->[0]);
			my $surfForm = $refSnt->[$i]->[0];
			my $rawToken = io::tok2str4xml($refSnt->[$i]);
			
			if ($outputFormat eq $const::FMT_XML) {
				if (!$printedSome) {
					print "\n";
					$printedSome = 1;
				}
				
				print "\t<missingRefWord idx=\"$i\" " .
					"surfaceForm=\"" . io::str4xml($surfForm) . "\" " . 
					"token=\"$rawToken\"";
				print "/>\n";
			}
			elsif ($outputFormat eq $const::FMT_FLAG) {
				my $flag;
				
				push @{$flaggedHyp->{'missed'}}, $rawToken;
			}
		}
	}
}

#####
#
#####
sub displayIncorrectHypTokens {
	my ($srcSnt, $hypSnt, $al, $outputFormat, $flaggedHyp) = @_;
	
	my $srcHash = io::hashFactors($srcSnt, 0);
	my $alHash = hashAlignment($al, 'hyp');
	
	my $printedSome = undef;
	
	for my $i (0..$#$hypSnt) {
		if (!$alHash->{$i}) {
			#my $surfForm = io::str4xml($hypSnt->[$i]->[0]);
			my $surfForm = $hypSnt->[$i]->[0];
			my $rawToken = io::tok2str4xml($hypSnt->[$i]);
			
			if ($outputFormat eq $const::FMT_XML) {
				if (!$printedSome) {
					print "\n";
					$printedSome = 1;
				}
				
				my $tagId = ($srcHash->{$surfForm})? "untranslated": "extra";
				
				print "\t<" . $tagId . "HypWord idx=\"$i\" " .
					"surfaceForm=\"" . io::str4xml($surfForm) . "\" " . 
					"token=\"$rawToken\"/>\n";
			}
			elsif ($outputFormat eq $const::FMT_FLAG) {
				my $flag;
				
				push @{$flaggedHyp->{'hyp'}->[$i]->{'flags'}}, (($srcHash->{$surfForm})? "untr": "extra");
			}
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
