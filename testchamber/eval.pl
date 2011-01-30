#!/usr/bin/perl
use strict;
use File::Spec;

BEGIN {
	my @dirs = File::Spec->splitdir(File::Spec->rel2abs(File::Spec->canonpath($0)));
	pop @dirs;
	push(@INC, File::Spec->catdir(@dirs));
}

use io;
use stats;
use opts;

binmode(STDOUT, ":utf8");

opts::processOpts();
my ($srcfile, $reffile, $hypfile) = @ARGV;

if (!$srcfile or !$reffile or !$hypfile) {
	die("Required arguments: source file, reference file, hypothesis file");
}

my $fh = io::openFiles($srcfile, $reffile, $hypfile);

my $tuple;
my $stats = {};

my $counter = 0;

while($tuple = io::readSentences($fh)) {
	stats::update($tuple, $stats);
	
	$counter++;
	
	if ($counter % 10 == 0) {
		print STDERR ".";
	}
	if ($counter % 100 == 0) {
		print STDERR "$counter\n";
	}
}

if ($counter % 100 != 0) {
	print STDERR "$counter\n";
}

io::closeFiles($fh);

stats::display($stats);
