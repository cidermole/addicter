#!/usr/bin/perl
#$debug = 1;
#--------------------------------------------------------------
# Jussi Karlgren, jussi@sics.se
#--------------------------------------------------------------
# Calculates rank sum correlation between two columns of
# numerical data in a file entered on standard input.
# Use as is - no guarantees :-)
#--------------------------------------------------------------
# Change this to fit whatever set of columns 
# you are studying. First column 
# is 0. Many columns ( > 2) can be specified.
#@columns = (1,9);
@columns = (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18);
#--------------------------------------------------------------
# Read data.
# $line_number is the current line number; $column the current column.
# %score will hold the value for any combination of key and column.
# %individuals will hold a "1" for every line with a non-null value. If a line
# holds some nulls but at least one non-null value the nulls will be interpreted
# as zero values.
$line = <>;
@column_names = split(/\s+/, $line);
$line_number = 0;
while (<>) {
    split(/\s+/);
    foreach $column (@columns) { 
	if ($_[$column] ne "") {
	    $score{$column,$line_number} = $_[$column];
	    $individuals{$line_number} = 1;
	}
    }
    $line_number++;
}

# backward way of seeing how many individuals had values.
@tmp_n = keys %individuals;
$n = $#tmp_n + 1;

foreach $column (@columns) {
    $this_rank = 0;
    # $individual will in turn contain the index of a cell to be studied in $column.
    # each cycle, it will be put in $previous_index and the cell contents in $previous_score
    foreach $individual (sort {$score{$column,$a} <=> $score{$column,$b}} keys %individuals) {
        # Are the values equal? 
        # YES: Stack the individual in @stack of $duplicates and wait for a new value to show up.
        #      Well, except if we are at the first element, of course. 
	if ($this_rank > 0 && $score{$column,$individual} == $score{$column,$previous}) {
	    print STDERR "$column $individual	->	st	$score{$column,$individual} $score{$column,$previous}  d $duplicates EQ!\n" if $debug;
	    $stack[$duplicates] = $previous;
	    $duplicates++;
        # Are the values equal? 
	# NO: Pop the stack, and put the previous item into %rank.
	} else {
            # unroll the stack if necessary
	    if ($duplicates) { 
		$stack[$duplicates] = $previous;
		$duplicates++;
		# then calculate the average for the stack. 
		$rank_average = $this_rank - 1 - $#stack/2;
		# foreach stacked duplicate value, put in the average rank.
		$d = $duplicates;
		foreach $double (@stack) {
		    print STDERR "$column $double	->	$rank_average	$score{$column,$double} UNSTACK\n" if $debug;
		    $rank{$column,$double} = $rank_average;
		}
		# empty the stack.
		$duplicates = 0;
		@stack = ();
	    } else {
		# if no stack, put the previous rank into %rank
		print STDERR "$column $previous	->	$previous_rank	$score{$column,$previous} INPUT!\n" if $debug;
		$rank{$column,$previous} = $previous_rank;
	    }
	}
	# Put the current position and rank into memory for next iteration.
	$previous = $individual;
	$previous_rank = $this_rank;
	$this_rank++;	
    }
    
    # after the last element, are there any left on stack? (was the last element a duplicate?)
    if ($duplicates) {
	$stack[$duplicates] = $previous;
	$duplicates++;
	# then calculate the average for the stack. 
	$rank_average = $this_rank - 1 - $#stack/2;
	# foreach stacked duplicate value, put in the average rank.
	$d = $duplicates;
	foreach $double (@stack) {
	    print STDERR "$column $double	->	$rank_average	$score{$column,$double} UNSTACK\n" if $debug;
	    $rank{$column,$double} = $rank_average;
	}
	# empty the stack.
	$duplicates = 0;
	@stack = ();
    } else {
	# if no stack, put the previous rank into %rank
	print STDERR "$column $previous	->	$previous_rank	$score{$column,$previous} INPUT!\n" if $debug;
	$rank{$column,$previous} = $previous_rank;
    }
}
if ($debug) { 
    foreach $individual (sort {$a <=> $b} keys %individuals) {
	print "$individual	";
	foreach $column (@columns) {
	    print ">$rank{$column,$individual}:$score{$column,$individual}<	";
	}
	print "\n";
    }
}
%score = ();
print "    ";
foreach $column (@columns) {print $column_names[$column]. " ";}
print "\n";

for($i = 0; $i < @column_names-1; $i++) {
    $column = $columns[$i];
   print $column_names[$column] . "\t";
    for($j = 0; $j < @column_names-1; $j++) {
	$other_column = $columns[$j];
	if ($column == $other_column) {
	    printf "%4d\t",1;
	} else {
	    if($j > $i) {
		$D2 = 0;
		foreach $line (keys %individuals) {
		    $D2 += ($rank{$column,$line}-$rank{$other_column,$line})*($rank{$column,$line}-$rank{$other_column,$line});
		}
		$rs = 1-6*$D2/($n*($n*$n-1));
		printf "%4.3f\t", $rs;
	    } else {
		print "---\t";
	    }
	}
    }
    print "\n";
} 

exit(0);	
