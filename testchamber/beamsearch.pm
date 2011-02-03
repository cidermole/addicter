package beamsearch;
use strict;
use const;

#####
#
#####
sub tmplog {
	print STDERR "DEBUG: @_;\n";
}

#####
#
#####
sub isStateLessProbable {
	my ($state, $testProb, $testSecProb, $nonstrictComparison) = @_;
	
	return (($state->{'prob'} < $testProb) or (
		($state->{'prob'} == $testProb) and
		($state->{'secprob'} < $testSecProb)) or (
			$nonstrictComparison and
			($state->{'prob'} == $testProb) and
			($state->{'secprob'} == $testSecProb)));
}

#####
#
#####
sub findMin {
	my $posqueue = shift;
	
	my $minIdx = -1;
	my $minProb = 0;
	my $minSecProb = 0;
	
	for my $i (0..$#{$posqueue}) {
		my $thisState = $posqueue->[$i];
		
		if (isStateLessProbable($thisState, $minProb, $minSecProb)) {
			$minIdx = $i;
			$minProb = $thisState->{'prob'};
			$minSecProb = $thisState->{'secprob'};
		}
	}
	
	return ($minIdx, $minProb, $minSecProb);
}

#####
#
#####
sub pushState {
	my ($state, $queue) = @_;
	
	my $pos = $state->{'pos'};
	
	if (!$queue->{$pos}) {
		$queue->{$pos} = [];
	}
	
	for my $existingState (@{$queue->{$pos}}) {
		if ($state->{'hash'} eq $existingState->{'hash'}) {
			if ($state->{'prob'} > $existingState->{'prob'}) {
				for my $key (keys %$existingState) {
					$existingState->{$key} = $state->{$key};
				}
			}

			return;
		}
	}
	
	if ((scalar @{$queue->{$pos}}) < $const::BEAM_WIDTH) {
		unshift @{$queue->{$pos}}, $state;
	}
	else {
		my ($minIdx, $minProb, $minSecProb) = findMin($queue->{$pos});
		
		if (!isStateLessProbable($state, $minProb, $minSecProb, 1)) {
			$queue->{$pos}->[$minIdx] = $state;
		}
	}
}

#####
#
#####
sub popState {
	my $queue = shift;
	
	if (!$queue) {
		return undef;
	}
	
	my @keys = sort { $a <=> $b } keys %$queue;
	
	if ((scalar @keys) == 0) {
		return undef;
	}
	
	my $key = $keys[0];
	my $arr = $queue->{$key};
	
	if ((scalar @$arr) == 0) {
		return undef;
	}
	
	my $state = pop @$arr;
	
	if (scalar @$arr == 0) {
		delete $queue->{$key};
	}
	
	return $state;
}

#####
#
#####
sub decode {
	my ($initstate, $auxinfo, $genNextStatesFunc, $isFinalStateFunc) = @_;
	
	my $stateQueue = {};
	pushState($initstate, $stateQueue);
	
	my $finalState = { 'prob' => -10e600 };
	
	my $currState;
	
	while ($currState = popState($stateQueue)) {
		
		my $nextStates = &$genNextStatesFunc($currState, $auxinfo);
		
		for my $nextState (@$nextStates) {
			if (&$isFinalStateFunc($nextState, $auxinfo)) {
				if ($nextState->{'prob'} > $finalState->{'prob'}) {
					$finalState = $nextState;
				}
			}
			else {
				pushState($nextState, $stateQueue);
			}
		}
	}
	
	return $finalState;
}

1;
