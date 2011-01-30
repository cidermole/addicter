package stats;
use strict;
use beamsearch;
use probs;

#####
#
#####
sub alignSntTuple {
	my $tuple = shift;
	
	my $probs = probs::generate($tuple);
	
	$tuple->{'alignment'} = beamsearch::decode($tuple, $probs);
}

#####
#
#####
sub displayTupleAlignment {
	my $snttuple = shift;
	
	my $idx = 1;
	for my $refw (@{$snttuple->{'ref'}}) {
		print "$idx: " . $refw . " ";
		$idx++;
	}
	print "\n";
  
	for my $hidx (1..(scalar @{$snttuple->{'hyp'}})){
		print "$hidx: " . $snttuple->{'hyp'}->[$hidx-1] .
			" (" . $snttuple->{'alignment'}->[$hidx-1] .
			") ";
	}
	print "\n";
	print "--------------\n";
}

#####
#
#####
sub submitStatChunk {
	my ($currstats, $stats) = @_;
	
	push @{$stats->{'raw'}}, $currstats;
	
	for my $k1 (qw(totalref totalhyp spearman totalspearman)) {
		$stats->{$k1} += $currstats->{$k1};
	}
	
	for my $k2 (qw(missing untranslated extra wrongform)) {
		for my $k3 (keys %{$currstats->{$k2}}) {
			$stats->{$k2}->{$k3} += $#{$currstats->{$k2}->{$k3}} + 1
		}
	}
}

#####
#
#####
sub updateWordErrors {
	my ($currstats, $tuple) = @_;
	
	my $coveredRefIdxs = {};
	
	for my $i (0..$#{$tuple->{'alignment'}}) {
		my $alPt = $tuple->{'alignment'}->[$i];
		my $hypword = $tuple->{'hyp'}->{'forms'}->[$i];
		my $hyptag = $tuple->{'hyp'}->{'tags'}->[$i];
		
		#evaluating unknown/wrong hyp words
		if ($alPt == 0) {
			my $whereToPut = (probs::sntHasWord($tuple->{'src'}->{'forms'}, $hypword))?
				'untranslated': 'extra';
			
			push @{$currstats->{$whereToPut}->{$hyptag}}, $hypword;
			$tuple->{$whereToPut}->{$i} = 1;
		}
		else {
			#for evaluating missing ref words
			$coveredRefIdxs->{$alPt} = 1;
			
			my $refword = $tuple->{'ref'}->{'forms'}->[$alPt - 1];
			my $reftag = $tuple->{'ref'}->{'tags'}->[$alPt - 1];
			
			if ($refword ne $hypword) {
				push @{$currstats->{'wrongform'}->{"" . $reftag}},
					("" . $hypword . "-" . $refword);
			}
		}
	}
	
	#evaluating missing ref words
	for my $j (0..$#{$tuple->{'ref'}->{'forms'}}) {
		unless ($coveredRefIdxs->{$j + 1}) {
			push @{$currstats->{'missing'}->{$tuple->{'ref'}->{'tags'}->[$j]}},
				$tuple->{'ref'}->{'forms'}->[$j];
		}
	}
	
	return $coveredRefIdxs;
}

#####
#
#####
sub updateOrderErrors {
	my ($currstats, $tuple, $refCovIdxs) = @_;
	
	my $refRank = 0;
	for my $refk (sort { $a <=> $b } keys %$refCovIdxs) {
		$refCovIdxs->{$refk} = ++$refRank;
	}
	
	my $sumOfSquareDiffs = 0;
	
	my $hypRank = 0;
	for my $i (0..$#{$tuple->{'alignment'}}) {
		my $alpt = $tuple->{'alignment'}->[$i];
		
		if ($alpt != 0) {
			my $diff = ++$hypRank - $refCovIdxs->{$alpt};
			$sumOfSquareDiffs += $diff ** 2;
		}
	}
	
	if ($hypRank < 2) {
		return;
	}
	
	#original: -1..1
	#$currstats->{'spearman'} = 1 - (6 * $sumOfSquareDiffs / ($hypRank * ($hypRank ** 2 - 1)));
	#scaled: 0..1
	#$currstats->{'spearman'} = 1 - (3 * $sumOfSquareDiffs / ($hypRank * ($hypRank ** 2 - 1)));
	#scaled: -N..N, N -- number of aligned words
	#$currstats->{'spearman'} = $hypRank - (6 * $sumOfSquareDiffs / ($hypRank ** 2 - 1));
	#scaled: 0..N, N -- number of aligned words
	$currstats->{'spearman'} = $hypRank - (3 * $sumOfSquareDiffs / ($hypRank ** 2 - 1));

	$currstats->{'totalspearman'} = $hypRank;
}

