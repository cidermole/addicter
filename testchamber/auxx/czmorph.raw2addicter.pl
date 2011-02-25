#!/usr/bin/perl
use strict;
use utf8;

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

while (<STDIN>) {
	s/\n//g;
	$_ = lc($_);

	my @newwords = ();
	
	for my $word (split(/ /)) {
		my ($form, $lemma, $tag) = split(/\|/, $word);
		
		if ($lemma =~ /^([[:alnum:]]+)([^[:alnum:]].*)$/) {
			$lemma = $1;
			my $fixCode = $2;
			
			$lemma = tryFixLemma($lemma, $fixCode);
		}
		
		if ($tag =~ /^[acdnvx]/) {
			$tag = "content";
		}
		elsif ($tag =~ /^z/) {
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

#####
#
#####
sub tryFixLemma {
	my ($lemma, $fixCode) = @_;
	
	#zaprášený_^(*3it)
	if ($fixCode =~ /\(\*([0-9]+)([^)]*)\)/) {
		my ($size, $repl) = ($1, $2);
		
		$lemma =~ s/.{$size}$/$repl/g;
	}
	
	return $lemma;
}
