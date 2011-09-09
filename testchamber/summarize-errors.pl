#!/usr/bin/perl
use strict;

#
# produces a summary table of error frequencies from Hjerson't output format:
#
# 1::ref-err-cats: the reord~~total reord~~amount miss~~designated for assistance to reord~~the reord~~system is to be divided into two parts .  
# 1::hyp-err-cats: the for reord~~the reord~~system to help ext~~certain reord~~total reord~~amount will be divided into two parts .  
# 
# 2::ref-err-cats: lex~~there infl~~are price lex~~and qualitative categories here reord~~as reord~~well .  
# 2::hyp-err-cats: lex~~here too there infl~~is price and quality categories .  
# ...
#

my $stats;
my $sizes;

while (<STDIN>) {
	s/\n//g;
	
	my @tokens = split(/ /);
	
	my $rawClass = shift @tokens;
	
	my ($idx, $class) = split(/::/, $rawClass, 2);
	
	for my $token (@tokens) {
		$sizes->{$class}++;
		
		if ($token =~ /~~/) {
			my ($flag, $word) = split(/~~/, $token, 2);
			
			$stats->{$class}->{$flag}++;
		}
	}
}

printf("%-12s %-12s %-6s %-s\n\n", "file", "error-flag", "count", "frequency");

for my $class (sort keys %$stats) {
	for my $flag (sort keys %{$stats->{$class}}) {
		printf("%-12s %-12s %-6d %-.3f%%\n", $class, $flag,
			$stats->{$class}->{$flag},
			$stats->{$class}->{$flag} / $sizes->{$class});
	}
	print "\n";
}
