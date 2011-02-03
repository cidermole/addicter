package unscramble;
use strict;
use beamsearch;

#####
#
#####
sub getListOfPermutations {
	my ($alignment) = @_;
	
	my $hypIdxArr = alignment2arr($alignment);
	
	my $path = beamsearch::decode(genInitState($hypIdxArr),
		undef, \&genNextStates, \&isEndState);
	
	return decryptPath($path);
}

#####
#
#####
sub decryptPath {
	my ($path) = @_;
	my @list = ();
	
	my ($startPos, $endPos) = (undef, undef);
	
	my $prevProb = 1;
	while (defined($path)) {
		my $currProb = $path->{'prob'};
		
		if ($prevProb != $currProb) {
			if (defined($endPos)) {
				my $isASwitch = ($startPos == $endPos);
				
				if ($startPos <= $endPos) {
					$startPos--;
				}
				else {
					$endPos--;
				}
					
				unshift @list, {
					'refidx1' => $path->{'arr'}->[$startPos],
					'refidx2' => $path->{'arr'}->[$endPos],
					'switch' => $isASwitch };
			}
			
			$endPos = $path->{'shiftpos'};
		}
		
		$startPos = $path->{'shiftpos'};
		
		$prevProb = $currProb;
		$path = $path->{'prev'};
	}
	
	return \@list;
}

#####
#
#####
sub alignment2arr {
	my ($alignment) = @_;
	
	my @result;
	for my $pair (sort { $a->{'hyp'} <=> $b->{'hyp'} } @$alignment) {
		push @result, $pair->{'ref'};
	}
	
	return \@result;
}

#####
#
#####
sub getSig {
	my $arr = shift;
	return join("-", @$arr);
}

#####
#
#####
sub genNewState {
	my ($prob, $pos, $arr, $shiftPos, $prev, $secondaryProb) = @_;
	
	my $result = {
		'prob' => $prob,
		'pos' => $pos,
		'arr' => $arr,
		'shiftpos' => $shiftPos,
		'prev' => $prev,
		'secprob' => $secondaryProb};
	
	$result->{'hash'} = getSig($arr) . ":" .
		(defined($shiftPos)? $shiftPos: "-");
	
	return $result;
}

#####
#
#####
sub genInitState {
	my $arr = shift;
	
	return genNewState(0, 0, $arr, undef, undef, 0);
}

#####
#
#####
sub genNextState {
	my ($prevState, $permPos) = @_;
	my $prevArr = $prevState->{'arr'};
	
	my $newArr = [@$prevArr];
	$newArr->[$permPos] = $prevArr->[$permPos - 1];
	$newArr->[$permPos - 1] = $prevArr->[$permPos];
	
	my $stepCost = 1;
	
	my $prevPermPos = $prevState->{'shiftpos'};
	
	if (defined($prevPermPos)) {
		my $gap = $prevPermPos - $permPos;
		
		if (abs($gap) == 1) {
			my $prevPrev = $prevState->{'prev'};
			
			if (!defined($prevPrev) or ($prevPrev->{'shiftpos'} != $permPos)) {
				$stepCost = 0;
			}
		}
	}
	
	return
		genNewState(
			$prevState->{'prob'} - $stepCost,
			$prevState->{'pos'} + 1,
			$newArr,
			$permPos,
			$prevState,
			(($stepCost == 0)? $prevState->{'secprob'} - 1: 0));
}

#####
#
#####
sub genNextStates {
	my $currState = shift;
	my $result = [];
	my $arr = $currState->{'arr'};
	
	for my $i (1..$#$arr) {
		if ($arr->[$i] < $arr->[$i - 1]) {
			push @$result, genNextState($currState, $i);
		}
	}
	
	return $result;
}

#####
#
#####
sub isEndState {
	my $state = shift;
	my $arr = $state->{'arr'};
	
	for my $i (1..$#$arr) {
		if ($arr->[$i] < $arr->[$i - 1]) {
			return undef;
		}
	}
	
	return 1;
}

1;
