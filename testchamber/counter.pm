package counter;
use strict;

our $symb = randSymb(qw(. , > : ; < - ? ! * + / = ^ % $ # @ ~ _ | { } [ ]));

#####
#
#####
sub randSymb {
	return $_[int(rand() * (scalar @_))];
}

#####
#
#####
sub init {
	return { 'val' => 0 };
}

#####
#
#####
sub update {
	my $cnt = shift;
	
	my $counter = ++$cnt->{'val'};
	
	if ($counter % 10 == 0) {
		print STDERR $symb;
	}
	if ($counter % 100 == 0) {
		print STDERR "$counter\n";
	}
}

#####
#
#####
sub finish {
	my $cnt = shift;
	
	if ($cnt->{'val'} % 100 != 0) {
		print STDERR "" . $cnt->{'val'} . "\n";
	}
}

1;
