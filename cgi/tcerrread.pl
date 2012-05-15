#!/usr/bin/perl
# Reads tcerr.txt (output of detecterr.pl) and displays HTML page with
# error summary
# Copyright © 2012 Jan Berka <berka@ufal.mff.cuni.cz>, Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
use XML::Simple;
use ReadFindErrs;
use AddicterHTML;
use dzcgi;

my $experiment;
my $alignment;
print("Content-type: text/html; charset=utf8\n\n");
dzcgi::cist_parametry(\%config);
# For debugging purposes, read parameters also from @ARGV.
dzcgi::cist_parametry_argv(\%config);
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
    # number of sentences
    my $numsnt = count_lines("$experiment/test.src");
    # path to file with found errors
    my $path = "$experiment/$alignment/tcerr.txt";

    # count of error type sentence occurences (number of different sentences with given error type occurence)
    #my %err_sent_counts = (
    #	'extraHypWord' => 0,
    #	'missingRefWord' => 0,
    #	'untranslatedHypWord' => 0,
    #	'unequalAlignedTokens' => 0,
    #	'ordErrorShiftWord' => 0,
    #	'ordErrorSwitchWords' => 0
    #);

    my %err_sent_counts = ();

    # counts of error type occurence
    #my %err_counts = (
    #	'extraHypWord' => 0,
    #	'missingRefWord' => 0,
    #	'untranslatedHypWord' => 0,
    #	'unequalAlignedTokens' => 0,
    #	'ordErrorShiftWord' => 0,
    #	'ordErrorSwitchWords' => 0
    #);
    my %err_counts = ();
    # id's of sentences with error of the given type
    #my %err_positions = (
    #	'extraHypWord' => [qw()],
    #	'missingRefWord' => [qw()],
    #	'untranslatedHypWord' => [qw()],
    #	'unequalAlignedTokens' => [qw()],
    #	'ordErrorShiftWord' => [qw()],
    #	'ordErrorSwitchWords' => [qw()]
    #);
    my %err_positions = ();
    #id's of sentences without any errors
    my @without_errs = qw();

    print("<html>\n");
    print("<head>\n");
    print("  <meta http-equiv='content-type' content='text/html; charset=utf8'/>\n");
    print("  <title>Addicter</title>\n");
    print("</head>\n");
    print("<body>\n");
    my $xmlrecord;
    if(!-f $path)
    {
        print("<p style='color:red'>File does not exist: $path</p>\n");
    }
    else
    {
        $xmlrecord = XMLin($path);
    }
    # Loop over all <sentence> elements in the input XML.
    for my $i (0..$#{$xmlrecord->{sentence}})
    {
        my $oldrecord = $xmlrecord->{sentence}[$i];
        my %oldrecord = %$oldrecord;
        my %sentence;
        my %errors;
        my $element;

        # %oldrecord contains all sub-elements and attributes of the current <sentence> element.
        # Copy them to %sentence, performing a few changes on the fly.
        while (($element, $value) = each(%oldrecord))
        {
            if ($element =~ m/^(missingRefWord|extraHypWord|ordErrorShiftWord|ordErrorSwitchWords|unequalAlignedTokens|untranslatedHypWord|otherMismatch|inflectionalError|reorderingError)$/)
            {
                $sentence{errors}{$element} = $value;
            }
            else
            {
                $sentence{$element} = $value;
            }
        }
        # Sanity check: There should be an 'index' attribute with incremental value.
        if($sentence{index} ne $i)
        {
            print("<div style='color:magenta'>XML input error: \$i = '$i', \$sentence{index} = '$sentence{index}'</div>\n");
        }

    	#filling the hashes
    	if ( exists($sentence{errors}) )
    	{
            while( ($type, $val) = each(%{$sentence{errors}}) )
            {
                # Add the sentence id to the list of sentences containing this type of error (if it isn't already there).
                if((!exists($err_positions{$type}[-1]) || $err_positions{$type}[-1] != $sentence{index}))
                {
                    push(@{$err_positions{$type}}, $sentence{index});
                }
                # Initialize counters if this is a new type of error, not seen before.
                if(!exists($err_sent_counts{$type}))
                {
                    $err_sent_counts{$type} = 0;
                    $err_counts{$type} = 0;
                }
                # adding 1 to error type occurence count
                $err_sent_counts{$type}++;
                my $errors = $sentence{errors};
                my $errs_of_type = $$errors{$type};
                if (ref($errs_of_type) eq 'ARRAY') # a couple of occurences in this sentence
                {
                    my $count = $#$errs_of_type + 1;
                    $err_counts{$type} += $count;
                }
                else # just one error occurence in this sentence
                {
                    $err_counts{$type}++;
                }
    		}
    	}
    	else
    	{
    	    # sentence without errors
    	    push(@without_errs, $sentence{index});
    	}
    }

    print("  <h1>Error Summary of <a href='index.pl?experiment=$experiment'>$experiment</a></h1>\n");
    print("  <div>...with alignment $alignment</div>\n");
    print("<br>\n");
    # table of error type occurence counts
    print("  <table border='1'>\n");
    print("    <caption>Error occurence counts</caption>\n");
    print("    <tr><th>Error type</th><th>Sentence count</th><th>Avg per sentence</th><th>Count</th></tr>");
    my %error_colors =
    (
        'missingRefWord'       => 'lightblue',
        'extraHypWord'         => 'lightblue',
        'untranslatedHypWord'  => 'orange',
        'unequalAlignedTokens' => 'pink',
        'ordErrorShiftWord'    => 'lightgreen',
        'ordErrorSwitchWords'  => 'lightgreen',
    );
    foreach $type (sort {$a cmp $b} keys %err_sent_counts)
    {
        if ($err_sent_counts{$type} != 0)
        {
            $avg = int(100*$err_counts{$type}/$err_sent_counts{$type})/100;
        }
        else
        {
            $avg = "NaN";
        }
        print("    <tr><td style='background-color:$error_colors{$type}'>$type</td><td align=center>$err_sent_counts{$type}</td><td align=center>$avg</td><td align=center>$err_counts{$type}</td></tr>\n");
    }
    print("  </table>\n");
    print("  <br>\n");

    # list of sentences without any translation errors
    print("<h3>Sentences without errors</h3>");
    if (exists $without_errs[-1])
    {
    	print("  <div>");
        my @links = map
        {
            my $tdb_id = $_ + 1;
            "<a href='browsetest.pl?experiment=$experiment&sntno=$tdb_id#page=$alignment'>$tdb_id</a>";
        }
        (@without_errs);
        print('    ', join(";\n    ", @links), "\n");
    	print("  </div>\n");
    }
    else
    {
    	print("  <div>No sentences without any errors</div>\n");
    }

    # list of sentences with given error type
    foreach $type (sort {$a cmp $b} keys %err_sent_counts)
    {
        print("  <h3>$type</h3>\n");
        print("  <div>\n");
        my @links = map
        {
            my $tdb_id = $_ + 1;
            "<a href='browsetest.pl?experiment=$experiment&sntno=$tdb_id#page=$alignment'>$tdb_id</a>";
        }
        (@{$err_positions{$type}});
        print('    ', join(";\n    ", @links), "\n");
        print("  </div>\n");
    }
    print("</body>\n");
    print("</html>\n");
}
else # no alignment selected
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
