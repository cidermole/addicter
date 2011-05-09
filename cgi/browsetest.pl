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
        'HA'  => "${path}test.system.ali"
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
        print(sentence_to_table($sntno, $files{S}, $files{R}, $files{RA}, $files{H}, $files{HA}));
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
    push(@links, $next<$numsnt ? "<a href='browsetest.pl?experiment=$config{experiment}&amp;sntno=$next'>next</a>" : 'next');
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
    my $html;
    my $srcline = get_nth_line($srcfile, $sntno);
    my $tgtline = get_nth_line($tgtfile, $sntno);
    my $aliline = get_nth_line($alifile, $sntno);
    my $hypline = get_nth_line($hypfile, $sntno);
    my $haliline = get_nth_line($halifile, $sntno);
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
    my $srcrow = sentence_to_table_row(\@srcwords, \@tgtwords, \@alignments, 0);
    my $tgtrow = sentence_to_table_row(\@tgtwords, \@srcwords, \@alignments, 1);
    my $hyprow = sentence_to_table_row(\@hypwords, \@srcwords, \@halignments, 1);
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
    return $html;
}



#------------------------------------------------------------------------------
# Generates a part of an HTML table with a sentence and corresponding aligned
# words from the other language. The function generates two table rows. One row
# contains words (tokens) of the sentence. The other row contains the
# alignments: numeric indices and the actual tokens from the corresponding
# sentence in the other language. The tokens in the main row are linked to
# word example pages. Tokens in the alignment row are not hyperlinks. By
# default, the main row is displayed first and the alignment row second. They
# can be swapped by specifying that the sentence is in the target language.
#------------------------------------------------------------------------------
sub sentence_to_table_row
{
    # Source and target of the alignment, not necessarily source and target languages in the experiment analyzed.
    my $srcwords = shift; # array reference
    my $tgtwords = shift; # array reference
    my $alignments = shift; # reference to array of arrays (pairs).
    my $target = shift; # 0|1: influences not only the order of the table rows
    my ($linklang, $aithis, $aithat);
    unless($target)
    {
        $linklang = 's';
        $aithis = 0;
        $aithat = 1;
    }
    else
    {
        $linklang = 't';
        $aithis = 1;
        $aithat = 0;
    }
    my $mainrow;
    $mainrow .= "  <tr>";
    for(my $i = 0; $i<=$#{$srcwords}; $i++)
    {
        # Every word except for the current one is a link to its own examples.
        $mainrow .= '<td>'.word_to_link($config{experiment}, $linklang, $srcwords->[$i]).'</td>';
    }
    $mainrow .= "</tr>\n";
    # Second row contains target words aligned to source words.
    my $alirow;
    $alirow .= "  <tr>";
    for(my $i = 0; $i<=$#{$srcwords}; $i++)
    {
        my $ali_word = join('&nbsp;', map {join('-', @{$_})} (grep {$_->[$aithis]==$i} (@{$alignments})));
        my $ali_ctpart = join('&nbsp;', map {$tgtwords->[$_->[$aithat]]} (grep {$_->[$aithis]==$i} (@{$alignments})));
        $alirow .= "<td>$ali_ctpart<br/>$ali_word</td>";
    }
    $alirow .= "</tr>\n";
    # Put the two rows together.
    my $html = $target ? $alirow.$mainrow : $mainrow.$alirow;
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



#------------------------------------------------------------------------------
# Reads the n-th sentence (line) from a file. Does not assume we want to read
# more so it opens and closes the file. Definitely not the most efficient way
# of reading the whole file! Before returning the line, the function strips the
# final line-break character.
#------------------------------------------------------------------------------
sub get_nth_line
{
    my $path = shift;
    my $n = shift;
    open(IN, $path) or print("<p style='color:red'>Cannot read $path: $!</p>\n");
    my $line;
    for(my $i = 0; $i<=$n; $i++)
    {
        $line = <IN>;
    }
    close(IN);
    $line =~ s/\r?\n$//;
    return $line;
}



#------------------------------------------------------------------------------
# Converts a word into a hyperlink to the page with an example of the word as
# occurs in the corpus.
#------------------------------------------------------------------------------
sub word_to_link
{
    my $experiment = shift;
    my $lang = shift;
    my $word = shift;
    my $html = "<a href='example.pl?experiment=$experiment&amp;lang=$lang&amp;word=$word'>$word</a>";
    return $html;
}
