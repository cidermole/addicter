package beamsearch;
use strict;
use const;

#####
#
#####
sub tmplog {
	return;
	print STDERR "DEBUG: @_";
}

#####
#
#####
sub tmpstatelog {
	return;
	my $state = shift;
	
	print STDERR "DEBUG STATE: ";
	
	for my $k (qw(pos prob)) {
		print STDERR "$k => " . $state->{$k} . ", ";
	}
	my $ar = $state->{'alignment'};
	for my $i (0..$#$ar) {
		my $x = $ar->[$i];
		print STDERR "$i-$x/";
	}
	
	print STDERR "\n";
}

#####
#
#####
sub isStateLessProbable {
	my ($state, $testProb, $testSecProb, $nonstrictComparison) = @_;
	
	return (($state->{'prob'} < $testProb) or
		(($state->{'prob'} == $testProb) and
		 ($state->{'secprob'} < $testSecProb)) or
	 		($nonstrictComparison and
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
			tmplog("\t\tduplicate\n");
			
			if ($state->{'prob'} > $existingState->{'prob'}) {
				for my $key (keys %$existingState) {
					$existingState->{$key} = $state->{$key};
				}
				
				tmplog("\t\t\tinserted\n");
			}
			else {
				tmplog("\t\t\tdropped\n");
			}

			return;
		}
	}
	
	if ((scalar @{$queue->{$pos}}) < $const::BEAM_WIDTH) {
		tmplog("\t\tadded\n");
		unshift @{$queue->{$pos}}, $state;
	}
	else {
		tmplog("\t\toverflow\n");
		
		my ($minIdx, $minProb, $minSecProb) = findMin($queue->{$pos});
		
		if (!isStateLessProbable($state, $minProb, $minSecProb, 1)) {
			tmplog("\t\t\tinserted instead of ");
			tmpstatelog($queue->{$pos}->[$minIdx]);
			
			$queue->{$pos}->[$minIdx] = $state;
		}
		else {
			tmplog("\t\t\tdropped\n");
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
			tmpstatelog($nextState);
			
			if (&$isFinalStateFunc($nextState, $auxinfo)) {
				tmplog("\tfinal\n");
				if ($nextState->{'prob'} > $finalState->{'prob'}) {
					$finalState = $nextState;
					tmplog("\t\twon!\n");
				}
				else {
					tmplog("\t\tlost!\n");
				}
			}
			else {
				tmplog("\tinter\n");
				pushState($nextState, $stateQueue);
			}
		}
		tmplog("\n");
	}
	
	return $finalState;
}

1;
