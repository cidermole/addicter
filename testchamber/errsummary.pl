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

my $filename = (scalar @ARGV == 0)? "-": $ARGV[0];

my $fh = io::openRead($filename);

my $totalNumOfSnts = 0;
my $totalRefLen = 0;
my $totalHypLen = 0;
my $totalNumOfAligned = 0;
my $currentNumOfAligned = undef;
my $missingRefWords = {};
my $incorrectHypWords = {};
my $orderErrors = {};
my $totalRho = 0;

while (<$fh>) {
	my $tag = parse::xml($_);
	
	if (defined($tag)) {
		my $tagId = $tag->{'id'};
		my $fields = $tag->{'fields'};
		
		if ($tagId eq "sentence") {
			$totalNumOfSnts++;
		}
		elsif ($tagId eq "reference") {
			$totalRefLen += $fields->{'length'};
		}
		elsif ($tagId eq "hypothesis") {
			$currentNumOfAligned = $fields->{'aligned'};
			$totalNumOfAligned += $currentNumOfAligned;
			$totalHypLen += $fields->{'length'};
		}
		elsif ($tagId eq "orderSimilarityMetrics") {
			my $rho = $fields->{'spearmansRho'};
			
			if ($rho ne "undef") {
				$totalRho += ($fields->{'spearmansRho'} + 1) * $currentNumOfAligned / 2;
			}
		}
		elsif ($tagId eq "") {
		}
	}
}

printf "%.3f\n", $totalRho / $totalNumOfAligned;
