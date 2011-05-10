package ordersim;
use strict;
use Carp; # confess() debugs better than die()
use unscramble;
use const;
use io;

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
sub getOrderErrs {
	my ($ref, $hyp, $al) = @_;
	
	my $permList = unscramble::getListOfPermutations($al);
	
	my $hypIdxMap = getHypRefAlMap($al);
	
	my $output = permutationToErrs($permList, $hypIdxMap, $hyp);
	
	my $metrics = getSimilarityMetrics($al, $hyp);
	
	return (defined($output) and (scalar @$output > 0))?
		[@$metrics, "", @$output]:
		$metrics;
}

#####
#
#####
sub permutationToErrs {
	my ($permList, $hypIdxMap, $hyp) = @_;
	
	my @output = ();
	
	#for my $permutation (@$permList) {
	for my $permutation (sort { $a->{'refidx1'} <=> $b->{'refidx1'} } @$permList) {
		if ($permutation->{'switch'}) {
			my $idx1 = $hypIdxMap->[$permutation->{'refidx1'}];
			my $idx2 = $hypIdxMap->[$permutation->{'refidx2'}];
            # DZ: I got index out of bounds on my data.
            confess("hyp[0..$#{$hyp}], idx1=$idx1, idx2=$idx2") if($idx1<0 || $idx1>$#{$hyp} || $idx2<0 || $idx2>$#{$hyp});
			my $tok1 = io::tok2str4xml($hyp->[$idx1]);
			my $tok2 = io::tok2str4xml($hyp->[$idx2]);
			
			push @output, "<ordErrorSwitchWords hypIdx1=\"$idx1\" hypIdx2=\"$idx2\"" .
				" distance=\"" . abs($idx1 - $idx2) . "\"" .
				" hypToken1=\"$tok1\" hypToken2=\"$tok2\"/>";
		}
		else {
			my $hypPos = $hypIdxMap->[$permutation->{'refidx1'}];
			my $hypTok = io::tok2str4xml($hyp->[$hypPos]);
			my $targetHypPos = $hypIdxMap->[$permutation->{'refidx2'}];
			my $rawShiftWidth = $targetHypPos - $hypPos;
			
			push @output, "<ordErrorShiftWord hypPos=\"$hypPos\" hypToken=\"$hypTok\" distance=\"" .
				abs($rawShiftWidth) . "\" direction=\"" .
				(($rawShiftWidth > 0)? "towardsEnd": "towardsBeginning") . "\"/>";
		}
	}
	
	return \@output;
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
sub getSimilarityMetrics {
	my ($al, $hyp) = @_;
	
	my $rho = getSpearmanRho($al);
	my $fmtRho = sprintf("%.3f", $rho);
	
	my $rhoText = "<ordSimMetrics spearmansRho=\"" .
		(defined($rho)? $fmtRho: "undef") . "\"/>";
	
	return [$rhoText];
}

1;
