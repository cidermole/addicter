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
use probs;
use beamsearch;
use counter;

binmode(STDOUT, ":utf8");

my ($reffile, $hypfile, $caseSensitive, $alFactor) =
	processInputArgsAndOpts();

my ($fhRef, $fhHyp) = io::openMany($reffile, $hypfile);
my $tuple;
my $cnt = counter::init();

while($tuple = io::readSentences($fhRef, $fhHyp)) {
	my $refSnt = io::parseSentence($tuple->[0], $caseSensitive);
	my $hypSnt = io::parseSentence($tuple->[1], $caseSensitive);
	
	my $probs = probs::generate($refSnt, $hypSnt, $alFactor);
	my $alignment = beamsearch::decodeAlignment($refSnt, $hypSnt, $alFactor, $probs);
	displayAlignment($alignment);
	
	counter::update($cnt);
}

counter::finish($cnt);

io::closeMany($fhRef, $fhHyp);

#####
#
#####
sub processInputArgsAndOpts {
	my ($caseSensitive, $alFactor);
	
	GetOptions(
		'c' => \$caseSensitive,
		'n=i' => \$alFactor);
	
	if (!defined($alFactor)) {
		$alFactor = 0;
	}
	
	if ($alFactor < 0) {
		die("Looking for a positive-valued iteger for alignment factor");
	}
	
	my ($reffile, $hypfile) = @ARGV;

	if (!$reffile or !$hypfile) {
		die("Required arguments: reference file, hypothesis file");
	}
	
	return ($reffile, $hypfile, $caseSensitive, $alFactor);
}

#####
#
#####
sub displayAlignment {
	my $al = shift;
	
	if (!$al) {
		print "undef\n";
	}
	else {
		for my $i (0..$#$al) {
			my $alPt = $al->[$i];
			if ($alPt >= 0) {
				printf("%d-%d", $i, $alPt);
				
				if ($i < $#$al) {
					print " "
				}
			}
		}
		
		print "\n";
	}
}
