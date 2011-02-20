#!/usr/bin/perl
use strict;
use utf8;

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

while (<STDIN>) {
	s/\n//g;
	
	my @newwords = ();
	
	for my $word (split(/ /)) {
		my ($form, $lemma, $tag) = split(/\|/, $word);
		
		if ($lemma =~ /^([[:alnum:]]+)[^[:alnum:]].*$/) {
			$lemma = $1;
		}
		
		if ($tag =~ /^[ACDNVX]/) {
			$tag = "content";
		}
		elsif ($tag =~ /^Z/) {
			$tag = "punct";
		}
		else {
			$tag = "aux";
		}
		
		push @newwords, "$form|$tag|$lemma";
	}
	
	print join(" ", @newwords);
	print "\n";
}
