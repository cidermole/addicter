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

binmode(STDOUT, ":utf8");

my ($srcfile, $reffile, $hypfile, $alifile, $caseSensitive) =
	processInputArgsAndOpts();

my ($fhSrc, $fhRef, $fhHyp, $fhAli, $caseSensitive) = io::openMany($srcfile, $reffile, $hypfile, $alifile);
my $tuple;
my $cnt = counter::init();

while($tuple = io::readSentences($fhRef, $fhHyp)) {
	my $srcSnt = io::parseSentence($tuple->[0], $caseSensitive);
	my $refSnt = io::parseSentence($tuple->[1], $caseSensitive);
	my $hypSnt = io::parseSentence($tuple->[2], $caseSensitive);
	my $alignment = io::parseAlignment($tuple->[3]);
	
	counter::update($cnt);
}

counter::finish($cnt);

io::closeMany($fhRef, $fhHyp);

#####
#
#####
sub processInputArgsAndOpts {
	my $caseSensitive;
	
	GetOptions(
		'c' => \$caseSensitive);
	
	my ($srcfile, $reffile, $hypfile, $alifile) = @ARGV;

	if (!$srcfile or !$alifile or !$reffile or !$hypfile) {
		die("Required arguments: source file, reference file, hypothesis file, alignment file");
	}
	
	return ($srcfile, $reffile, $hypfile, $alifile, $caseSensitive);
}
