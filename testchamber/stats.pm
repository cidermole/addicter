package stats;
use strict;
use beamsearch;
use probs;

#####
#
#####
sub alignSntTuple {
	my $tuple = shift;
	
	my $time = time();
	
	my $probs = probs::generate($tuple);
	
	$tuple->{'alignment'} = beamsearch::decode($tuple, $probs);

	$time = time() - $time;

	#print "total: $time seconds\n";
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
	
	for my $k2 (qw(missing unknown wrong)) {
		$stats->{$k2} += $#{$currstats->{$k2}} + 1;
	}
}

#####
#
#####
sub updateUnalignedWords {
	my ($currstats, $tuple) = @_;
	
	my $coveredRefIdxs = {};
	
	for my $i (0..$#{$tuple->{'alignment'}}) {
		my $alPt = $tuple->{'alignment'}->[$i];
		
		#evaluating unknown/wrong hyp words
		if ($alPt == 0) {
			my $hypword = $tuple->{'hyp'}->[$i];
			
			my $idxToPushTo = (probs::sntHasWord($tuple->{'src'}, $hypword))? 'unknown': 'wrong';
			
			push @{$currstats->{$idxToPushTo}}, $hypword;
			$tuple->{$idxToPushTo}->{$i} = 1;
		}
		else {
			#for evaluating missing ref words
			$coveredRefIdxs->{$alPt} = 1;
		}
		
	}
	
	#evaluating missing ref words
	for my $j (0..$#{$tuple->{'ref'}}) {
		unless ($coveredRefIdxs->{$j + 1}) {
			push @{$currstats->{'missing'}}, $tuple->{'ref'}->[$j];
		}
	}
	
	return $coveredRefIdxs;
}

#####
#
#####
sub updateDistortion {
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
	
	my $hyp = $tuple->{'hyp'};
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
			$wrongnessId = $tuple->{'wrong'}->{$i}? "X": "?";
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
	
	dumpRef($coveredRefIdxs, $tuple->{'ref'});
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
	
	$currstats->{'totalref'} = scalar @{$tuple->{'ref'}};
	$currstats->{'totalhyp'} = scalar @{$tuple->{'hyp'}};
	
	my $coveredRefIdxs = updateUnalignedWords($currstats, $tuple);
	
	updateDistortion($currstats, $tuple, $coveredRefIdxs);
	
	if ($opts::dumpEachSnt) {
		dumpSntInfo($coveredRefIdxs, $tuple);
	}
	
	submitStatChunk($currstats, $stats);
}

#####
#
#####
sub percentage {
	my ($stats, $totalId, $valueId) = @_;
	
	my $total = $stats->{$totalId};
	my $value = $stats->{$valueId};
	
	return sprintf("%7.2f%% (%8d / %8d)", 100*$value/$total, $value, $total);
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
	
	print "Missing: " . percentage($stats, 'totalref', 'missing') . "\n";
	print "Unknown: " . percentage($stats, 'totalhyp', 'unknown') . "\n";
	print "Wrong:   " . percentage($stats, 'totalhyp', 'wrong') . "\n";
	printf ("Order similarity: %.5f\n", ($stats->{'spearman'} / $stats->{'totalspearman'}));
}

1;
