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
sub findMin {
	my $posqueue = shift;
	
	my $minIdx = -1;
	my $minProb = 0;
	
	for my $i (0..$#{$posqueue}) {
		my $thisState = $posqueue->[$i];
		
		if ($thisState->{'prob'} < $minProb) {
			$minIdx = $i;
			$minProb = $thisState->{'prob'};
		}
	}
	
	return ($minIdx, $minProb);
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
		my ($minIdx, $minProb) = findMin($queue->{$pos});
		
		if ($minProb < $state->{'prob'}) {
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

#####
#
#####
sub decodeAlignment {
	my ($refSnt, $hypSnt, $alFactor, $probs) = @_;
	
	my $auxinfo = {
		'refsnt' => $refSnt,
		'hypsnt' => $hypSnt,
		'alfact' => $alFactor,
		'probs' => $probs};
	
	my $result = decode(genAlInitState(), $auxinfo,
		\&genAlNextStates, \&isAlFinalState);
	
	return $result->{'alignment'};
}

#####
#
#####
sub isAlFinalState {
	my ($state, $auxinfo) = @_;
	
	my $hypsnt = $auxinfo->{'hypsnt'};
	
	return ($state->{'pos'} == $#$hypsnt);
}

#####
#
#####
sub getLastNonNilPoint {
	my $alignment = shift;
	
	my $i = $#$alignment;
	
	while ($i >= 0 and ($alignment->[$i] == -1)) {
		$i--;
	}
	
	return ($i < 0)? -1: $alignment->[$i];
}

#####
#
#####
sub genAlNextStates {
	my ($currState, $auxinfo) = @_;
	
	my $refSnt = $auxinfo->{'refsnt'};
	
	my $nextPos = $currState->{'pos'} + 1;
	my $currAlignment = $currState->{'alignment'};
	my $currAlPoint = getLastNonNilPoint($currAlignment);
	
	my $nextHypWord = io::getWordFactor($auxinfo->{'hypsnt'}->[$nextPos], $auxinfo->{'alfact'});
	
	my $result = [];
	
	for my $refIdx (-1..$#$refSnt) {
		if ($refIdx == -1 or grep(/^\Q$refIdx\E$/, @$currAlignment) == 0) {
			my $newProb =
				$auxinfo->{'probs'}->{'emit'}->{$nextHypWord}->{$refIdx} *
				$auxinfo->{'probs'}->{'trans'}->{$currAlPoint}->{$refIdx};
			
			if ($newProb != 0) {
				my $newstate = genNewAlState($currState->{'prob'} + log($newProb),
					[@$currAlignment, $refIdx], $nextPos);
				push @$result, $newstate;
			}
		}
	}
	
	return $result;
}

#####
#
#####
sub getCoverString {
	my $state = shift;
	my $al = $state->{'alignment'};
	my @cleanAl = grep(!/^\Q0\E$/, @$al);
	my @sortAl = sort { $a <=> $b } @cleanAl;
	return "@sortAl";
}

#####
#
#####
sub genNewAlState {
	my ($prob, $al, $pos) = @_;
	my $newstate = { 'prob' => $prob, 'alignment' => $al, 'pos' => $pos };
	$newstate->{'hash'} = getCoverString($newstate);
	return $newstate;
}

#####
#
#####
sub genAlInitState {
	return genNewAlState(0, [], -1);
}

1;
