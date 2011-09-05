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
			$incorrectHypWords->{'unk'}++;
		}
		elsif ($tagId eq "unequalAlignedTokens") {
			my $latag = ($fields->{'unequalFactorList'} =~ /2/)? 'lex error': 'wrong form';
			$incorrectHypWords->{$latag}++;
		}
		elsif ($tagId =~ /^ordError/) {
			my $dist = $fields->{'distance'};
			
			$orderErrors->{($dist > 1? "many": $dist)}++;
		}
	}
}

printf "Total sentences: %10d\n", $totalNumOfSnts;
printf "Total ref words: %10d\n", $totalRefLen;
printf "Total hyp words: %10d\n", $totalHypLen;

printWithCats($missingRefWords, 'Missing ref words', 'ref', $totalRefLen);
printWithCats($incorrectHypWords, 'Incorrect hyp words', 'hyp', $totalHypLen);

#print "\nOrder similarity metrics\n";
#if($totalNumOfAligned != 0)
#{
#	printf "\t%13s: %5.3f\n", "Spearman's rho", $totalRho / $totalNumOfAligned;
#}
#else
#{
#	  printf("\t%13s: %5s\n", "Spearman's rho", "$totalRho / $totalNumOfAligned ... cannot divide by zero");
#}

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
		printf "%10s: %7d (%5.2f%% of $aux)\n", $k, $val, 100*$val/$total;
	}
	printf "\n%10s: %7d (%5.2f%% of $aux)\n", 'total', $sum, 100*$sum/$total;
}

#####
#
#####
sub getCat {
	my $token = shift;
	my @fields = split(/\|/, $token);
	my $res = substr($fields[1], 0, 1);
	return $res;
}
