#!/usr/bin/perl
use strict;
use File::Spec;
use Getopt::Long;

BEGIN {
	# include packages from same folder where the
	# script is, even if launched from elsewhere
	# unshift(), not push(), to give own functions precedence over other libraries
	my @dirs = File::Spec->splitdir(File::Spec->rel2abs(File::Spec->canonpath($0)));
	pop @dirs;
	unshift(@INC, File::Spec->catdir(@dirs));
}

use io;
use parse;
use counter;
use ordersim;
use const;
use flagg;
use math;

sub getUsage {
	# return "Usage: finderrs.pl source.txt hypothesis.txt reference.txt alignment.txt > errorlist.txt\n";
	return "Required arguments: source hypothesis reference alignment [ref-2 ali-2 [ref-3 ali-3 [...]]]\n";
}

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
# Autoflush (useful for debugging)
my $old_fh = select(STDERR);
$| = 1;
select(STDOUT);
$| = 1;
select($old_fh);

my $opts = processInputArgsAndOpts();
my @inputFiles = @ARGV;
my $numOfRefs = ((scalar @inputFiles) - 2) / 2;

#print STDERR "NB! order of input arguments changed to support multiple references\n" . getUsage() . "\n";

my @handles = io::gopenMany(@inputFiles);
my $tuple;
my $cnt = counter::init();

# There must be one root element in the output XML, otherwise the XML::Parser will complain.
print("<document>\n");

