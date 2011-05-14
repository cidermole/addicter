#!/usr/bin/perl
use strict;
use Carp;
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

##############################################
# produce a hypothesis-to-reference alignment via intersection
# of a source-to-hypothesis and source-to-reference alignment
##############################################

my ($srcToHypFile, $srcToRefFile) = @ARGV;

unless (defined($srcToRefFile) and defined($srcToHypFile)) {
	usage();
}

my @fhs = io::gopenMany($srcToHypFile, $srcToRefFile);
my $tuple;

while ($tuple = io::readSentences(@fhs)) {
	my $srcToHypAli = parse::alignment($tuple->[0], 1);
	my $srcToRefAli = parse::alignment($tuple->[1], 1);
	my $hypToRefAli = intersectAlignments($srcToHypAli, $srcToRefAli);
	displayMultiAlignment($hypToRefAli);
}

#####
#
#####
sub intersectAlignments {
	my ($srcToHyp, $srcToRef) = @_;
	
	my $hypMap = aliToMap($srcToHyp);
	my $refMap = aliToMap($srcToRef);
	
	my $result;
	
	for my $hypPt (keys %$hypMap) {
		my $srcToHypMap = $hypMap->{$hypPt};
		
		for my $refPt (keys %$refMap) {
			my $srcToRefMap = $refMap->{$refPt};
			my $doit = 0;
			
			for my $srcToRefPt (keys %$srcToRefMap) {
				if ($srcToHypMap->{$srcToRefPt}) {
					$doit = 1;
				}
			}
			
			if ($doit) {
				push @$result, { 'hyp' => $hypPt, 'ref' => $refPt};
			}
		}
	}
	
	return $result;
}

#####
#
#####
sub aliToMap {
	my ($ali) = @_;
	my $result = {};
	
	for my $alPt (@$ali) {
		$result->{$alPt->{'ref'}}->{$alPt->{'hyp'}} = 1;
	}
	
	return $result;
}

#####
#
#####
sub displayMultiAlignment {
	my $al = shift;
	my @printPts = ();
	
	for my $alPt (sort { 1000 * $a->{'hyp'} + $a->{'ref'} <=> 1000 * $b->{'hyp'} + $b->{'ref'} } @$al) {
		push @printPts, ("" . $alPt->{'hyp'} . "-" . $alPt->{'ref'});
	}
	
	print join(" ", @printPts);
	print "\n";
}

#####
#
#####
sub usage {
	die("Usage: ./322.pl src-to-hyp-alignment src-to-ref-alignment");
}
