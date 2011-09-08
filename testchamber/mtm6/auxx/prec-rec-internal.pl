#!/usr/bin/perl
use strict;

my @fhs = openMany(@ARGV);

my $stats = {};

my $allFlags = {};

while (my $snts = readSentences(@fhs)) {
	my $sntMan = $snts->[0];
	my $sntAuto = $snts->[1];
	
	my @wordsMan = split(/ /, $sntMan);
	my @wordsAuto = split(/ /, $sntAuto);
	
	if ($#wordsMan != $#wordsAuto) {
		die("$#wordsMan != $#wordsAuto, wrong files probably");
	}
	
	for my $i (0..$#wordsMan) {
		my ($manFlags, $manSform) = getFlags($wordsMan[$i]);
		my ($autoFlags, $autoSform) = getFlags($wordsAuto[$i]);
		
		if (lc($manSform) ne lc($autoSform)) {
			die("Words in manual and automatic annotated files should match ($manSform != $autoSform)");
		}
		
		if (scalar keys %$manFlags > 1) {
			die("Many manual flags");
		}
		
		my @keys = keys %$manFlags;
		my $manFlag = shift @keys;
		
		$allFlags->{$manFlag} = 1;
		
		if ($autoFlags->{$manFlag}) {
			$stats->{$manFlag}->{$manFlag}++;
		}
		else {
			for my $autoFlag (keys %$autoFlags) {
				$stats->{$autoFlag}->{$manFlag}++;
				$allFlags->{$autoFlag} = 1;
			}
		}
	}
}

my @flags = sort keys %$allFlags;

my $correct = 0;
my $total = 0;

print "||border=1\n";
print "|| (left: auto; top: manual) ||||||||||||\n";

printf "|| %15s ", "";

for my $headFlag (@flags) {
	printf "|| %8s", $headFlag;
}

print " ||\n";

for my $autoFlag (@flags) {
	printf "|| %15s ", $autoFlag;
	
	for my $manFlag (@flags) {
		my $val = $stats->{$autoFlag}->{$manFlag};
		printf "|| %8d", $val;
		
		$correct += ($autoFlag eq $manFlag)? $val: 0;
		
		$total += $val;
	}
	print " ||\n";
}



printf "|| total accuracy: %.3f ||||||||||||\n", $correct / $total;

#####
#
#####
sub getFlags {
	my ($word) = @_;
	
	my $result = {};
	
	my @parts = split(/~~/, $word);
	pop @parts;
	
	if (@parts > 0) {
		for my $k (@parts) {
			$result->{$k} = 1;
		}
	}
	else {
		$result->{'-'} = 1;
	}
	
	return $result;
}

#####
#
#####
sub noRead {
	die("Failed to open `" . $_[0] . "' for reading");
}

#####
#
#####
sub openRead {
	my $filename = shift;
	
	my $fh;
	
	open($fh, $filename) or noRead($filename);
	binmode($fh, ":utf8");
	
	return $fh;
}

#####
#
#####
sub openMany {
	my @fhs = ();
	for my $file (@_) {
		push @fhs, openRead($file);
	}
	return @fhs;
}

#####
#
#####
sub closeMany {
	for my $fh (@_) {
		close($fh);
	}
}

#####
#
#####
sub readSentence {
	my $fh = shift;
	
	my $string = <$fh>;
	
	if ($string) {
		$string =~ s/\n//g;
		$string =~ s/[ \t]{2,}/ /g;
		$string =~ s/^ //g;
		$string =~ s/ $//g;
		
		return $string;
	}
	else {
		return undef;
	}
}

#####
#
#####
sub readSentences {
	my @fhArr = @_;
	my @sntArr = ();
	
	my $allFinished = 1;
	my $allSucceeded = 1;
	
	for my $fh (@fhArr) {
		my $snt = readSentence($fh);
		
		if (defined($snt)) {
			$allFinished = undef;
		}
		else {
			$allSucceeded = undef;
		}
		
		push @sntArr, $snt;
	}
	
	if ($allSucceeded) {
		return \@sntArr;
	}
	elsif ($allFinished) {
		return undef;
	}
	else {
		die("Unequal number of lines in the input files");
	}
}
