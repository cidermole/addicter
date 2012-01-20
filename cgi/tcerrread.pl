#!/usr/bin/perl
# Reads tcerr.txt (output of detecterr.pl) and displays HTML page with
# error summary
# Copyright © 2012 Jan Berka <berka@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use ReadFindErrs;
use AddicterHTML;
use dzcgi;
use XML::Simple;

my $experiment;
my $alignment;
dzcgi::cist_parametry(\%config);
if ( exists($config{experiment}) )
{
	$experiment = $config{experiment};
}
else
{
	$experiment = "TectoMT_WMT09";
}

if ( exists($config{page}) )
{
	$alignment = $config{page};
}
else
{
	print("<html>\n");
	print("<head>\n");
	print("  <meta http-equiv='content-type' content='text/html; charset=utf8'/>\n");
	print("  <title>Addicter</title>\n");
	print("</head>\n");
	print("<body>\n");
	print("  <h1>Error Summary of $experiment</h1>\n");
	print("  <div>Select alignment</div>\n");
	my $subfolders = get_subfolders($experiment);
	for my $subfolder (@$subfolders)
	{
		print("<div><a href='tcerrread.pl?experiment=$experiment&page=$subfolder'>$subfolder</a></div>\n");
	}
	print("</body>\n");
	print("</html>\n");
}
# number of sentences
my $numsnt = count_lines("$experiment/test.src");
# path to file with found errors
my $path = "$experiment/$alignment/tcerr.txt";

# count of error type sentence occurences (number of different sentences with given error type occurence)
my %err_sent_counts = (
	'extraHypWord' => 0,
	'missingRefWord' => 0,
	'untranslatedHypWord' => 0,
	'unequalAlignedTokens' => 0,
	'ordErrorShiftWord' => 0,
	'ordErrorSwitchWords' => 0
);
# counts of error type occurence
my %err_counts = (
	'extraHypWord' => 0,
	'missingRefWord' => 0,
	'untranslatedHypWord' => 0,
	'unequalAlignedTokens' => 0,
	'ordErrorShiftWord' => 0,
	'ordErrorSwitchWords' => 0
);
# id's of sentences with error of the given type
my %err_positions = (
	'extraHypWord' => [qw()],
	'missingRefWord' => [qw()],
	'untranslatedHypWord' => [qw()],
	'unequalAlignedTokens' => [qw()],
	'ordErrorShiftWord' => [qw()],
	'ordErrorSwitchWords' => [qw()]
);
#id's of sentences without any errors
my @without_errs = qw();

my $xmlrecord = XMLin($path);
for my $i (0..$#{$xmlrecord->{sentence}})
{
	my $oldrecord = ${$xmlrecord->{sentence}}[$i];
	my %oldrecord = %$oldrecord;
	my %sentence;
	my $sentence = \%sentence;
	my %errors;
	my $element;
	
	#just few changes to be in wanted structure
	while (($element, $value) = each(%oldrecord)){
		if (($element eq 'missingRefWord') or ($element eq 'extraHypWord') or ($element eq 'ordErrorShiftWord') or ($element eq 'ordErrorSwitchWords') or ($element eq 'unequalAlignedTokens') or ($element eq 'untranslatedHypWord'))
		{
			$sentence{errors}->{$element} = $value;
		}
		else
		{
			$sentence{$element} = $value;
		}
	}
	
	#filling the hashes
	if ( exists($sentence{'errors'}) )
	{
		while( ($type, $val) = each(%{$sentence{errors}}) )
		{
			if ( exists($err_sent_counts{$type}) )
			{
				# adding 1 to error type occurence count
				$err_sent_counts{$type} = $err_sent_counts{$type} + 1;
				# adding sentence id to list of sentences with error type occurence
				# if it isn't already there
				if ( (not exists(${$err_positions{$type}}[-1])) or (${$err_positions{$type}}[-1] != $sentence{index}) )
				{
					push( @{$err_positions{$type}}, "$sentence{index}" );
				}
				
				my $errors = $sentence{errors};
				my $errs_of_type = $$errors{$type};
				if (ref($errs_of_type) eq 'ARRAY') #a couple of occurences in this sentence
				{
					my $count = $#$errs_of_type + 1;
					$err_counts{$type} = $err_counts{$type} + $count;
				}
				else #just one error occurence in this sentence
				{
					$err_counts{$type} = $err_counts{$type} + 1;
				}
			}
			else
			{
				#add error type to err_sent_counts and id to err_positions
				#TODO, but not necesarry now (we don't get any type of errors not in err_sent_counts anyway)
			}
		}
	}
	else
	{
		#sentence without errors
		push( @without_errs, $sentence{index} );
	}
}

print("<html>\n");
print("<head>\n");
print("  <meta http-equiv='content-type' content='text/html; charset=utf8'/>\n");
print("  <title>Addicter</title>\n");
print("</head>\n");
print("<body>\n");
print("  <h1>Error Summary of $experiment</h1>\n");
print("  <div>...with alignment $alignment</div>\n");
print("<br>\n");
# table of error type occurence counts
print("  <table border='1'>\n");
print("    <caption>Error occurence counts</caption>\n");
print("    <tr><th>Error type</th><th>Sentence count</th><th>Avg per sentence</th><th>Count</th></tr>");
foreach $type (sort {$a cmp $b} keys %err_sent_counts)
{
	if ($err_sent_counts{$type} != 0)
	{
		$avg = $err_counts{$type}/$err_sent_counts{$type};
	}
	else
	{
		$avg = "NaN";
	}
	print("    <tr><td>$type</td><td>$err_sent_counts{$type}</td><td>$avg</td><td>$err_counts{$type}</td></tr>\n");
}
print("  </table>\n");
print("  <br>\n");

# list of sentences without any translation errors
print("<h3>Sentences without errors</h3>");
if (exists $without_errs[-1])
{
	print("  <h3>Sentences without any errors</h3>\n");
	print("  <div>");
	for my $sntid (@without_errs)
	{
		my $tdb_id = $sntid + 1;
		print("    <a href='browsetest.pl?experiment=$experiment&sntno=$realid#page=$alignment'>$tdb_id</a> " );
	}
	print("  </div>\n");
}
else
{
	print("  <div>No sentences without any errors</div>\n");
}

# list of sentences with given error type
foreach $type (keys %err_positions)
{
	print("  <h3>$type</h3>\n");
	print("  <div>\n");
	for my $sntid (@{$err_positions{$type}})
	{
		my $tdb_id = $sntid + 1;
		print("    <a href='browsetest.pl?experiment=$experiment&sntno=$tdb_id#page=$alignment'>$tdb_id</a>;\n");
	}
	print("  </div>\n");
}
print("</body>\n");
print("</html>\n");

################################
# SUBROUTINES                  #
################################

# Counts sentences (lines) in a file.
sub count_lines
{
    my $path = shift;
    my $n;
    open(IN, $path) or print("<p style='color:red'>Cannot read $path: $!</p>\n");
    while(<IN>)
    {
        $n++;
    }
    close(IN);
    return $n;
}

#------------------------------------------------------------------------------
# Scans the experiment folder for subfolders.
#------------------------------------------------------------------------------
sub get_subfolders
{
    my $folder = shift;
    opendir(DIR, $folder) or print("<p style='color:red'>Cannot read folder $folder: $!</p>\n");
    my @subfolders = readdir(DIR) or 'no subfolders found';
    @subfolders = grep {-d "$folder/$_" && !m/^\./} (@subfolders);
    closedir(DIR);
    return \@subfolders;
}
