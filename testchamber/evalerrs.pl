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
use math;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

our %groups = (
	"order" => [qw(ows owl ops opl)],
	"punct" => ["punct"],
	"lex" => [qw(disam lex extra unk form)],
	"missed" => [qw(missA missP missC)]
);


my ($refAnalysisFile, $hypAnalysisFile, $refTransFile) = @ARGV;

if (!$refAnalysisFile or !$hypAnalysisFile or !$refTransFile) {
	die("required arguments: manual_analysis_file automatic_analysis_file reference_translation");
}

my ($fhRA, $fhHA, $fhRT) = io::openMany($refAnalysisFile, $hypAnalysisFile, $refTransFile);
my ($hypAnalysis, $refAnalysis, $refTrans);
my @refAnalysisArr;
my $prevId = undef;
my $stats = {};

while ($refAnalysis = readRefAnalysis($fhRA)) {
	if (defined($prevId) and $prevId != $refAnalysis->{'id'}) {
		($hypAnalysis, $refTrans) = readHAandRT($fhHA, $fhRT);
		
		updateStats($hypAnalysis, $refTrans, \@refAnalysisArr, $stats);
		
		@refAnalysisArr = ();
	}
	
	push @refAnalysisArr, $refAnalysis;
	
	$prevId = $refAnalysis->{'id'};
}

($hypAnalysis, $refTrans) = readHAandRT($fhHA, $fhRT);
updateStats($hypAnalysis, $refTrans, \@refAnalysisArr, $stats);

for my $groupId ("lex", "order", "punct", "missed") {
	logHash($stats, $groupId);
}

sub logHash {
	my ($stats, $id) = @_;
	
	my $flags = $groups{$id};
	
	print "\n---=== Confusion matrix for $id errors: ===---\n";
	print "\n(top: ref flags, side: hyp flags)\n\n";
	
	printf "%8s%8s", "", "(empty)";
	for my $flag (@$flags) {
		printf "%8s", $flag;
	}
	printf "%15s\n", "total";
	
	for my $k1 (undef, @$flags) {
		my $dk1 = ($k1)? $k1: "(empty)";
		my $sum = 0;
		
		printf "%8s", $dk1;
		
		for my $k2 (undef, @$flags) {
			my $val = (0 + $stats->{$id}->{$k2}->{$k1});
			printf "%8s", $val;
			$sum += $val;
		}
		printf "%15d\n", $sum;
	}
}

#####
# idiom, case, garbled -- ignore
# ows, owl, ops, opl -- "group"
# disam, lex, extra, unk, form, neg -- "group"
# missC, missA, missP::??? -- ?
# punct separately
#####
sub updateStats {
	my ($hypAnalysis, $refTrans, $refAnalysisArr, $stats) = @_;
	
	my $hypAnalysisHyp = $hypAnalysis->{'hyp'};
	my $hypAnalysisMiss = $hypAnalysis->{'missed'};
	
	updateGroupStats($hypAnalysisHyp, $refAnalysisArr, $stats, "order");
	updateGroupStats($hypAnalysisHyp, $refAnalysisArr, $stats, "punct");
	updateGroupStats($hypAnalysisHyp, $refAnalysisArr, $stats, "lex");
	updateMissStats($hypAnalysisMiss, (scalar @$refTrans), $refAnalysisArr, $stats);
}

#####
#
#####
sub updateMissStats {
	my ($hypAnalysisMiss, $refSize, $refAnalysisArr, $stats) = @_;
	
	my $maxWeight = -1e600;
	my $bestStats;
	
	for my $refAnalysis (@$refAnalysisArr) {
		my ($currStats, $currWeight) = singleRefMissStats($hypAnalysisMiss,
			$refAnalysis->{'analysis'}->{'missed'}, $refSize);

		if ($currWeight > $maxWeight) {
			$maxWeight = $currWeight;
			$bestStats = $currStats;
		}
	}
	
	insertStatChunk($stats, 'missed', $bestStats);
}

