#!/usr/bin/perl
use strict;
use File::Spec;
use Getopt::Long;

BEGIN {
    # include packages from same folder where the
    # script is, even if launched from elsewhere
    # unshift(), not push(), to give own functions precedence over other libraries
    my @dirs = File::Spec->splitdir(File::Spec->rel2abs(File::Spec->canonpath($0)));
    pop @dirs;
    unshift(@INC, File::Spec->catdir(@dirs));
}

use io;
use parse;
use probs;
use beamsearch;
use counter;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my ($reffile, $hypfile, $caseSensitive, $alFactor, $morePtsFiles, $exPts, $uwPts) =
	processInputArgsAndOpts();

my @files = ($reffile, $hypfile);

for my $morePtsFile (@$morePtsFiles) {
	push @files, $morePtsFile;
}

my @fhs = io::gopenMany(@files);
my $tuple;
my $cnt = counter::init();

while($tuple = io::readSentences(@fhs)) {
	my $refSnt = parse::sentence(shift @$tuple, $caseSensitive);
	my $hypSnt = parse::sentence(shift @$tuple, $caseSensitive);
	
	my $morePts = {};
	
	my $morePtsLine;
	while ($morePtsLine = shift @$tuple) {
		parse::morepts($morePtsLine, $morePts, $#$refSnt, $#$hypSnt);
	}
	
	my $probs = probs::generate($refSnt, $hypSnt,
		$alFactor, $morePts, $exPts, $uwPts);
	my $alignment = decodeAlignment($refSnt, $hypSnt, $alFactor, $probs, $cnt);
	displayAlignment($alignment);
	
	counter::update($cnt);
}

counter::finish($cnt);

io::closeMany(@fhs);

#####
#
#####
sub processInputArgsAndOpts {
	my ($caseSensitive, $alFactor, $exclusiveMorePts, $unweighedMorePts);
	my @morePtsFiles;
	
	GetOptions(
		'c' => \$caseSensitive,
		'n=i' => \$alFactor,
		'a=s' => \@morePtsFiles,
		'x' => \$exclusiveMorePts,
		'u' => \$unweighedMorePts) or die("Options failed");
	
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
	
	return ($reffile, $hypfile, $caseSensitive, $alFactor, \@morePtsFiles, $exclusiveMorePts, $unweighedMorePts);
}

#####
#
#####
sub decodeAlignment {
	my ($refSnt, $hypSnt, $alFactor, $probs, $cnt) = @_;
	
	my $auxinfo = {
		'refsnt' => $refSnt,
		'hypsnt' => $hypSnt,
		'alfact' => $alFactor,
		'probs' => $probs};
	
	my $result = beamsearch::decode(genAlInitState(), $auxinfo,
		\&genAlNextStates, \&isAlFinalState);
	
	unless ($result->{'alignment'}) {
		my $msg = "Fail at " . $cnt->{'val'};
		die($msg);
	}
	
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
	
	my $result = [];
	
	#print STDERR "DB\tgenerating for $nextPos;\n";
	
	for my $refIdx (-1..$#$refSnt) {
		#print STDERR "DB\ttrying $refIdx;\n";
		
		if ($refIdx == -1 or grep(/^\Q$refIdx\E$/, @$currAlignment) == 0) {
			my $newProb =
				$auxinfo->{'probs'}->{'emit'}->[$nextPos]->{$refIdx} *
				$auxinfo->{'probs'}->{'trans'}->{$currAlPoint}->{$refIdx};
			
			#print STDERR "DB\tp($refIdx) = $newProb;\n";
			
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
		print "fail\n";
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
