#!/usr/bin/perl
# Displays HTML page with error summary
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

# count of error type occurences
my %err_counts = (
	'extraHypWord' => 0,
	'missingRefWord' => 0,
	'untranslatedHypWord' => 0,
	'unequalAlignedTokens' => 0,
	'ordErrorShiftWords' => 0,
	'ordErrorSwitchWords' => 0
);
# id's of sentences with error of the given type
my %err_positions = (
	'extraHypWord' => [qw()],
	'missingRefWord' => [qw()],
	'untranslatedHypWord' => [qw()],
	'unequalAlignedTokens' => [qw()],
	'ordErrorShiftWords' => [qw()],
	'ordErrorSwitchWords' => [qw()]
);
#id's of sentences without any errors
my @without_errs = qw();

for my $n (1..$numsnt)
{
	$sentence = ReadFindErrs::get_nth_sentence( $path, $n );
	if ( exists($$sentence{'errors'}) )
	{
		while( ($type, $value)= each(%{$$sentence{'errors'}}) )
		{
			if ( exists($err_counts{$type}) )
			{
				# adding 1 to error type occurence count
				$err_counts{$type} = $err_counts{$type} + 1;
				# adding sentence id to list of sentences with error type occurence
				if ( (not exists(${$err_positions{$type}}[-1])) or (${$err_positions{$type}}[-1] != $$sentence{'wantid'}) )
				{
					push( @{$err_positions{$type}}, "$$sentence{'wantid'}" );
				}
			}
			else
			{
				#add error type to err_counts and id to err_positions
			}
		}
	}
	else
	{
		#sentence without errors
		push( @without_errs, $$sentence{'wantid'} );
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
print("    <tr><th>Error type</th><th>Count</th></tr>");
foreach $type (keys %err_counts)
{
	print("    <tr><td>$type</td><td>$err_counts{$type}</td></tr>\n");
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
		my $realid = $sntid + 1;
		print("    <a href='browsetest.pl?experiment=$experiment&sntno=$realid#page=$alignment'>$realid</a> " );
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
		my $realid = $sntid + 1;
		print("    <a href='browsetest.pl?experiment=$experiment&sntno=$realid#page=$alignment'>$realid</a>;\n");
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
