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

my $filename = (scalar @ARGV == 0)? "-": $ARGV[0];

my $fh = io::openRead($filename);

my $totalRefLen = 0;
my $totalHypLen = 0;
my $currentHypLen = undef;
my $missingRefWords = {};
my $incorrectHypWords = {};

while (<$fh>) {
}
