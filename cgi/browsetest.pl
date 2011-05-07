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
    my $numsnt = 1; ###!!!
    my $plural = $numsnt>1 ? 's' : '';
    if($numsnt>0)
    {
        my $example;
        # So what do we need to read?
        my $sntno = 1; ###!!!
        my ($srcfile, $tgtfile, $alifile);
        ###!!! Tohle jsem okopíroval z example.pl, ale umí to jen dvě verze věty najednou.
        ###!!! Tady bych potřeboval současně zdroj, referenci a hypotézu.
        $srcfile = 'S';
        $tgtfile = 'R';
        $alifile = 'RA';
        ###!!!$tgtfile = 'H';
        ###!!!$alifile = 'HA';
        print("  <p>This is the test sentence number $sntno:</p>\n");
        print(sentence_to_table(\%files, $sntno, $srcfile, $tgtfile, $alifile));
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
# Generates a HTML table with a sentence pair/triple (for test data, triples of
# source, reference and hypothesis may be available).
#------------------------------------------------------------------------------
sub sentence_to_table
{
    # This function accesses the global hashes %config and %prevod.
    my $files = shift;
    my $sntno = shift;
    my $srcfile = shift;
    my $tgtfile = shift;
    my $alifile = shift;
    my $html;
    my $srcline = get_nth_line($files->{$srcfile}, $sntno);
    my $tgtline = get_nth_line($files->{$tgtfile}, $sntno);
    my $aliline = get_nth_line($files->{$alifile}, $sntno);
    # Print raw sentences first. No tables, to make reading easier.
    $html .= "<dl>\n";
    $html .= "  <dt><b>source</b></dt>\n";
    $html .= "  <dd>$srcline</dd>\n";
    $html .= "  <dt><b>target</b></dt>\n";
    $html .= "  <dd>$tgtline</dd>\n";
    $html .= "</dl>\n";
    # Decompose alignments into array of arrays (pairs).
    my @alignments = map {my @pair = split(/-/, $_); \@pair} (split(/\s+/, $aliline));
    my @srcwords = split(/\s+/, $srcline);
    my @tgtwords = split(/\s+/, $tgtline);
    # Display the source words along with their alignment links.
    $html .= "<table border style='font-family:Code2000'>\n";
    $html .= "  <tr>";
    for(my $i = 0; $i<=$#srcwords; $i++)
    {
        if($srcwords[$i] eq $config{word})
        {
            $html .= "<td style='color:red'>$srcwords[$i]</td>";
        }
        else
        {
            # Every word except for the current one is a link to its own examples.
            $html .= '<td>'.word_to_link($config{experiment}, 's', $srcwords[$i]).'</td>';
        }
    }
    $html .= "</tr>\n";
    # Second row contains target words aligned to source words.
    $html .= "  <tr>";
    for(my $i = 0; $i<=$#srcwords; $i++)
    {
        my $ali_word = join('&nbsp;', map {join('-', @{$_})} (grep {$_->[0]==$i} (@alignments)));
        my $ali_ctpart = join('&nbsp;', map {$tgtwords[$_->[1]] eq $config{word} ? "<span style='color:red'>$tgtwords[$_->[1]]</span>" : $tgtwords[$_->[1]]} (grep {$_->[0]==$i} (@alignments)));
        $html .= "<td>$ali_ctpart<br/>$ali_word</td>";
    }
    $html .= "</tr>\n";
    # An empty row separates source and target sections.
    $html .= "  <tr><td></td></tr>\n";
    # Display the target words along with their alignment links.
    $html .= "  <tr>";
    for(my $i = 0; $i<=$#tgtwords; $i++)
    {
        my $ali_word = join('&nbsp;', map {join('-', @{$_})} (grep {$_->[1]==$i} (@alignments)));
        my $ali_ctpart = join('&nbsp;', map {$srcwords[$_->[0]] eq $config{word} ? "<span style='color:red'>$srcwords[$_->[0]]</span>" : $srcwords[$_->[0]]} (grep {$_->[1]==$i} (@alignments)));
        $html .= "<td>$ali_word<br/>$ali_ctpart</td>";
    }
    $html .= "</tr>\n";
    $html .= "  <tr>";
    for(my $i = 0; $i<=$#tgtwords; $i++)
    {
        if($tgtwords[$i] eq $config{word})
        {
            $html .= "<td style='color:red'>$tgtwords[$i]</td>";
        }
        else
        {
            # Every word except for the current one is a link to its own examples.
            $html .= '<td>'.word_to_link($config{experiment}, 't', $tgtwords[$i])."</td>";
        }
    }
    ###!!! If the filter is test+reference, show a third row with system hypothesis.
    if($config{filter} eq 'r')
    {
        my $tgtline = get_nth_line($files->{H}, $sntno);
        my $aliline = get_nth_line($files->{HA}, $sntno);
        # Decompose alignments into array of arrays (pairs).
        my @alignments = map {my @pair = split(/-/, $_); \@pair} (split(/\s+/, $aliline));
        my @tgtwords = split(/\s+/, $tgtline);
        $html .= "  <tr><td></td></tr>\n";
        $html .= "  <tr>";
        for(my $i = 0; $i<=$#tgtwords; $i++)
        {
            my $ali_word = join('&nbsp;', map {join('-', @{$_})} (grep {$_->[1]==$i} (@alignments)));
            my $ali_ctpart = join('&nbsp;', map {$srcwords[$_->[0]] eq $config{word} ? "<span style='color:red'>$srcwords[$_->[0]]</span>" : $srcwords[$_->[0]]} (grep {$_->[1]==$i} (@alignments)));
            $html .= "<td>$ali_word<br/>$ali_ctpart</td>";
        }
        $html .= "</tr>\n";
        $html .= "  <tr>";
        for(my $i = 0; $i<=$#tgtwords; $i++)
        {
            if($tgtwords[$i] eq $config{word})
            {
                $html .= "<td style='color:red'>$tgtwords[$i]</td>";
            }
            else
            {
                # Every word except for the current one is a link to its own examples.
                $html .= '<td>'.word_to_link($config{experiment}, 't', $tgtwords[$i])."</td>";
            }
        }
    }
    $html .= "</tr>\n";
    $html .= "</table>\n";
    return $html;
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
