#!/usr/bin/perl
# Displays HTML page with one segment of test data (source language, reference translation, MT system hypothesis).
# Copyright © 2011 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use lib 'C:\Documents and Settings\Dan\Dokumenty\Lingvistika\lib';
use lib '/home/zeman/lib';
use dzcgi;
use AddicterHTML;
use ReadFindErrs;

# Print the HTML header (so that any debugging can possibly also output to the browser).
print("Content-type: text/html; charset=utf8\n\n");
print("<html>\n");
print("<head>\n");
print("  <meta http-equiv='content-type' content='text/html; charset=utf8'/>\n");
print("  <title>Addicter: Test Data Browsing</title>\n");
print("</head>\n");
print("<body>\n");
# We do not want underlined hyperlinks unless the mouse goes over them.
print("  <style><!-- A:link, A:visited { text-decoration: none } A:hover { text-decoration: underline } --></style>\n");
# Read cgi parameters.
dzcgi::cist_parametry(\%config);
if(exists($config{experiment}))
{
    my $path = "$config{experiment}/";
    my %files =
    (
        'TRS' => "${path}train.src",
        'TRT' => "${path}train.tgt",
        'TRA' => "${path}train.ali",
        'S'   => "${path}test.src",
        'R'   => "${path}test.tgt",
        'H'   => "${path}test.system.tgt",
        'RA'  => "${path}test.ali",
        'HA'  => "${path}test.system.ali",
        'XML' => "${path}tcerr.txt"
    );
    print("  <h1>Test Data of $config{experiment}</h1>\n");
    # How many lines (sentences) are there in the test data?
    my $numsnt = count_lines($files{S});
    if($numsnt>0)
    {
        my $example;
        # So what do we need to read?
        my $sntno = $config{sntno}>0 ? $config{sntno} : 1;
        print(get_navigation($sntno, $numsnt));
        my $sentence = read_sentence($config{experiment}, $sntno);
        print(sentence_to_table($sentence));
    }
}
else
{
    print("<p style='color:red'>No experiment specified.</p>\n");
}
# Close the HTML document.
print("</body>\n");
print("</html>\n");



###############################################################################
# SUBROUTINES
###############################################################################



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
    push(@links, $previous>0 ? "<a href='browsetest.pl?experiment=$config{experiment}&amp;sntno=$previous'>previous</a>" : 'previous');
    push(@links, $next<=$numsnt ? "<a href='browsetest.pl?experiment=$config{experiment}&amp;sntno=$next'>next</a>" : 'next');
    $html .= " Go to [".join(' | ', @links)."].";
    $html .= "</p>\n";
    return $html;
}



#------------------------------------------------------------------------------
# Reads tokens and word aligments for the n-th sentence of the test data. Tries
# to read the relevant line from all files that may be available.
#------------------------------------------------------------------------------
sub read_sentence
{
    my $experiment = shift;
    my $sntno = shift; # number of current sentence (first sentence has number 1)
    my %files =
    (
        'S'   => 'test.src',
        'R'   => 'test.tgt',
        'H'   => 'test.system.tgt',
        'RA'  => 'test.ali',
        'HA'  => 'test.system.ali',
        'RH'  => 'test.refhyp.ali',
        'XML' => 'tcerr.txt'
    );
    my %sentence;
    foreach my $file (keys(%files))
    {
        my $path = "$experiment/$files{$file}";
        if(-f $path)
        {
            unless($file eq 'XML')
            {
                $sentence{$file} = AddicterHTML::get_nth_line($path, $sntno);
            }
            else
            {
                $sentence{$file} = ReadFindErrs::get_nth_sentence($path, $sntno);
            }
        }
    }
    return \%sentence;
}



#------------------------------------------------------------------------------
# Generates a HTML table with a sentence pair/triple (for test data, triples of
# source, reference and hypothesis may be available).
#------------------------------------------------------------------------------
sub sentence_to_table
{
    # This function accesses the global hashes %config and %prevod.
    my $sentence = shift; # hash with read tokens and alignments
    my $html;
    # Print raw sentences first. No tables, to make reading easier.
    $html .= "<dl>\n";
    $html .= "  <dt><b>source</b></dt>\n";
    $html .= "  <dd>$sentence->{S}</dd>\n";
    $html .= "  <dt><b>target</b></dt>\n";
    $html .= "  <dd>$sentence->{R}</dd>\n";
    $html .= "  <dt><b>system hypothesis</b></dt>\n";
    $html .= "  <dd>$sentence->{H}</dd>\n";
    $html .= "</dl>\n";
    # Decompose alignments into array of arrays (pairs).
    my @srcwords = split(/\s+/, $sentence->{S});
    my @tgtwords = split(/\s+/, $sentence->{R});
    my @hypwords = split(/\s+/, $sentence->{H});
    my @alignments;
    my @halignments;
    my @rhalignments;
    @alignments = map {my @pair = split(/-/, $_); \@pair} (split(/\s+/, $sentence->{RA})) if(exists($sentence->{RA}));
    @halignments = map {my @pair = split(/-/, $_); \@pair} (split(/\s+/, $sentence->{HA})) if(exists($sentence->{HA}));
    @rhalignments = map {my @pair = split(/-/, $_); \@pair} (split(/\s+/, $sentence->{RH})) if(exists($sentence->{RH}));
    # Get HTML for the three sentences with alignments.
    my ($srcrow, $tgtrow, $hyprow, $rhrow, $hrrow);
    if(exists($sentence->{RA}))
    {
        $srcrow = AddicterHTML::sentence_to_table_row($config{experiment}, \@srcwords, \@tgtwords, \@alignments, 0);
        $tgtrow = AddicterHTML::sentence_to_table_row($config{experiment}, \@tgtwords, \@srcwords, \@alignments, 1);
    }
    if(exists($sentence->{HA}))
    {
        $hyprow = AddicterHTML::sentence_to_table_row($config{experiment}, \@hypwords, \@srcwords, \@halignments, 1);
    }
    if(exists($sentence->{RH}))
    {
        $rhrow = AddicterHTML::sentence_to_table_row($config{experiment}, \@tgtwords, \@hypwords, \@rhalignments, 1);
        $hrrow = AddicterHTML::sentence_to_table_row($config{experiment}, \@hypwords, \@tgtwords, \@rhalignments, 0);
    }
    my @rowpairs = grep {1} ($srcrow, $tgtrow, $hyprow, $rhrow, $hrrow);
    # We can display all three pairs of rows in one table or we can display them in separate tables.
    my $onetable = 0;
    if($onetable)
    {
        # Display the source words along with their alignment links.
        $html .= "<table border style='font-family:Code2000'>\n";
        # An empty row separates source and target sections.
        $html .= join("  <tr><td></td></tr>\n", @rowpairs);
        $html .= "</table>\n";
    }
    else # separate tables
    {
        foreach my $rowpair (@rowpairs)
        {
            # Display the source words along with their alignment links.
            $html .= "<table border style='font-family:Code2000'>\n";
            $html .= $rowpair;
            $html .= "</table>\n";
        }
    }
    # Additional information by finderrs.pl from Mark's Testchamber.
    if(exists($sentence->{XML}))
    {
        my $xmlrecord = $sentence->{XML};
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
