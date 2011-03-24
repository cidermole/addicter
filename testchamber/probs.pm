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
sub getAllowedPoints {
	my ($refSnt, $hypSnt, $alFactor, $morePts) = @_;
	
	my $result = {};
	my $resultx = {};
	
	for my $hypIdx (0..$#$hypSnt) {
		my $hypw = $hypSnt->[$hypIdx];
		my $hypf = io::getWordFactor($hypw, $alFactor);
		
		my $covered = undef;
		
		for my $refIdx (0..$#$refSnt) {
			my $refw = $refSnt->[$refIdx];
			my $reff = io::getWordFactor($refw, $alFactor);
			
			if ($hypf eq $reff or defined($morePts) and $morePts->{$hypIdx}->{$refIdx}) {
				$result->{$hypIdx}->{$refIdx} = 1;
				$resultx->{$refIdx}->{$hypIdx} = 1;
				$covered = 1;
			}
		}
		
		unless ($covered) {
			#print "$hypIdx is unseen\n";
			$result->{-1}++;
		}
	}
	
	return ($result, $resultx);
}

#####
#
#####
sub setProb {
	my ($hash, $hypIdx, $refIdx, $prob) = @_;
	
	$hash->[$hypIdx]->{$refIdx} = $prob;
	#print STDERR "PROB p($refIdx | $hypIdx) = $prob;\n";
}
#####
#
#####
sub genEmitPs {
	my ($refSnt, $hypSnt, $alFactor, $morePts) = @_;
	
	my ($hrAllowedPoints, $rev) = getAllowedPoints($refSnt, $hypSnt, $alFactor, $morePts);
  
	my $result = [];
	
	for my $hypIdx (0..$#$hypSnt) {
		my $canAlignTo = $hrAllowedPoints->{$hypIdx};
		
		if ($canAlignTo) {
			my @refPts = keys %$canAlignTo;
			my $refPtNum = scalar @refPts;
			my $allowUnalign = undef;
			
			for my $refPrePt (@refPts) {
				if (scalar keys %{$rev->{$refPrePt}} > 1) {
					$allowUnalign = 1;
				}
			}
			
			my $unalProb = $allowUnalign? $const::SEEN_UNAL_PROB: 0;
			
			if ($allowUnalign) {
				setProb($result, $hypIdx, -1, $unalProb);
			}
			
			my $probForOthers = (1 - $unalProb) / $refPtNum;
			
			for my $refPt (@refPts) {
				setProb($result, $hypIdx, $refPt, $probForOthers);
			}
		}
		else {
			setProb($result, $hypIdx, -1, 1.0 / $hrAllowedPoints->{-1});
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
	my ($refSnt, $hypSnt, $alFactor, $morePts) = @_;
	
	my $refSize = scalar @$refSnt;
	
	my $result = {};
	
	$result->{'init'} = genInitPs($refSize);
	$result->{'trans'} = genTransPs($refSize);
	$result->{'emit'} = genEmitPs($refSnt, $hypSnt, $alFactor, $morePts);
	
	return $result;
}

1;
