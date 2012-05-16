#!/usr/bin/perl
# Addicter CGI viewer: alignment summary
# Copyright © 2010-2012 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
use dzcgi;
use cas;
use AddicterHTML;

# Remember when we started generating the page so that we can figure out the duration.
$starttime = time();
# Print the HTML header (so that any debugging can possibly also output to the browser).
print("Content-type: text/html; charset=utf8\n\n");
print("<html>\n");
print("<head>\n");
print("  <meta http-equiv='content-type' content='text/html; charset=utf8'/>\n");
print("  <title>Addicter</title>\n");
print("</head>\n");
print("<body>\n");
print("  <style><!-- A:link, A:visited { text-decoration: none } A:hover { text-decoration: underline } --></style>");
# Read cgi parameters.
dzcgi::cist_parametry(\%config);
# For debugging purposes, read parameters also from @ARGV.
dzcgi::cist_parametry_argv(\%config);
if(exists($config{experiment}))
{
    # Path to experiment we are analyzing (can be relative to the location of this script).
    $experiment = $config{experiment};
    print("<h1>$config{word}</h1>\n");
    print("  <div><a href='index.pl?experiment=$config{experiment}'>Back to Experiment Main Page</a></div>");
    # Figure out the name of the index file.
    $config{word} =~ m/^(.)/;
    $fl = $1;
    $indexname = sprintf("$experiment/$config{lang}index%04x.txt", ord($fl));
    # Read the index.
    open(INDEX, $indexname) or print("<p style='color:red'>Cannot open $indexname: $!</p>\n");
    while(<INDEX>)
    {
        # Chop off the line break.
        s/\r?\n$//;
        # Tab is the field separator.
        my @fields = split(/\t/, $_);
        my $word = shift(@fields);
        my @links = map {m/^(\w+):(\d+):(.*)$/; {'file' => $1, 'line' => $2, 'aliphrase' => $3}} (@fields);
        $index{$word} = \@links;
    }
    close(INDEX);
    if(exists($index{$config{word}}))
    {
        my @examples;
        if($config{filter} eq 'tr')
        {
            @examples = grep {$_->{file} =~ m/^(TRS|TRT)$/} (@{$index{$config{word}}});
        }
        elsif($config{filter} eq 'r')
        {
            @examples = grep {$_->{file} =~ m/^(S|R)$/} (@{$index{$config{word}}});
        }
        elsif($config{filter} eq 'h')
        {
            @examples = grep {$_->{file} =~ m/^(S|H)$/} (@{$index{$config{word}}});
        }
        else
        {
            @examples = @{$index{$config{word}}};
        }
        # Compute and print summary of alignments.
        my %alicps;
        foreach my $occ (grep {$_->{file} ne 'PT'} (@examples))
        {
            my $acp = $occ->{aliphrase};
            $alicps{$acp}++;
        }
        my @alicps = sort {$alicps{$b} <=> $alicps{$a}} (keys(%alicps));
        print("<h2>Alignment summary</h2>\n");
        my $n = 0;
        my $list;
        for(my $i = 0; $i<=$#alicps; $i++)
        {
            my $acp = $alicps[$i];
            my $c = $alicps{$acp};
            $n += $c;
            if($i<20)
            {
                $list .= '  <li>'.AddicterHTML::word_to_link($experiment, swaplang(), $acp)." ($c)</li>\n";
            }
        }
        print("<p>The word '$config{word}' occurred $n times and got aligned to ", scalar(@alicps), " distinct words/phrases. The most frequent ones follow (with frequencies):</p>\n");
        print("<ol>\n");
        print($list);
        print("</ol>\n");
    }
    else
    {
        print("<p style='color:red'>Unknown word $config{word}.</p>\n");
    }
}
else
{
    print("<p style='color:red'>No experiment specified.</p>\n");
}
# Figure out the duration of the program and report it.
my $report = cas::sestavit_hlaseni_o_trvani_programu($starttime, 'en');
print("  <div align=right><address>$report</address></div>\n");
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
    my $srcline = AddicterHTML::get_nth_line($files->{$srcfile}, $sntno);
    my $tgtline = AddicterHTML::get_nth_line($files->{$tgtfile}, $sntno);
    my $aliline = AddicterHTML::get_nth_line($files->{$alifile}, $sntno);
    # Decompose alignments into array of arrays (pairs).
    my @alignments = map {my @pair = split(/-/, $_); \@pair} (split(/\s+/, $aliline));
    my @srcwords = split(/\s+/, $srcline);
    my @tgtwords = split(/\s+/, $tgtline);
    #Display the sentence
    $html .= "<dl>";
    $html .= "<dt>source</dt>";
    $html .= "<dd>$srcline</dd>";
    $html .= "<dt>translation</dt>";
    $html .= "<dd>$tgtline</dd>";
    $html .= "</dl>";
    # Display the source words along with their alignment links.
    $html .= "<table border style='font-family:Code2000'>\n";
    $html .= AddicterHTML::sentence_to_table_row($config{experiment}, \@srcwords, \@tgtwords, \@alignments, 0, $config{word});
    # An empty row separates source and target sections.
    $html .= "  <tr><td></td></tr>\n";
    # Display the target words along with their alignment links.
    $html .= AddicterHTML::sentence_to_table_row($config{experiment}, \@tgtwords, \@srcwords, \@alignments, 1, $config{word}, \&translit_russian);
    ###!!! If the filter is test+reference, show a third row with system hypothesis.
    if($config{filter} eq 'r')
    {
        my $tgtline = AddicterHTML::get_nth_line($files->{H}, $sntno);
        my $aliline = AddicterHTML::get_nth_line($files->{HA}, $sntno);
        # Decompose alignments into array of arrays (pairs).
        my @alignments = map {my @pair = split(/-/, $_); \@pair} (split(/\s+/, $aliline));
        my @tgtwords = split(/\s+/, $tgtline);
        $html .= "  <tr><td></td></tr>\n";
        $html .= AddicterHTML::sentence_to_table_row($config{experiment}, \@tgtwords, \@srcwords, \@alignments, 1, $config{word}, \&translit_russian);
    }
    $html .= "</table>\n";
    return $html;
}



