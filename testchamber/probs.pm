package probs;
use strict;
use const;
use io;

#####
#
#####
sub genInitPs {
	my $size = shift;
	my $hash = {};
	
	for my $i (-1..($size-1)) {
		$hash->{$i} = 1.0 / ($size + 1);
	}
	
	return $hash;
}

#####
#
#####
sub getTransWeight {
	my ($prev, $curr) = @_;
	
	#prev cannot be unaligned (-1) while decoding, since
	#the next non-nil alignment is used, but
	#just in case:
	if ($prev == -1 or $curr == -1) {
		return 1;
	}
	
	#since we do only 1-to-1 alignment with no
	#repetitions, current cannot be the same as
	#previous
	if ($prev == $curr) {
		return 0;
	}
	
	#distortion penalty -- the closer, the smaller
	return 2 ** (-abs($curr - $prev - 1)*2);
}

#####
#
#####
sub genTransPs {
	my $size = shift;
	my $hash = {};
	
	for my $i (-1..($size-1)) {
		my $denom = 0;
		
		for my $j (-1..($size-1)) {
			$denom += getTransWeight($i, $j);
		}
		
		for my $j (-1..($size-1)) {
			$hash->{$i}->{$j} = getTransWeight($i, $j) / $denom;
		}
	}
	
	return $hash;
}

#####
#
#####
sub addEqTokPts {
	my ($ptMap, $refSnt, $hypSnt, $alFactor) = @_;
	
	for my $hypIdx (0..$#$hypSnt) {
		my $hypw = $hypSnt->[$hypIdx];
		my $hypf = io::getWordFactor($hypw, $alFactor);
		
		for my $refIdx (0..$#$refSnt) {
			my $refw = $refSnt->[$refIdx];
			my $reff = io::getWordFactor($refw, $alFactor);
			
			if ($hypf eq $reff) {
				$ptMap->{$hypIdx}->{$refIdx}++;
			}
		}
	}
}

#####
#
#####
sub getRefAlCounts {
	my ($ptMap) = @_;
	
	#calculate nr. of connections for each ref point
	my $refAlCounts = {};
	
	for my $hyp (keys %$ptMap) {
		my $ptHypMap = $ptMap->{$hyp};
		
		for my $ref (keys %$ptHypMap) {
			$refAlCounts->{$ref}++;
		}
	}
	
	return $refAlCounts;
}

#####
#
#####
sub toUnalignOrNotToUnalign {
	my ($ptMap, $refAlCounts) = @_;
	
	#if a hyp point is connected to at least one ref point which has
	#more than one connections, then that hyp point has to be allowed
	#to be left unaligned
	for my $hyp (keys %$ptMap) {
		my $ptHypMap = $ptMap->{$hyp};
		
		my $canBeUnaligned = undef;
		
		for my $ref (keys %$ptHypMap) {
			if ($refAlCounts->{$ref} > 1) {
				$canBeUnaligned = 1;
			}
		}
		
		if ($canBeUnaligned) {
			$ptHypMap->{-1} = $const::SEEN_UNAL_PROB;
		}
	}
}

#####
#
#####
sub postProcMap {
	my ($ptMap, $uwPts) = @_;
	
	for my $hyp (keys %$ptMap) {
		my $ptHypMap = $ptMap->{$hyp};
		
		for my $ref (keys %$ptHypMap) {
			$ptHypMap->{$ref} = ($uwPts)? 1: $ptHypMap->{$ref} ** 2;
		}
	}
}

#####
#
#####
sub setProb {
	my ($hash, $hypIdx, $refIdx, $prob) = @_;
	
	#print STDERR "PROB p($refIdx | $hypIdx) = $prob;\n";
	$hash->[$hypIdx]->{$refIdx} = $prob;
}

#####
#
#####
sub genEmitPs {
	my ($refSnt, $hypSnt, $alFactor, $ptMap, $exPts, $uwPts) = @_;
	
	if (!$exPts) {
		addEqTokPts($ptMap, $refSnt, $hypSnt, $alFactor);
	}
	
	postProcMap($ptMap, $uwPts);
	
	my $refAlCounts = getRefAlCounts($ptMap);
	
	toUnalignOrNotToUnalign($ptMap, $refAlCounts);
	
	my $result = [];
	
	for my $hypIdx (0..$#$hypSnt) {
		if ($ptMap->{$hypIdx} > 0) {
			my $sum = 0.0;
			my $ptHypMap = $ptMap->{$hypIdx};
			
			for my $refConn (keys %$ptHypMap) {
				$sum += $ptHypMap->{$refConn};
			}
			
			for my $refConn (keys %$ptHypMap) {
				setProb($result, $hypIdx, $refConn,
					$ptHypMap->{$refConn} / $sum);
			}
		}
		else {
			setProb($result, $hypIdx, -1, 1.0);
		}
	}
	
	return $result;
}

#####
#
#####
sub stophere {
	my $arr = shift;
	
	for my $x (0..$#$arr) {
		my $xh = $arr->[$x];
		
		for my $y (keys %$xh) {
			print "$x - $y: " . $xh->{$y} . ";\n";
		}
	}
	
	die('ok');
}

#####
#
#####
sub generate {
	my ($refSnt, $hypSnt, $alFactor, $morePts, $exPts, $uwPts) = @_;
	
	my $refSize = scalar @$refSnt;
	
	my $result = {};
	
	$result->{'init'} = genInitPs($refSize);
	$result->{'trans'} = genTransPs($refSize);
	$result->{'emit'} = genEmitPs($refSnt, $hypSnt, $alFactor, $morePts, $exPts, $uwPts);
	
	return $result;
}

1;
