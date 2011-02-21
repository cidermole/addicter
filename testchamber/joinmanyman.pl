#!/usr/bin/perl
use strict;
use File::Spec;
use Getopt::Long;

BEGIN {
	#include packages from same folder where the
	#script is, even if launched from elsewhere
	
	my @dirs = File::Spec->splitdir(File::Spec->rel2abs(File::Spec->canonpath($0)));
	pop @dirs;
	push(@INC, File::Spec->catdir(@dirs));
}

use io;
use flagg;
use parse;

my $prevId = undef;
my $fhyp = undef;

while (<STDIN>) {
	s/\n//g;
	
	if (/^([0-9]+\t[^ \t]+\t)([^\t].*)$/) {
		my $info = $1;
		my $text = $2;
		$text =~ s/\t/ /g;
		$_ = "$info\t$text";
	}
	
	if (/^([0-9]+\t[^ ]+\t\t)(.*)$/) {
		my $currId = $1;
		my $snt = $2;
		
		if ($currId ne $prevId) {
			if (defined($prevId)) {
				print $prevId;
				flagg::display($fhyp);
			}
			$fhyp = undef;
		}
		
		my $currfhyp = parse::flagg($snt);
		
		if ($fhyp) {
			flagg::append($fhyp, $currfhyp);
		}
		else {
			$fhyp = flagg::clone($currfhyp);
		}
		
		$prevId = $currId;
	}
	else {
		die("Failed to parse `$_'");
	}
}

print $prevId;
flagg::display($fhyp);
