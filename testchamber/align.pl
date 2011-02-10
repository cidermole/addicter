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
use parse;
use probs;
use beamsearch;
use counter;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my ($reffile, $hypfile, $caseSensitive, $alFactor) =
	processInputArgsAndOpts();

my ($fhRef, $fhHyp) = io::openMany($reffile, $hypfile);
my $tuple;
my $cnt = counter::init();

while($tuple = io::readSentences($fhRef, $fhHyp)) {
	my $refSnt = parse::sentence($tuple->[0], $caseSensitive);
	my $hypSnt = parse::sentence($tuple->[1], $caseSensitive);
	
	my $probs = probs::generate($refSnt, $hypSnt, $alFactor);
	my $alignment = decodeAlignment($refSnt, $hypSnt, $alFactor, $probs);
	displayAlignment($alignment);
	
	counter::update($cnt);
}

counter::finish($cnt);

io::closeMany($fhRef, $fhHyp);

#####
#
#####
sub processInputArgsAndOpts {
	my ($caseSensitive, $alFactor);
	
	GetOptions(
		'c' => \$caseSensitive,
		'n=i' => \$alFactor);
	
	if (!defined($alFactor)) {
		$alFactor = 0;
	}
	
	if ($alFactor < 0) {
		die("Looking for a positive-valued iteger for alignment factor");
	}
	
	my ($reffile, $hypfile) = @ARGV;

	if (!$reffile or !$hypfile) {
		die("Required arguments: reference file, hypothesis file");
	}
	
	return ($reffile, $hypfile, $caseSensitive, $alFactor);
}

#####
#
#####
sub decodeAlignment {
	my ($refSnt, $hypSnt, $alFactor, $probs) = @_;
	
	my $auxinfo = {
		'refsnt' => $refSnt,
		'hypsnt' => $hypSnt,
		'alfact' => $alFactor,
		'probs' => $probs};
	
	my $result = beamsearch::decode(genAlInitState(), $auxinfo,
		\&genAlNextStates, \&isAlFinalState);
	
	return $result->{'alignment'};
}

#####
#
#####
sub isAlFinalState {
	my ($state, $auxinfo) = @_;
	
	my $hypsnt = $auxinfo->{'hypsnt'};
	
	return ($state->{'pos'} == $#$hypsnt);
}

#####
#
#####
sub getLastNonNilPoint {
	my $alignment = shift;
	
	my $i = $#$alignment;
	
	while ($i >= 0 and ($alignment->[$i] == -1)) {
		$i--;
	}
	
	return ($i < 0)? -1: $alignment->[$i];
}

#####
#
#####
sub genAlNextStates {
	my ($currState, $auxinfo) = @_;
	
	my $refSnt = $auxinfo->{'refsnt'};
	
	my $nextPos = $currState->{'pos'} + 1;
	my $currAlignment = $currState->{'alignment'};
	my $currAlPoint = getLastNonNilPoint($currAlignment);
	
	my $nextHypWord = io::getWordFactor($auxinfo->{'hypsnt'}->[$nextPos], $auxinfo->{'alfact'});
	
	my $result = [];
	
	for my $refIdx (-1..$#$refSnt) {
		if ($refIdx == -1 or grep(/^\Q$refIdx\E$/, @$currAlignment) == 0) {
			my $newProb =
				$auxinfo->{'probs'}->{'emit'}->{$nextHypWord}->{$refIdx} *
				$auxinfo->{'probs'}->{'trans'}->{$currAlPoint}->{$refIdx};
			
			if ($newProb != 0) {
				my $newstate = genNewAlState($currState->{'prob'} + log($newProb),
					[@$currAlignment, $refIdx], $nextPos);
				push @$result, $newstate;
			}
		}
	}
	
	return $result;
}

#####
#
#####
sub getCoverString {
	my $state = shift;
	my $al = $state->{'alignment'};
	my @cleanAl = grep(!/^\Q-1\E$/, @$al);
	my @sortAl = sort { $a <=> $b } @cleanAl;
	return join("/", @sortAl);
}

#####
#
#####
sub genNewAlState {
	my ($prob, $al, $pos) = @_;
	my $newstate = { 'prob' => $prob, 'alignment' => $al, 'pos' => $pos };
	$newstate->{'hash'} = getCoverString($newstate);
	return $newstate;
}

#####
#
#####
sub genAlInitState {
	return genNewAlState(0, [], -1);
}

#####
#
#####
sub displayAlignment {
	my $al = shift;
	
	if (!$al) {
		print "undef\n";
	}
	else {
		for my $i (0..$#$al) {
			my $alPt = $al->[$i];
			if ($alPt >= 0) {
				printf("%d-%d", $i, $alPt);
				
				if ($i < $#$al) {
					print " "
				}
			}
		}
		
		print "\n";
	}
}