#------------------------------------------------------------------------------
# Transliterates text from a Brahmi-based script to the Roman alphabet. Can be
# applied to the displayed words. Uses the global hash %prevod.
#------------------------------------------------------------------------------
sub translit_brahmi
{
    my $input = shift;
    my $output = translit::prevest(\%prevod, $input);
    return $output;
}



#------------------------------------------------------------------------------
# Transliterates text from Russian Cyrillic to the Roman alphabet. Can be
# applied to the displayed words.
#------------------------------------------------------------------------------
sub translit_russian
{
    my $input = shift;
    # Just a test... obviously it is very inefficient to declare the transliteration table here!
    # Unicode hex 400..45F (dec 1024..1119)
    # chr(200) ... LATIN CAPITAL LETTER E WITH GRAVE
    # chr(232) ... LATIN SMALL LETTER E WITH GRAVE
    my @roman = (chr(200), 'Ë', 'DJ', 'GJ', 'JE', 'S', 'I', 'JI', 'J', 'LJ', 'NJ', 'Ć', 'KJ', 'I', 'W', 'DŽ',
                 'A', 'B', 'V', 'G', 'D', 'E', 'Ž', 'Z', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'F', 'H', 'C', 'Č', 'Š', 'ŠČ', "''", 'Y', "'", chr(200), 'JU', 'JA',
                 'a', 'b', 'v', 'g', 'd', 'e', 'ž', 'z', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'r', 's', 't', 'u', 'f', 'h', 'c', 'č', 'š', 'šč', "''", 'y', "'", chr(232), 'ju', 'ja',
                 chr(232), 'ë', 'dj', 'gj', 'je', 's', 'i', 'ji', 'j', 'lj', 'nj', 'ć', 'kj', 'i', 'w', 'dž');
    my %prevod;
    for(my $i = 0; $i<=$#roman; $i++)
    {
        $prevod{chr(1024+$i)} = $roman[$i];
    }
    my $output = translit::prevest(\%prevod, $input);
    return $output;
}



#------------------------------------------------------------------------------
# Changes the language parameter to the other value. Returns the other value.
# Useful for creating cross links.
#------------------------------------------------------------------------------
sub swaplang
{
    my $current = shift;
    $current = $config{lang} unless($current);
    # Return target if current is source.
    if($current =~ m/^s/i)
    {
        return 't';
    }
    # Return source if current is target.
    elsif($current =~ m/^t/i)
    {
        return 's';
    }
    # If current is neither source nor target, return unknown.
    else
    {
        return 'x';
    }
}
