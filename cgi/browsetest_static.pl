#!/usr/bin/perl
# Generates static HTML page for every segment of test data (source sentence, reference translation, MT system hypothesis).
# Static version of the CGI script browsetest.pl.
# Copyright © 2011 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
sub usage
{
    print STDERR ("Usage example: browsetest_static.pl -experiment cs-ru -path /my/experiments/csru\n");
    print STDERR ("\t-experiment ... experiment name used only in heading of the page\n");
    print STDERR ("\t-path ... path to the index files and corpora of the experiment\n");
    print STDERR ("Numbered HTML pages with test sentences will be created in the current folder.\n");
}

use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use Getopt::Long;
use AddicterHTML;
use ReadFindErrs;

GetOptions('experiment=s' => \$experiment, 'path=s' => \$path);
$numsnt = count_lines("$path/test.src");
for(my $i = 1; $i<=$numsnt; $i++)
{
    my $filename = get_file_name($i, $numsnt);
    print STDERR ("Writing $filename...\n");
    open(HTML, ">$filename") or die("Cannot write $filename: $!\n");
    print HTML (html_page_start());
    print HTML (html_test_segment($experiment, $path, $i, $numsnt));
    # Close the HTML document.
    print HTML (html_page_end());
    close(HTML);
}



###############################################################################
# SUBROUTINES
###############################################################################



#------------------------------------------------------------------------------
# Generates file name (without path) for the HTML page for the i-th segment.
#------------------------------------------------------------------------------
sub get_file_name
{
    my $i_segment = shift;
    my $n_segments = shift;
    my $n_digits = length($n_segments);
    return sprintf("test%0${n_digits}d.html", $i_segment);
}



#------------------------------------------------------------------------------
# Generates the header of the HTML page including the initial <body> tag and
# returns it as a string.
#------------------------------------------------------------------------------
sub html_page_start
{
    my $html;
    $html .= "<html>\n";
    $html .= "<head>\n";
    $html .= "  <meta http-equiv='content-type' content='text/html; charset=utf8' />\n";
    $html .= "  <title>Addicter: Test Data Browsing</title>\n";
    $html .= "</head>\n";
    $html .= "<body>\n";
    # We do not want underlined hyperlinks unless the mouse goes over them.
    $html .= "  <style><!-- A:link, A:visited { text-decoration: none } A:hover { text-decoration: underline } --></style>\n";
    return $html;
}



#------------------------------------------------------------------------------
# Generates the footer of the HTML page and returns it as a string.
#------------------------------------------------------------------------------
sub html_page_end
{
    my $html;
    $html .= "</body>\n";
    $html .= "</html>\n";
    return $html;
}



#------------------------------------------------------------------------------
# Generates the HTML visualisation of a test data segment.
#------------------------------------------------------------------------------
sub html_test_segment
{
    my $experiment = shift; # experiment name (for the heading)
    my $path = shift; # path to the folder with corpora and index files of the experiment
    my $sntno = shift; # number of the test segment (starting at 1)
    my $numsnt = shift; # number of segments in test data
    $sntno = 1 unless($sntno);
    my %files =
    (
        'TRS' => "${path}/train.src",
        'TRT' => "${path}/train.tgt",
        'TRA' => "${path}/train.ali",
        'S'   => "${path}/test.src",
        'R'   => "${path}/test.tgt",
        'H'   => "${path}/test.system.tgt",
        'RA'  => "${path}/test.ali",
        'HA'  => "${path}/test.system.ali",
        'XML' => "${path}/tcerr.txt"
    );
    my $html = "  <h1>Test Data of $experiment</h1>\n";
    $html .= get_navigation($sntno, $numsnt);
    $html .= sentence_to_table($sntno, $files{S}, $files{R}, $files{RA}, $files{H}, $files{HA}, $files{XML});
    return $html;
}



#------------------------------------------------------------------------------
# Generates navigation information: sentence number, prev/next links.
#------------------------------------------------------------------------------
sub get_navigation
{
    my $sntno = shift; # number of current sentence (first sentence has number 1)
    my $numsnt = shift; # number of sentences in file
    my $html;
    $html .= "  <p>";
    $html .= "This is the test sentence number $sntno of $numsnt.";
    # Provide links to the preceding and the following sentence.
    my @links;
    my $previous = $sntno-1;
    my $next = $sntno+1;
    push(@links, $previous>0 ? "<a href='".get_file_name($previous, $numsnt)."'>previous</a>" : 'previous');
    push(@links, $next<=$numsnt ? "<a href='".get_file_name($next, $numsnt)."'>next</a>" : 'next');
    $html .= " Go to [".join(' | ', @links)."].";
    $html .= "</p>\n";
    return $html;
}