#####
#
#####
sub singleRefMissStats {
	my ($hypMiss, $refMiss, $refSize) = @_;
	my $weight = 0;
	my $stats = {};
	
	my $coveredHyp = {};
	
	for my $k (keys %$refMiss) {
		my ($refForm, $refPos) = split(/\|/, $k);
		my $refCount = $refMiss->{$k};
		my $totalHypCount = 0;
		
		my $refTag = "miss$refPos";
		
		my @posArr = grep(!/^\Q$refPos\E$/, "C", "P", "A");
		
		for my $hypPos ($refPos, @posArr) {
			my $hypKey = "$refForm|$hypPos";
			my $hypCount = $hypMiss->{$hypKey};
			$coveredHyp->{$hypKey} = 1;
			my $hypTag = "miss$hypPos";
			
			if ($hypCount) {
				my ($updThis, $updEmpty) = (0, 0);
				
				if ($totalHypCount + $hypCount <= $refCount) {
					$updThis = $hypCount;
				}
				elsif ($totalHypCount >= $refCount) {
					$updEmpty = $hypCount;
				}
				else {
					$updThis = $refCount - $totalHypCount;
					$updEmpty = $hypCount - $updThis;
				}
				
				$stats->{$refTag}->{$hypTag} += $updThis;
				$stats->{""}->{$hypTag} += $updEmpty;
				
				$totalHypCount += $hypCount;
			}
		}
		
		if ($totalHypCount < $refCount) {
			$stats->{$refTag}->{""} += ($refCount - $totalHypCount);
		}
	}
	
	for my $hk (keys %$hypMiss) {
		unless ($coveredHyp->{$hk}) {
			my ($hypForm, $hypPos) = split(/\|/, $hk);
			$stats->{""}->{"miss$hypPos"} += $hypMiss->{$hk};
		}
	}
	
	return ($stats, $weight);
}

#####
#
#####
sub updateGroupStats {
	my ($hypAnalysisHyp, $refAnalysisArr, $stats, $groupId) = @_;
	
	my $maxWeight = -1e600;
	my $bestStats;
	
	for my $refAnalysis (@$refAnalysisArr) {
		my ($currStats, $currWeight) = singleRefHypStats($hypAnalysisHyp,
			$refAnalysis->{'analysis'}->{'hyp'}, $groups{$groupId});

		if ($currWeight > $maxWeight) {
			$maxWeight = $currWeight;
			$bestStats = $currStats;
		}
	}
	
	insertStatChunk($stats, $groupId, $bestStats);
}

#####
#
#####
sub insertStatChunk {
	my ($genStats, $groupId, $statChunk) = @_;
	
	for my $k1 (keys %$statChunk) {
		for my $k2 (keys %{$statChunk->{$k1}}) {
			$genStats->{$groupId}->{$k1}->{$k2} += $statChunk->{$k1}->{$k2};
		}
	}
}

#####
#
#####
sub singleRefHypStats {
	my ($hypAnalysisHyp, $refAnalysisHyp, $groupFlags) = @_;
	my $weight = 0;
	my $stats = {};
	
	#flagg::resolveFlagConflicts($refAnalysisHyp);
	
	for my $hypIdx (0..$#$hypAnalysisHyp) {
		my $truHypFlag = getTruFlag($hypAnalysisHyp->[$hypIdx], $groupFlags);
		my $truRefFlag = getTruFlag($refAnalysisHyp->[$hypIdx], $groupFlags, $truHypFlag);
		
		$stats->{$truRefFlag}->{$truHypFlag}++;
		
		if ($truRefFlag eq $truHypFlag) {
			$weight++;
		}
	}
	
	return ($stats, $weight);
}

#####
#
#####
sub getTruFlag {
	my ($hyp, $group, $desiredFlag) = @_;
	
	my $result = undef;
	
	for my $flag (@$group) {
		if ($hyp->{'flags'}->{$flag}) {
			if (!defined($result)) {
				$result = $flag;
			}
			else {
				print STDERR "conflict between $flag and $result\n";
				
				if (defined($desiredFlag)) {
					if ($flag eq $desiredFlag) {
						$result = $flag;
					}
				}
				else {
					die("Duplicate flag in hypothesis, damn (@$group)");
				}
			}
		}
	}
	
	return $result;
}

#####
# read hyp analysis and ref translation
#####
sub readHAandRT {
	my ($fhHA, $fhRT) = @_;
	
	my $tupl = io::readSentences($fhHA, $fhRT);
	
	return ( parse::flagg($tupl->[0]), parse::sentence($tupl->[1]) );
}

#####
#
#####
sub readRefAnalysis {
	my $fh = shift;
	
	my $str = io::readSentence($fh);
	
	if ($str =~ /^([0-9]+) (.*)$/) {
		return { 'id' => $1 + 0, 'analysis' => parse::flagg($2) };
	}
	elsif (!defined($str)) {
		return undef;
	}
	else {
		die("Fail");
	}
}