#####
#
#####
sub dumpRef {
	my ($coveredRefIdxs, $ref) = @_;
	
	my $refWordStr = "Reference :";
	my $refIdxStr  = "   indexes:";
	my $missingStr = "   missing:";
	
	for my $i (0..$#$ref) {
		my $currWord = $ref->[$i];
		
		while (length($currWord) < 2) {
			$currWord = " " . $currWord;
		}
		
		my $len = length($currWord);
		my $truidx = $i + 1;
		
		$refWordStr .= "  " . $currWord;
		$refIdxStr .= "  " . sprintf("%" . $len . "d", $truidx);
		$missingStr .= "  " . sprintf("%" . $len . "s", ($coveredRefIdxs->{$truidx}? " ": "X"));
	}
	
	print $refWordStr . "\n";
	print $refIdxStr . "\n";
	print $missingStr . "\n";
}

#####
#
#####
sub dumpHyp {
	my $tuple = shift;
	
	my $hyp = $tuple->{'hyp'}->{'forms'};
	my $ali = $tuple->{'alignment'};
	
	my $hypAlStr   = " alignment:";
	my $hypIdxStr  = "   indexes:";
	my $hypWordStr = "Hypothesis:";
	my $wrongStr   = " wrong/oov:";
	
	for my $i (0..$#$hyp) {
		my $currWord = $hyp->[$i];
		
		while (length($currWord) < 2) {
			$currWord = " " . $currWord;
		}
		
		my $len = length($currWord);
		my $truidx = $i + 1;
		my $alpt = $ali->[$i];
		
		$hypWordStr .= "  " . $currWord;
		$hypIdxStr .= "  " . sprintf("%" . $len . "d", $truidx);
		$hypAlStr .= "  " . sprintf("%" . $len . "d", $alpt);
		
		my $wrongnessId = " ";
		
		if ($alpt == 0) {
			$wrongnessId = $tuple->{'extra'}->{$i}? "X": "?";
		}
		
		$wrongStr .= "  " . sprintf("%" . $len . "s", $wrongnessId);
	}
	
	print "--------------------------------------------------------------------------------------------------------\n";
	print $hypAlStr . "\n";
	print $hypWordStr . "\n";
	print $hypIdxStr . "\n";
	print $wrongStr . "\n";
}

#####
#
#####
sub dumpSntInfo {
	my ($coveredRefIdxs, $tuple) = @_;
	
	dumpRef($coveredRefIdxs, $tuple->{'ref'}->{'forms'});
	dumpHyp($tuple);
	
	print "========================================================================================================\n";
}

#####
#
#####
sub update {
	my $tuple = shift;
	my $stats = shift;
	
	alignSntTuple($tuple);
	
	my $currstats = {};
	
	$currstats->{'totalref'} = scalar @{$tuple->{'ref'}->{'forms'}};
	$currstats->{'totalhyp'} = scalar @{$tuple->{'hyp'}->{'forms'}};
	
	my $coveredRefIdxs = updateWordErrors($currstats, $tuple);
	
	updateOrderErrors($currstats, $tuple, $coveredRefIdxs);
	
	if ($opts::dumpEachSnt) {
		dumpSntInfo($coveredRefIdxs, $tuple);
	}
	
	submitStatChunk($currstats, $stats);
}

#####
#
#####
sub reportSome {
	my ($stats, $totalId, $valueId, $headTitle) = @_;
	
	if (!$headTitle) {
		$headTitle = $valueId;
	}
	
	my $total = $stats->{$totalId};
	my $valueHash = $stats->{$valueId};
	my $value = 0;
	
	my $result = "";
	
	for my $k (sort keys %$valueHash) {
		my $currVal = $valueHash->{$k};
		
		$result .=
			"\n    " .
			sprintf("%-11s: %7.2f%% (%8d / %8d)", $k, 100*$currVal/$total, $currVal, $total);
		
		$value += $currVal;
	}
	
	if ($value != 0) {
		printf("%-11s: %7.2f%% (%8d / %8d)%s\n", $headTitle, 100 * $value / $total, $value, $total, $result);
	}
	
}

#####
#
#####
sub fpercentage {
	my ($stats, $totalId, $valueId) = @_;
	
	my $total = $stats->{$totalId};
	my $value = $stats->{$valueId};
	
	return sprintf("%7.2f%% (%8.2f / %8.2f)", 100*$value/$total, $value, $total);
}

#####
#
#####
sub display {
	my $stats = shift;
	
	reportSome($stats, 'totalref', 'missing') . "\n";
	reportSome($stats, 'totalhyp', 'untranslated') . "\n";
	reportSome($stats, 'totalhyp', 'wrongform') . "\n";
	reportSome($stats, 'totalhyp', 'extra') . "\n";
	
	printf ("Order similarity: %.5f\n", ($stats->{'spearman'} / $stats->{'totalspearman'}));
	
	
}

1;
