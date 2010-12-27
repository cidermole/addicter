package probs;
use strict;
use const;

#####
#
#####
sub sntHasWord {
	my $snt = shift;
	my $word = shift;
	
	return (grep(/^\Q$word\E$/, @$snt) > 0);
}

#####
#
#####
sub genInitPs {
	my $size = shift;
	my $hash = {};
	
	for my $i (0..$size) {
		$hash->{$i} = 1.0 / ($size + 1);
	}
	
	return $hash;
}

#####
#
#####
sub getTransWeight {
	my ($prev, $curr) = @_;
	
	if ($prev == 0) {
		return 1;
	}
	
	if ($prev == $curr) {
		return 0;
	}
	
	return 2 ** (-abs($curr - $prev - 1));
}

#####
#
#####
sub genTransPs {
	my $size = shift;
	my $hash = {};
	
	for my $i (0..$size) {
		my $denom = 0;
		
		for my $j (0..$size) {
			$denom += getTransWeight($i, $j);
		}
		
		for my $j (0..$size) {
			$hash->{$i}->{$j} = getTransWeight($i, $j) / $denom;
		}
	}
	
	return $hash;
}

#####
#
#####
sub isHypWordUnseen {
	my $word = shift;
	my $tuple = shift;
	
	return (sntHasWord($tuple->{'ref'}, $word)? undef: 1);
}

#####
#
#####
sub getTag {
	my ($word, $tuple) = @_;
	return isHypWordUnseen($word, $tuple)?
		$const::UNK_TAG: $word;
}
#####
#
#####
sub getInfoHash {
	my $tuple = shift;
	my $hash = {};
	
	for my $word (@{$tuple->{'hyp'}}) {
		$hash->{getTag($word, $tuple)}++;
	}
	
	return $hash;
}

#####
#
#####
sub genEmitPs {
	my $tuple = shift;
	my $hash = {};
	
	my $refSize = scalar @{$tuple->{'ref'}};
	
	my $infoHash = $tuple->{'infohash'};
	
	for my $hypWord (@{$tuple->{'hyp'}}) {
		if (isHypWordUnseen($hypWord, $tuple)) {
			$hash->{$hypWord}->{0} = 1.0 / $infoHash->{$const::UNK_TAG};
		}
		else {
			my $currUnalignProb = ($infoHash->{$hypWord} == 1)? 0: $const::SEEN_UNAL_PROB;
			
			$hash->{$hypWord}->{0} = $currUnalignProb;
			
			for my $class (1..$refSize) {
				$hash->{$hypWord}->{$class} =
					($hypWord eq $tuple->{'ref'}->[$class - 1])?
					(1.0 - $currUnalignProb) /
					$infoHash->{$hypWord}:
					0;
			}
		}
	}
	
	return $hash;
}

#####
#
#####
sub generate {
	my $tuple = shift;
	
	my $refSize = scalar @{$tuple->{'ref'}};
	
	my $result = {};
	
	$tuple->{'infohash'} = getInfoHash($tuple);
	$result->{'init'} = genInitPs($refSize);
	$result->{'trans'} = genTransPs($refSize);
	$result->{'emit'} = genEmitPs($tuple);
	
	return $result;
}

1;
