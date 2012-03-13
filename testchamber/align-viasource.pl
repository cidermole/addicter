#!/usr/bin/perl
# alignment via source
# Copyright © 2012 Jan Berka <berka@ufal.mff.cuni.cz>
# License: GNU GPL

use io;
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use Getopt::Long;
use File::Spec;
use parse;

BEGIN {
	#include packages from same folder where the
	#script is, even if launched from elsewhere
	
	my @dirs = File::Spec->splitdir(File::Spec->rel2abs(File::Spec->canonpath($0)));
	pop @dirs;
	push(@INC, File::Spec->catdir(@dirs));
}

my ($srcRefFile, $srcHypFile) = processInputArgsAndOpts();
my ($fhSrcRef, $fhSrcHyp) = io::openMany($srcRefFile, $srcHypFile);


while(my $tuple = io::readSentences($fhSrcRef, $fhSrcHyp)) {
	#print("$tuple->[0]\n");
	#print("$tuple->[1]\n");
	my $alignment = ViaSourceAlignment($tuple->[0], $tuple->[1]);
	print("@$alignment\n");
}

############################
#        SUBROUTINES       #
############################


sub processInputArgsAndOpts {
	my ($srcRefFile, $srcHypFile) = @ARGV;
	if (!$srcRefFile and !$srcHypFile) {
		print STDERR ("Aligns reference to hypothesis using the source-to-reference and source-to-hypothesis alignments\n");
		print STDERR ("Usage:\n align-viasource.pl src-ref_alignment_file src-hyp_alignment_file\n");
	}
	if (!$srcRefFile or !$srcHypFile) {
		die("Required arguments: source to reference alignment file, source to hypothesis alignment file");
	}
	return ($srcRefFile, $srcHypFile);
}

sub ViaSourceAlignment {
	my $srcRef = shift;
	my $srcHyp = shift;
	
	my @viasource = qw();
	
	my @srcRef = split(/ /,$srcRef);
	my @srcHyp = split(/ /,$srcHyp);
	
	my @srsrc = qw();
	my @srref = qw();
	my @shsrc = qw();
	my @shhyp = qw();
	
	foreach my $token (@srcRef) {
		my @p = split(/-/, $token);
		push(@srsrc, $p[0]);
		push(@srref, $p[1]);
	}
	foreach my $token (@srcHyp) {
		my @p = split(/-/, $token);
		push(@shsrc, $p[0]);
		push(@shhyp, $p[1]);
	}
	
	for my $i (0..$#srsrc) {
		for my $j (0..$#shsrc) {
			if ($srsrc[$i] == $shsrc[$j]) {
				push(@viasource, $srref[$i]."-".$shhyp[$j]); 
			}
		}
	}
	my $i = 0;
	while ($i < $#viasource) {
		if ($viasource[$i] eq $viasource[$i+1]) {
			delete($viasource[$i+1]);
		}
		$i = $i + 1;
	}
	return \@viasource;
}
