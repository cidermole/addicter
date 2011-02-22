package flagg;
use strict;
use math;

#####
#
#####
sub convertFromFactored {
	my $sentence = shift;
	my $newsnt = [];
	
	for my $w (@$sentence) {
		my $neww = { 'factors' => [], 'flags' => {} };
		
		for my $f (@$w) {
			push @{$neww->{'factors'}}, $f;
		}
		
		push @$newsnt, $neww;
	}
	
	return { 'hyp' => $newsnt, 'missed' => {} };
}

#####
#
#####
sub display {
	my $flaggedHyp = shift;
	
	displayFlaggedMissingRef($flaggedHyp);
	
	displayFlaggedHyp($flaggedHyp);
	
	print "\n";
}

#####
#
#####
sub displayFlaggedHyp {
	my $flaggedHyp = shift;
	
	for my $hypWord (@{$flaggedHyp->{'hyp'}}) {
		my $surfForm = $hypWord->{'factors'}->[0];
		
		for my $flag (sort keys %{$hypWord->{'flags'}}) {
			print $flag . "::";
		}
		
		print $surfForm . " ";
	}
}

#####
#
#####
sub displayFlaggedMissingRef {
	my $flaggedHyp = shift;
	
	for my $missRefWord (keys %{$flaggedHyp->{'missed'}}) {
		my $count = $flaggedHyp->{'missed'}->{$missRefWord};
		
		my @factors = split(/\|/, $missRefWord);
		my $surfForm = $factors[0];
		my $pos = $factors[1];
		my $auxFlag;
		
		if ($pos eq "content" or $pos eq "C") {
			$auxFlag = "C";
		}
		elsif ($pos eq "aux" or $pos eq "A") {
			$auxFlag = "A";
		}
		elsif ($pos eq "punct" or $pos eq "P") {
			$auxFlag = "P";
		}
		else {
			$auxFlag = "_";
		}
		
		for my $i (1..$count) {
			print "miss" . $auxFlag . "::" . $surfForm . " ";
		}
	}
}

our $conflictRules = [
	[qw(ows owl)],
	[qw(ows opl)],
	[qw(ows ops)],
	[qw(owl opl)],
	[qw(owl ops)],
	[qw(ops opl)],
	
	[qw(neg form)],
	[qw(lex form)],
	[qw(extra form)],
	[qw(unk form)],
	[qw(disam form)],
	
	[qw(unk neg)],
	[qw(extra neg)],
	[qw(disam neg)],
	[qw(lex neg)],
	
	[qw(unk disam)],
	[qw(extra disam)],
	[qw(lex disam)],
	
	[qw(unk lex)],
	[qw(extra lex)],
	
	[qw(unk extra)],
];

#####
#
#####
sub resolveFlagConflicts {
	my ($fhyp) = @_;
	
	for my $fhypTok (@{$fhyp->{'hyp'}}) {
		my $flagHash = $fhypTok->{'flags'};
		
		for my $conflictTuple (@$conflictRules) {
			my ($winner, $loser) = @$conflictTuple;
			
			if ($flagHash->{$winner} and $flagHash->{$loser}) {
				delete $flagHash->{$loser};
			}
		}
	}
}

#####
#
#####
sub append {
	my ($dest, $src) = @_;
	
	for my $newMissKey (keys %{$src->{'missed'}}) {
		$dest->{'missed'}->{$newMissKey} =
			math::max($dest->{'missed'}->{$newMissKey}, $src->{'missed'}->{$newMissKey})
	}
	
	my $hypsize = scalar @{$dest->{'hyp'}};
	
	if ($hypsize ne (scalar @{$src->{'hyp'}})) {
		die("Different hypothesis size, that's unexpected");
	}
	
	for my $i (0..($hypsize - 1)) {
		my $destHypTok = $dest->{'hyp'}->[$i];
		
		for my $newFlag (keys %{$src->{'hyp'}->[$i]->{'flags'}}) {
			$destHypTok->{'flags'}->{$newFlag} = 1;
		}
	}
}

#####
#
#####
sub clone {
	my ($src) = @_;
	my $newfhyp = { 'missed' => {}, 'hyp' => [] };
	
	for my $newMissKey (keys %{$src->{'missed'}}) {
		$newfhyp->{'missed'}->{$newMissKey} = $src->{'missed'}->{$newMissKey};
	}
	
	my $hypsize = scalar @{$src->{'hyp'}};
	
	for my $i (0..($hypsize - 1)) {
		my $srctoken = $src->{'hyp'}->[$i];
		my $newtoken = { 'factors' => [], 'flags' => {} };
		
		for my $factor (@{$srctoken->{'factors'}}) {
			push @{$newtoken->{'factors'}}, $factor;
		}
		
		for my $newFlag (keys %{$srctoken->{'flags'}}) {
			$newtoken->{'flags'}->{$newFlag} = 1;
		}
		
		push @{$newfhyp->{'hyp'}}, $newtoken;
	}
	
	return $newfhyp;
}

1;
