package math;
use strict;

#####
#
#####
sub min {
	my ($a, $b) = @_;
	
	return ($a > $b)? $b: $a;
}

#####
#
#####
sub max {
	my ($a, $b) = @_;
	
	return ($a < $b)? $b: $a;
}

1;