while($tuple = io::readSentences(@handles)) {
	my $srcSnt = parse::sentence($tuple->[0], $opts->{'caseSensitive'});
	my $hypSnt = parse::sentence($tuple->[1], $opts->{'caseSensitive'});
	
	my (@refSntArr, @aliArr);
	
	for my $i (0..($numOfRefs-1)) {
		my $refSnt = parse::sentence($tuple->[2 + $i * 2], $opts->{'caseSensitive'});
		my $aliHypRef = parse::alignment($tuple->[2 + $i * 2 + 1], 0, $#$refSnt, $#$hypSnt);
		 
		push @refSntArr, $refSnt;
		push @aliArr, $aliHypRef;
		
		# DZ: Avoid later confusing errors: Check that the alignment indices are consistent with the two aligned sentences.
		foreach my $aliPoint (@{$aliHypRef})
		{
			# Note: parse::alignment() always assumes that left side is hyp and right side is ref.
			if($aliPoint->{'hyp'}>$#{$hypSnt} || $aliPoint->{'ref'}>$#{$refSnt})
			{
				#MF: allow to ignore the out-of-boundary errors
				if ($opts->{'ignoreOutOfBounds'}) {
					print STDERR "alignment point $aliPoint->{hyp}-$aliPoint->{ref} points to nowhere\n";
				}
				else {
					print STDERR ("SRC[0..$#{$srcSnt}]: $tuple->[0]\n");
					print STDERR ("HYP[0..$#{$hypSnt}]: $tuple->[1]\n");
					print STDERR ("REF[0..$#{$refSnt}]: $tuple->[2+$i*2]\n");
					print STDERR ("ALI[HYP-REF]: $tuple->[2+$i*2+1]\n");
					die("Alignment point $aliPoint->{hyp}-$aliPoint->{ref} points to nowhere");
				}
			}
		}
	}
	
	displayErrors($cnt->{'val'}, $srcSnt, $hypSnt, \@refSntArr, \@aliArr, $opts->{'multiRefMethod'});
	
	counter::update($cnt);
}

counter::finish($cnt);

io::closeMany(@handles);

# There must be one root element in the output XML, otherwise the XML::Parser will complain.
print("</document>\n");

#####
#
#####
sub processInputArgsAndOpts {
	my ($caseSensitive, $multiRefMethod, $ignoreOutOfBounds);
	
	GetOptions('c' => \$caseSensitive, 'm=s' => \$multiRefMethod, 'i' => \$ignoreOutOfBounds);
	
	if (!defined($multiRefMethod)) {
		$multiRefMethod = $const::MRM_SNT;
	}
	
	unless ($const::mrmTest->{$multiRefMethod}) {
		my $msg = "Unknown method for handling " .
			"multiple references: `$multiRefMethod'";
		die($msg);
	}
	
	my $numOfArgs = scalar @ARGV;
	if ($numOfArgs < 4) {
		my $msg = "Arguments missing, check them carefully;\n" .
			getUsage();
		die($msg);
	}
	if ($numOfArgs % 2 == 1) {
		my $msg = "Last reference file is missing an alignment file, " .
			"check the arguments carefully;\n" .
			getUsage();
		die($msg);
	}
	
	return {
		'caseSensitive' => $caseSensitive,
		'multiRefMethod' => $multiRefMethod,
		'ignoreOutOfBounds' => $ignoreOutOfBounds };
}

#####
#
#####
sub displayErrors {
	my ($sntIdx, $srcSnt, $hypSnt, $refSntArr, $aliArr, $mrm) = @_;
	
	printSntStart($sntIdx);
	printGeneralSntInfo($srcSnt, $hypSnt);
	
	if ($mrm eq $const::MRM_ALL) {
		displayAllErrors($srcSnt, $hypSnt, $refSntArr, $aliArr);
	}
	elsif ($mrm eq $const::MRM_SNT) {
		displaySentenceOptimizedErrors($srcSnt, $hypSnt, $refSntArr, $aliArr);
	}
	elsif ($mrm eq $const::MRM_ERRCAT) {
		displayCategoryOptimizedErrors($srcSnt, $hypSnt, $refSntArr, $aliArr);
	}
	
	printSntFinish();
}

#####
#
#####
sub wrongHypWrap {
	my ($ref, $ali, $idx, $src, $hyp) = @_;
	return getIncorrectHypTokenErrs($src, $hyp, $ali);
}

#####
#
#####
sub missingWrap {
	my ($ref, $ali, $idx, $src, $hyp) = @_;
	return getMissingRefTokenErrs($ref, $ali);
}

#####
#
#####
sub aliUneqWrap {
	my ($ref, $ali, $idx, $src, $hyp) = @_;
	return getAlignedUneqTokenErrs($ref, $hyp, $ali);
}

#####
#
#####
sub orderWrap {
	my ($ref, $ali, $idx, $src, $hyp) = @_;
	return ordersim::getOrderErrs($ref, $hyp, $ali)
}

#####
#
#####
sub displayCategoryOptimizedErrors {
	my ($srcSnt, $hypSnt, $refSntArr, $aliArr) = @_;
	my $lines = [];
	
	for my $i (0..$#$refSntArr) {
		appendLines($lines, 1, getRefInfo($refSntArr->[$i], $aliArr->[$i], $i));
	}
	
	for my $catFunc (\&wrongHypWrap, \&missingWrap, \&aliUneqWrap, \&orderWrap) {
		my $lowestCost = 1e600;
		my $chosenLines = undef;
		
		for my $i (0..$#$refSntArr) {
			my $refSnt = $refSntArr->[$i];
			my $ali = $aliArr->[$i];
			
			my $currLines = &$catFunc($refSnt, $ali, $i, $srcSnt, $hypSnt);
			
			my $cost = getCost($currLines);
			
			if ($cost > 0) {
				unshift @$currLines, "<chosenReference index=\"$i\">";
			}
			
			if ($cost < $lowestCost) {
				$lowestCost = $cost;
				$chosenLines = $currLines;
			}
		}
		
		appendLines($lines, 0, $chosenLines);
	}
	
	printLines(1, $lines);
}

#####
#
#####
sub displaySentenceOptimizedErrors {
	my ($srcSnt, $hypSnt, $refSntArr, $aliArr) = @_;
	
	my $lowestCost = 1e600;
	my $chosenLines = undef;
	
	for my $i (0..$#$refSntArr) {
		my $currLines = [];
		my $refSnt = $refSntArr->[$i];
		my $ali = $aliArr->[$i];
		
		appendLines($currLines, 1, getRefInfo($refSnt, $ali, $i));
		appendLines($currLines, 0, getIncorrectHypTokenErrs($srcSnt, $hypSnt, $ali));
		appendLines($currLines, 0, getMissingRefTokenErrs($refSnt, $ali));
		appendLines($currLines, 0, getAlignedUneqTokenErrs($refSnt, $hypSnt, $ali));
		appendLines($currLines, 0, ordersim::getOrderErrs($refSnt, $hypSnt, $ali));
		
		my $cost = getCost($currLines);
		
		if ($cost < $lowestCost) {
			$lowestCost = $cost;
			$chosenLines = $currLines;
		}
	}
	
	printLines(1, $chosenLines)
}

#####
#
#####
sub getCost {
	my $lines = shift;
	
	return scalar grep(!/^\s*$/, @$lines);
}

#####
#
#####
sub appendLines {
	my ($buff, $skipLine, $newlines) = @_;
	
	if (defined($newlines) and (scalar @$newlines > 0)) {
		unless ($skipLine) {
			push @$buff, "";
		}
		
		push @$buff, @$newlines;
	}
}

#####
#
#####
sub displayAllErrors {
	my ($srcSnt, $hypSnt, $refSntArr, $aliArr) = @_;
	
	for my $i (0..$#$refSntArr) {
		my $currLines = [];
		my $refSnt = $refSntArr->[$i];
		my $ali = $aliArr->[$i];
		
		printRefStart($i);
		
		appendLines($currLines, 1, getRefInfo($refSnt, $ali));
		appendLines($currLines, 0, getIncorrectHypTokenErrs($srcSnt, $hypSnt, $ali));
		appendLines($currLines, 0, getMissingRefTokenErrs($refSnt, $ali));
		appendLines($currLines, 0, getAlignedUneqTokenErrs($refSnt, $hypSnt, $ali));
		appendLines($currLines, 0, ordersim::getOrderErrs($refSnt, $hypSnt, $ali));
		
		printLines(2, $currLines);
		
		printRefFinish();
	}
}

#####
#
#####
sub printLines {
	my ($tabs, $lines) = @_;
	
	if (defined($lines)) {
		for my $line (@$lines) {
			print "\t" x $tabs;
			print $line;
			print "\n";
		}
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
sub getAlignedUneqTokenErrs {
	my ($refSnt, $hypSnt, $al) = @_;
	
	my @output = ();
	
	for my $pair (@$al) {
		if ($pair->{'hyp'} >= 0 and
				$pair->{'hyp'} <= $#$hypSnt and
				$pair->{'ref'} >= 0 and
				$pair->{'ref'} <= $#$hypSnt) {
			my $hypToken = $hypSnt->[$pair->{'hyp'}];
			my $refToken = $refSnt->[$pair->{'ref'}];
			
			my @uneqFactors = ();
			
			my $maxidx = math::max($#$hypToken, $#$refToken);
			
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
				
				push @output, "<unequalAlignedTokens hypIdx=\"" . $pair->{'hyp'} .
					"\" hypToken=\"$rawHypToken\" refIdx=\"" . $pair->{'ref'} .
					"\" refToken=\"$rawRefToken\" unequalFactorList=\"$uneqFactorList\"/>";
			}
		}
	}
	
	return \@output;
}

#####
#
#####
sub getMissingRefTokenErrs {
	my ($refSnt, $al) = @_;
	
	my @output = ();
	
	my $alHash = hashAlignment($al, 'ref');
	
	for my $i (0..$#$refSnt) {
		if (!$alHash->{$i}) {
			my $surfForm = $refSnt->[$i]->[0];
			my $rawToken = io::tok2str4xml($refSnt->[$i]);
			
			push @output, "<missingRefWord idx=\"$i\" " .
				"surfaceForm=\"" . io::str4xml($surfForm) . "\" " .
				"token=\"$rawToken\"/>";
		}
	}
	
	return \@output;
}

#####
#
#####
sub getIncorrectHypTokenErrs {
	my ($srcSnt, $hypSnt, $al) = @_;
	
	my @output = ();
	
	my $srcHash = io::hashFactors($srcSnt, 0);
	my $alHash = hashAlignment($al, 'hyp');
	
	for my $i (0..$#$hypSnt) {
		if (!$alHash->{$i}) {
			my $surfForm = $hypSnt->[$i]->[0];
			my $rawToken = io::tok2str4xml($hypSnt->[$i]);
			
			my $tagId = ($srcHash->{$surfForm})? "untranslated": "extra";
			
			push @output, "<" . $tagId . "HypWord idx=\"$i\" " .
				"surfaceForm=\"" . io::str4xml($surfForm) . "\" " .
				"token=\"$rawToken\"/>";
		}
	}
	
	return \@output;
}

#####
#
#####
sub printSntStart {
	my $idx = shift;
	print "<sentence index=\"$idx\">\n";
}

#####
#
#####
sub printSntFinish {
	print "</sentence>\n\n";
}

#####
#
#####
sub printRefStart {
	my $idx = shift;
	print "\t<reference index=\"$idx\">\n";
}

#####
#
#####
sub printRefFinish {
	print "\t</reference>\n";
}

#####
#
#####
sub printGeneralSntInfo {
	my ($srcSnt, $hypSnt) = @_;
	
	print "\t<source length=\"" . scalar @$srcSnt . "\" text=\"" . io::snt2txt($srcSnt) . "\"/>\n";
	print "\t<hypothesis length=\"" . scalar @$hypSnt . "\" text=\"" . io::snt2txt($hypSnt) . "\"/>\n";
}

#####
#
#####
sub getRefInfo {
	my ($refSnt, $ali, $idx) = @_;
	
	my $numOfAligned = scalar @$ali;
	
	my $idxInfo = (defined($idx))? " index=\"$idx\"": "";
	
	return ["<reference$idxInfo length=\"" . (scalar @$refSnt) .
		"\" aligned=\"$numOfAligned\" text=\"" . io::snt2txt($refSnt) . "\"/>"];
}
