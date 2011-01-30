package beamsearch;
use strict;
use const;

#####
#
#####
sub dlog {
	#print STDERR $_[0] . "; " . `date`;
}

#####
#
#####
sub dstatelog {
	my ($state, $msg) = @_;
	my $ali = $state->{'alignment'};
	dlog($msg . " -- prob: " . $state->{'prob'} . ", pos: " . $state->{'pos'} . ", alignment: @$ali"
		. ", last point: =|" . $ali->[$#$ali] . "|=");
}

#####
#
#####
sub genInitState {
	return { 'prob' => 0, 'alignment' => [], 'pos' => 0 };
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
sub sameCoverage {
	my ($state1, $state2) = @_;
	
	return (getCoverString($state1) eq getCoverString($state2));
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
		if (sameCoverage($state, $existingState)) {
			if ($state->{'prob'} > $existingState->{'prob'}) {
				$existingState->{'prob'} = $state->{'prob'};
				$existingState->{'alignment'} = $state->{'alignment'};
			}

			return;
		}
	}
	
	if ((scalar @{$queue->{$pos}}) < $const::BEAM_WIDTH) {
		unshift @{$queue->{$pos}}, $state;
	}
	else {
		my $minIdx = -1;
		my $minProb = 0;
		
		for my $i (0..$#{$queue->{$pos}}) {
			my $thisState = $queue->{$pos}->[$i];
			
			if ($thisState->{'prob'} < $minProb) {
				$minIdx = $i;
				$minProb = $thisState->{'prob'};
			}
		}
		
		if ($minProb < $state->{'prob'}) {
			$queue->{$pos}->[$minIdx] = $state;
		}
	}
}

#####
#
#####
sub countStates {
	my $queue = shift;
	my $msg = shift;
	my $result = 0;
	
	dlog("---------------");
	dlog($msg);
	
	for my $k (sort { $a <=> $b } keys %$queue) {
		my $currSize = scalar @{$queue->{$k}};
		$result += $currSize;
		dlog("$k: $currSize");
	}
	
	dlog("---------------");
	
	return $result;
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
	
	dlog("returning $state\n");
	
	return $state;
}

#####
#
#####
sub isFinalState {
	my ($state, $tuple) = @_;
	
	return ($state->{'pos'} == (scalar @{$tuple->{'hyp'}->{'lemmas'}}));
}

#####
#
#####
sub getLastNonZeroPoint {
	my $alignment = shift;
	
	my $i = $#$alignment;
	my $result = 0;
	
	while ($i > 0 and !($result = $alignment->[$i])) {
		$i--;
	}
	
	return $result;
}

#####
#
#####
sub genNextStates {
	my ($tuple, $probs, $currState) = @_;
	
	my $currPos = $currState->{'pos'};
	my $currAlignment = $currState->{'alignment'};
	my $currAlPoint = getLastNonZeroPoint($currAlignment);
	
	my $nextHypWord = $tuple->{'hyp'}->{'lemmas'}->[$currPos]; #($currPos - 1) + 1
	
	my $result = [];
	
	for my $refIdx (0..(scalar @{$tuple->{'ref'}->{'lemmas'}})) {
		if ($refIdx == 0 or grep(/^\Q$refIdx\E$/, @$currAlignment) == 0) {
			my $newProb = $probs->{'emit'}->{$nextHypWord}->{$refIdx} * $probs->{'trans'}->{$currAlPoint}->{$refIdx};
			
			if ($newProb != 0) {
				my $newstate = {
					'prob' => $currState->{'prob'} + log($newProb),
					'pos' => $currPos + 1,
					'alignment' => [@$currAlignment, $refIdx]};
				push @$result, $newstate;
			}
		}
	}
	
	return $result;
}

sub decodeAlignment {
	return decode(@_);
}

#####
#
#####
sub decode {
	my ($tuple, $probs) = @_;
	
	my $stateQueue = {};
	pushState(genInitState(), $stateQueue);
	
	my $finalState = { 'prob' => -10e600 };
	
	my $currState;
	
	while ($currState = popState($stateQueue)) {
		
		my $nextStates = genNextStates($tuple, $probs, $currState);
		
		for my $nextState (@$nextStates) {
			if (isFinalState($nextState, $tuple)) {
				if ($nextState->{'prob'} > $finalState->{'prob'}) {
					$finalState = $nextState;
				}
			}
			else {
				pushState($nextState, $stateQueue);
			}
		}
	}
	
	return $finalState->{'alignment'};
}

1;
