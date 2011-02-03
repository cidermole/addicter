package ordersim;
use strict;
use unscramble;

our %methodHash = (
	'individualChanges' => \&guessShiftsAndSwitches,
);

#####
#
#####
sub getDefaultMethod {
	return 'individualChanges';
}

#####
#
#####
sub testMethodId {
	my ($methodId) = @_;
	
	if (!defined($methodHash{$methodId})) {
		die("Method of analyzing order similary with id `$methodId' not defined");
	}
}

#####
#
#####
sub display {
	my ($ref, $hyp, $al, $mId) = @_;
	
	my $methodFunc = $methodHash{$mId};
	
	if (defined($methodFunc)) {
		return &$methodFunc($ref, $hyp, $al);
	}
	else {
		die("Strange, should have tested for this -- method with id `$mId' undefined");
	}
}

#####
#
#####
sub getHypRefAlMap {
	my ($al) = @_;
	
	my @result = ();
	
	for my $pt (@$al) {
		$result[$pt->{'ref'}] = $pt->{'hyp'};
	}
	
	return \@result;
}

#####
#
#####
sub guessShiftsAndSwitches {
	my ($ref, $hyp, $al) = @_;
	
	displaySimilarityMetrics($al, $hyp);
	
	my $permList = unscramble::getListOfPermutations($al);
	
	my $hypIdxMap = getHypRefAlMap($al);
	
	my $printedSome = undef;
	
	#for my $permutation (sort { $a->{'refidx1'} <=> $b->{'refidx1'} } @$permList) {
	for my $permutation (@$permList) {
		if (!$printedSome) {
			print "\n";
			$printedSome = 1;
		}
		
		if ($permutation->{'switch'}) {
			my $idx1 = $hypIdxMap->[$permutation->{'refidx1'}];
			my $idx2 = $hypIdxMap->[$permutation->{'refidx2'}];
			my $tok1 = io::tok2str4xml($hyp->[$idx1]);
			my $tok2 = io::tok2str4xml($hyp->[$idx2]);
			
			print "\t<ordErrorSwitchWords hypIdx1=\"$idx1\" hypIdx2=\"$idx2\"" .
				" distance=\"" . abs($idx1 - $idx2) . "\"" .
				" hypToken1=\"$tok1\" hypToken2=\"$tok2\"/>\n";
		}
		else {
			my $hypPos = $hypIdxMap->[$permutation->{'refidx1'}];
			my $hypTok = io::tok2str4xml($hyp->[$hypPos]);
			my $targetHypPos = $hypIdxMap->[$permutation->{'refidx2'}];
			my $rawShiftWidth = $targetHypPos - $hypPos;
			
			print "\t<ordErrorShiftWord hypPos=\"$hypPos\" hypToken=\"$hypTok\" distance=\"" .
				abs($rawShiftWidth) . "\" direction=\"" .
				(($rawShiftWidth > 0)? "towardsEnd": "towardsBeginning") . "\"/>\n";
		}
	}
}

#####
#
#####
sub addRank {
	my ($al, $id) = @_;
	
	my $rank = 0;
	for my $pt (sort { $a->{$id} <=> $b->{$id} } @$al) {
		$pt->{$id . 'rank'} = ++$rank;
	}
}

#####
#
#####
sub getSpearmanRho {
	my ($al) = @_;
	
	my $size = scalar @$al;
	
	if ($size == 0) {
		return undef;
	}
	elsif ($size == 1) {
		return 1;
	}
	else {
		addRank($al, 'ref');
		addRank($al, 'hyp');
		
		my $sumOfSqDiffs = 0;
		
		for my $pt (@$al) {
			$sumOfSqDiffs += ($pt->{'refrank'} - $pt->{'hyprank'}) ** 2;
		}
		
		return (1 - 6 * $sumOfSqDiffs / ($size * ($size ** 2 - 1)));
	}
}

#####
#
#####
sub displaySimilarityMetrics {
	my ($al, $hyp) = @_;
	
	my $rho = getSpearmanRho($al);
	my $fmtRho = sprintf("%.3f", $rho);
	
	print "\n\t<ordSimMetrics spearmansRho=\"" . (defined($rho)? $fmtRho: "undef") . "\"/>\n";
}

1;
