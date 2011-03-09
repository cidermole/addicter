#!/usr/bin/perl
#align-lcs.pl -c -n i ref.file hyp.file
#-c			case sensitive
#-n=i		align factor:
#	0		surface form
#	1		
#	2		lemma
#aligns hyp to ref using LCS algorithm

use strict;
use Getopt::Long;
use File::Spec;

BEGIN {
	#include packages from same folder where the
	#script is, even if launched from elsewhere
	
	my @dirs = File::Spec->splitdir(File::Spec->rel2abs(File::Spec->canonpath($0)));
	pop @dirs;
	push(@INC, File::Spec->catdir(@dirs));
}

use io;
use counter;
use parse;
use Algorithm::Diff;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my ($refFile, $hypFile, $caseSensitive, $alFactor) = processInputArgsAndOpts();
my ($fhRef, $fhHyp) = io::openMany($refFile, $hypFile);
my $cnt = counter::init();
my $tuple;

while($tuple = io::readSentences($fhRef, $fhHyp)) {
	my $refSnt = parse::sentence($tuple->[0], $caseSensitive);
	my $hypSnt = parse::sentence($tuple->[1], $caseSensitive);
	my $alignment = LCSAlignment($refSnt, $hypSnt, $alFactor);
	print("@$alignment \n");
	counter::update($cnt);
}

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
	
	my ($refFile, $hypFile) = @ARGV;

	if (!$refFile or !$hypFile) {
		die("Required arguments: reference file, hypothesis file");
	}
	
	return ($refFile, $hypFile, $caseSensitive, $alFactor);
}

sub LCSAlignment {
	my ($refSnt, $hypSnt, $alFactor) = @_;
	my @reference;
	my @hypothesis;
	for (my $i=0;$i<=$#$refSnt;$i++) {
		push(@reference,$refSnt->[$i]->[$alFactor]);
	}
	for (my $j=0;$j<=$#$hypSnt;$j++) {
		push(@hypothesis,$hypSnt->[$j]->[$alFactor]);
	}
	my @ali = Algorithm::Diff::compact_diff(\@hypothesis,\@reference);
	my (@hypAli, @refAli);
	for (my $i=0;$i<=$#ali-1;$i+=2) {
		push(@hypAli,$ali[$i]);
		push(@refAli,$ali[$i+1]);
	}
	
	my @result;
	for (my $i=0;$i<=$#hypAli;$i++) {
		my $residual = $hypAli[$i+1]-$hypAli[$i];
		if ($residual>0) {
			if ($residual==$refAli[$i+1]-$refAli[$i]) {
				for (my $j=0;$j<$residual;$j++) {
					my $rhs = $hypAli[$i]+$j;
					my $lhs = $refAli[$i]+$j;
					push(@result,$rhs.'-'.$lhs);
				}
			}
		}
	}
	return \@result;
}
