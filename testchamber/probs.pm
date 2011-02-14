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
sub countWordClasses {
	my ($refSnt, $hypSnt, $alFactor) = @_;
	
	my $refWordHash = io::hashFactors($refSnt, $alFactor);
	
	#count words -- seen words as themselves, unseen words as "UNK"
	my $counthash = {};
	
	for my $hypw (@$hypSnt) {
		my $factor = io::getWordFactor($hypw, $alFactor);
		my $class = ($refWordHash->{$factor})? $factor: $const::UNK_TAG;
		$counthash->{$class}++;
	}
	
	return $counthash;
}

#####
#
#####
sub genEmitPs {
	my ($refSnt, $hypSnt, $alFactor) = @_;
	my $hash = {};
	
	my $refSize = scalar @$refSnt;
	
	my $wcCount = countWordClasses($refSnt, $hypSnt, $alFactor);
	
	for my $hypw (@$hypSnt) {
		my $hypf = io::getWordFactor($hypw, $alFactor);
		
		if ($wcCount->{$hypf}) {
			my $currUnalignProb = ($wcCount->{$hypf} == 1)? 0: $const::SEEN_UNAL_PROB;
			
			$hash->{$hypf}->{-1} = $currUnalignProb;
			
			for my $class (0..($refSize-1)) {
				$hash->{$hypf}->{$class} = ($hypf eq io::getWordFactor($refSnt->[$class], $alFactor))?
					(1.0 - $currUnalignProb) / $wcCount->{$hypf}: 0;
			}
		}
		else {
			$hash->{$hypf}->{-1} = 1.0 / $wcCount->{$const::UNK_TAG};
		}
	}
	
	return $hash;
}

#####
#
#####
sub generate {
	my ($refSnt, $hypSnt, $alFactor) = @_;
	
	my $refSize = scalar @$refSnt;
	
	my $result = {};
	
	$result->{'init'} = genInitPs($refSize);
	$result->{'trans'} = genTransPs($refSize);
	$result->{'emit'} = genEmitPs($refSnt, $hypSnt, $alFactor);
	
	return $result;
}

1;