#------------------------------------------------------------------------------
# Generates a HTML table with a sentence pair/triple (for test data, triples of
# source, reference and hypothesis may be available).
#------------------------------------------------------------------------------
sub sentence_to_table
{
    # This function accesses the global hashes %config and %prevod.
    my $sntno = shift;
    my $srcfile = shift;
    my $tgtfile = shift;
    my $alifile = shift;
    my $hypfile = shift;
    my $halifile = shift;
    my $finderrsxmlfile = shift;
    my $html;
    my $srcline = AddicterHTML::get_nth_line($srcfile, $sntno);
    my $tgtline = AddicterHTML::get_nth_line($tgtfile, $sntno);
    my $aliline = AddicterHTML::get_nth_line($alifile, $sntno);
    my $hypline = AddicterHTML::get_nth_line($hypfile, $sntno);
    my $haliline = AddicterHTML::get_nth_line($halifile, $sntno);
    # Print raw sentences first. No tables, to make reading easier.
    $html .= "<dl>\n";
    $html .= "  <dt><b>source</b></dt>\n";
    $html .= "  <dd>$srcline</dd>\n";
    $html .= "  <dt><b>target</b></dt>\n";
    $html .= "  <dd>$tgtline</dd>\n";
    $html .= "  <dt><b>system hypothesis</b></dt>\n";
    $html .= "  <dd>$hypline</dd>\n";
    $html .= "</dl>\n";
    # Decompose alignments into array of arrays (pairs).
    my @alignments = map {my @pair = split(/-/, $_); \@pair} (split(/\s+/, $aliline));
    my @srcwords = split(/\s+/, $srcline);
    my @tgtwords = split(/\s+/, $tgtline);
    my @halignments = map {my @pair = split(/-/, $_); \@pair} (split(/\s+/, $haliline));
    my @hypwords = split(/\s+/, $hypline);
    # Get HTML for the three sentences with alignments.
    my $srcrow = AddicterHTML::sentence_to_table_row($config{experiment}, \@srcwords, \@tgtwords, \@alignments, 0, undef, undef, 1);
    my $tgtrow = AddicterHTML::sentence_to_table_row($config{experiment}, \@tgtwords, \@srcwords, \@alignments, 1, undef, undef, 1);
    my $hyprow = AddicterHTML::sentence_to_table_row($config{experiment}, \@hypwords, \@srcwords, \@halignments, 1, undef, undef, 1);
    # We can display all three pairs of rows in one table or we can display them in separate tables.
    my $onetable = 0;
    if($onetable)
    {
        # Display the source words along with their alignment links.
        $html .= "<table border style='font-family:Code2000'>\n";
        # An empty row separates source and target sections.
        $html .= join("  <tr><td></td></tr>\n", ($srcrow, $tgtrow, $hyprow));
        $html .= "</table>\n";
    }
    else # separate tables
    {
        foreach my $rowpair ($srcrow, $tgtrow, $hyprow)
        {
            # Display the source words along with their alignment links.
            $html .= "<table border style='font-family:Code2000'>\n";
            $html .= $rowpair;
            $html .= "</table>\n";
        }
    }
    # Additional information by finderrs.pl from Mark's Testchamber.
    if(-f $finderrsxmlfile)
    {
        my $xmlrecord = ReadFindErrs::get_nth_sentence($finderrsxmlfile, $sntno);
        $html .= "<h2>Automatically Identified Errors</h2>\n";
        if($xmlrecord->{state} eq 'waiting')
        {
            $html .= "<p>No information from <tt>finderrs.pl</tt> found.</p>\n";
        }
        elsif($xmlrecord->{state} eq 'finished')
        {
            $html .= "<dl>\n";
            foreach my $key (keys(%{$xmlrecord->{errors}}))
            {
                $html .= "<dt><b>$key</b></dt>\n";
                $html .= "<dd>".join(' ', map {$_->{surfaceForm}} (@{$xmlrecord->{errors}{$key}}))."</dd>\n";
            }
            $html .= "</dl>\n";
        }
        else
        {
            $html .= "<p style='color:red'>Parsing the XML file <tt>$findersxmlfile</tt> resulted in unknown state '$xmlrecord->{state}'.</p>\n";
        }
    }
    return $html;
}



#------------------------------------------------------------------------------
# Counts sentences (lines) in a file. It is not efficient to do this every time
# an example is displayed, especially not for long files. We should count the
# lines during indexing and store the number within the index.
#------------------------------------------------------------------------------
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
