#!/usr/bin/perl
use strict;
use beamsearch;

my @arr = @ARGV;

#my $path = findBestPath(\@arr);
my $path = findBeamBestPath(\@arr);

my $currScore = $path->{'prob'};

print "cost: $currScore\n";

my $prevProb = 1;

while (defined($path)) {
	my $currProb = $path->{'prob'};
	
	#if ($currProb != $prevProb) {
		print "" . getSig($path->{'arr'}) . ", " . ($path->{'shiftpos'}) . " (" . ($path->{'prob'}) . ")\n";
		$prevProb = $currProb;
	#}
	
	$path = $path->{'prev'};
}

#####
#
#####
sub findBeamBestPath {
	my $arr = shift;
	
	return beamsearch::decode(genInitState($arr),
		undef, \&genNextStates, \&isEndState);
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
	my ($prob, $pos, $arr, $shiftPos, $prev) = @_;
	
	my $result = {
		'prob' => $prob,
		'pos' => $pos,
		'arr' => $arr,
		'shiftpos' => $shiftPos,
		'prev' => $prev};
	
	$result->{'hash'} = getSig($arr) . ":" .
		(defined($shiftPos)? $shiftPos: "-");
	
	return $result;
}

#####
#
#####
sub genInitState {
	my $arr = shift;
	
	return genNewState(0, 0, $arr, undef, undef);
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
	
	#return newState($prevState->{'steps'} + 1, $prevState, $newArr, $permPos, $prevState->{'cost'} + $stepCost);
	return genNewState($prevState->{'prob'} - $stepCost, $prevState->{'pos'} + 1, $newArr, $permPos, $prevState);
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
	
	for my $i (0..$#$arr) {
		if ($arr->[$i] != $i + 1) {
			return undef;
		}
	}
	
	return 1;
}
