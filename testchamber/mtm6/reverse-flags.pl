#!/usr/bin/perl
use strict;

#
# reverses flags and words in Hjerson's output;
#
# input: file like "an~~reord example~~reord this be~~infl"
#
# output: file like "reord~~an reord~~example this infl~~be"
#

while (<STDIN>) {
	s/\n//g;
	s/^ //g;
	s/ $//g;
	
	my @tokens = split(/ /);
	my @output = ();
	
	for my $token (@tokens) {
		my ($word, $flag) = split(/~~/, $token);
		push @output, ($flag eq "x"? "": $flag . "~~") . $word;
	}
	
	print join(" ", @output);
	print "\n";
}
