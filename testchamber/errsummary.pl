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
		elsif ($tagId eq "ordSimMetrics") {
			my $rho = $fields->{'spearmansRho'};
			
			if ($rho ne "undef") {
				$totalRho += ($fields->{'spearmansRho'} + 1) * $currentNumOfAligned / 2;
			}
		}
		elsif ($tagId eq "missingRefWord") {
			$missingRefWords->{getCat($fields->{'token'})}++;
		}
		elsif ($tagId eq "extraHypWord") {
			$incorrectHypWords->{'extra, ' . getCat($fields->{'token'})}++;
		}
		elsif ($tagId eq "untranslatedHypWord") {
			$incorrectHypWords->{'untranslated'}++;
		}
		elsif ($tagId eq "unequalAlignedTokens") {
			$incorrectHypWords->{'wrong form'}++;
		}
		elsif ($tagId =~ /^ordError/) {
			my $dist = $fields->{'distance'};
			
			$orderErrors->{($dist > 0? "8+": $dist)}++;
		}
	}
}

printf "Total sentences: %10d\n", $totalNumOfSnts;
printf "Total ref words: %10d\n", $totalRefLen;
printf "Total hyp words: %10d\n", $totalHypLen;

printWithCats($missingRefWords, 'Missing ref words', 'ref', $totalRefLen);
printWithCats($incorrectHypWords, 'Incorrect hyp words', 'hyp', $totalHypLen);

print "\nOrder similarity metrics\n";
printf "\t%13s: %5.3f\n", "Spearman's rho", $totalRho / $totalNumOfAligned;

printWithCats($orderErrors, 'Order errors, by shift distance', 'hyp', $totalHypLen);

#####
#
#####
sub printWithCats {
	my ($hash, $setId, $aux, $total) = @_;
	
	print "\n$setId:\n";
	
	my $sum = 0;
	
	for my $k (sort { $a <=> $b } keys %$hash) {
		my $val = $hash->{$k};
		$sum += $val;
		printf "\t%13s: %7d (%5.2f%% of $aux)\n", $k, $val, 100*$val/$total;
	}
	printf "\n\t%13s: %7d (%5.2f%% of $aux)\n", 'total', $sum, 100*$sum/$total;
}

#####
#
#####
sub getCat {
	return '--';

	my $token = shift;
	my @fields = split(/\|/, $token);
	return $fields[1];
}
