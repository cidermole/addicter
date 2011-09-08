#!/usr/bin/perl
use strict;
#cu-bojar.man  cu-tectomt.man  google.man  pctrans.man

#ref: 4353
#hyp: 4276   4265   4646   4478

#missA 111	138	84	96	
#missC 199	108	72	42	

my $missData = {
'missA' => [111,138, 84,96],
'missC' => [199,108, 72,42],
	};

my $lexData = {
'punct' => [118,155,110,111],
'extra' => [311,395,383,350],
'unk' => [53,97,51,56],
'form' => [726,703,776,759],
'lex' => [587,999,617,800],
'ows' => [100,155,117,157],
'owl' => [57,44,43,50],
'ops' => [14,15,26,25],
'opl' => [11,13,10,11]
};

printf "%8s  %9s%9s%9s%9s\n", "", "bojar", "tecto", "google", "pctrans";

for my $mk (keys %$missData) {
	printf "%8s: ", $mk;
	
	for my $md (@{$missData->{$mk}}) {
		printf "%8.2f%%", 100 * $md / 4353;
	}
	
	printf "\n";
}

for my $lk (keys %$lexData) {
	printf "%8s: ", $lk;
	
	for my $ld (@{$lexData->{$lk}}) {
		printf "%8.2f%%", 100 * $ld / 4353;
	}
	
	printf "\n";
}
