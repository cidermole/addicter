#!/usr/bin/perl
# Addicter CGI viewer
# Copyright © 2010 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use lib 'C:\Documents and Settings\Dan\Dokumenty\Lingvistika\lib';
use lib '/home/zeman/lib';
use dzcgi;
use translit;
use translit::brahmi;

# Path to experiment we are analyzing (can be relative to the location of this script).
$experiment = 'enur';
# Print the HTML header (so that any debugging can possibly also output to the browser).
print("Content-type: text/html; charset=utf8\n\n");
print("<html>\n");
print("<head>\n");
print("  <meta http-equiv='content-type' content='text/html; charset=utf8'/>\n");
print("  <title>Addicter</title>\n");
print("</head>\n");
print("<body>\n");
print("  <style><!-- A:link, A:visited { text-decoration: none } A:hover { text-decoration: underline } --></style>");
# 0x900: Písmo devanágarí.
translit::brahmi::inicializovat(\%prevod, 2304, 1);
# Read cgi parameters.
dzcgi::cist_parametry(\%config);
print("<h1>$config{word}</h1>\n");
# Figure out the name of the index file.
$config{word} =~ m/^(.)/;
$fl = $1;
$indexname = sprintf("$experiment/index%04x.txt", ord($fl));
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
# Print the first sentence pair where the word occurs.
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
    my $numsnt = scalar(@examples);
    print("<style>span.x:hover {color:green}</style>\n");
    my $plural = $numsnt>1 ? 's' : '';
    print("<p>Examples <span class='x'>of</span> the word in the <span class='x'>$config{filter}</span> data:\n");
    print("   The word '$config{word}' occurs in $numsnt sentence$plural.\n");
    if($numsnt>0)
    {
        my $example;
        my @links;
        if($config{exno}>=0 && $config{exno}<=$#examples)
        {
            $example = $examples[$config{exno}];
            if($config{exno}>0)
            {
                my $prevexno = $config{exno}-1;
                ###!!! all parameters should be preserved, not just filter
                push(@links, "<a href='example.pl?word=$config{word}&amp;exno=$prevexno&amp;filter=$config{filter}'>previous</a>");
            }
            if($config{exno}<$#examples)
            {
                my $nextexno = $config{exno}+1;
                ###!!! all parameters should be preserved, not just filter
                push(@links, "<a href='example.pl?word=$config{word}&amp;exno=$nextexno&amp;filter=$config{filter}'>next</a>");
            }
        }
        else
        {
            $example = $examples[0];
            if($#examples>0)
            {
                ###!!! all parameters should be preserved, not just filter
                push(@links, "<a href='example.pl?word=$config{word}&amp;exno=1&amp;filter=$config{filter}'>next</a>");
            }
        }
        # So what do we need to read?
        my $sntno = $example->{line};
        my ($srcfile, $tgtfile, $alifile);
        if($example->{file} eq 'TRS' || $example->{file} eq 'TRT')
        {
            $srcfile = 'TRS';
            $tgtfile = 'TRT';
            $alifile = 'TRA';
        }
        elsif($example->{file} eq 'S' || $example->{file} eq 'R')
        {
            $srcfile = 'S';
            $tgtfile = 'R';
            $alifile = 'RA';
        }
        else
        {
            $srcfile = 'S';
            $tgtfile = 'H';
            $alifile = 'HA';
        }
        print("   This is the sentence number $example->{line} in file $example->{file}.</p>\n");
        ###!!! We should read this from the index file.
        my $path = "$experiment/";
        # my $path = 'C:\Documents and Settings\Dan\Dokumenty\Lingvistika\Projekty\addicter\';
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
        my $srcline = get_nth_line($files{$srcfile}, $sntno);
        my $tgtline = get_nth_line($files{$tgtfile}, $sntno);
        my $aliline = get_nth_line($files{$alifile}, $sntno);
        # Decompose alignments into array of arrays (pairs).
        my @alignments = map {my @pair = split(/-/, $_); \@pair} (split(/\s+/, $aliline));
        my @srcwords = split(/\s+/, $srcline);
        my @tgtwords = split(/\s+/, $tgtline);
        # Display the source words along with their alignment links.
        print("<table border style='font-family:Code2000'>\n");
        print("  <tr>");
        for(my $i = 0; $i<=$#srcwords; $i++)
        {
            if($srcwords[$i] eq $config{word})
            {
                print("<td style='color:red'>$srcwords[$i]</td>");
            }
            else
            {
                # Every word except for the current one is a link to its own examples.
                print("<td><a href='example.pl?word=$srcwords[$i]'>$srcwords[$i]</a></td>");
            }
        }
        print("</tr>\n");
        print("  <tr>");
        for(my $i = 0; $i<=$#srcwords; $i++)
        {
            my $ali_word = join('&nbsp;', map {join('-', @{$_})} (grep {$_->[0]==$i} (@alignments)));
            my $ali_ctpart = join('&nbsp;', map {$tgtwords[$_->[1]] eq $config{word} ? "<span style='color:red'>$tgtwords[$_->[1]]</span>" : $tgtwords[$_->[1]]} (grep {$_->[0]==$i} (@alignments)));
            print("<td>$ali_ctpart<br/>$ali_word</td>");
        }
        print("</tr>\n");
#        print("</table>\n");
        # Display the target words along with their alignment links.
#        print("<table>\n");
        print("  <tr><td></td></tr>\n");
        print("  <tr>");
        for(my $i = 0; $i<=$#tgtwords; $i++)
        {
            my $ali_word = join('&nbsp;', map {join('-', @{$_})} (grep {$_->[1]==$i} (@alignments)));
            my $ali_ctpart = join('&nbsp;', map {$srcwords[$_->[0]] eq $config{word} ? "<span style='color:red'>$srcwords[$_->[0]]</span>" : $srcwords[$_->[0]]} (grep {$_->[1]==$i} (@alignments)));
            print("<td>$ali_word<br/>$ali_ctpart</td>");
        }
        print("</tr>\n");
        print("  <tr>");
        for(my $i = 0; $i<=$#tgtwords; $i++)
        {
            my $translit = translit::prevest(\%prevod, $tgtwords[$i]);
            if($tgtwords[$i] eq $config{word})
            {
                print("<td style='color:red'>$tgtwords[$i]<br/>$translit</td>");
            }
            else
            {
                # Every word except for the current one is a link to its own examples.
                print("<td><a href='example.pl?word=$tgtwords[$i]'>$tgtwords[$i]</a><br/>$translit</td>");
            }
        }
        ###!!! If the filter is test+reference, show a third row with system hypothesis.
        if($config{filter} eq 'r')
        {
            my $tgtline = get_nth_line($files{H}, $sntno);
            my $aliline = get_nth_line($files{HA}, $sntno);
            # Decompose alignments into array of arrays (pairs).
            my @alignments = map {my @pair = split(/-/, $_); \@pair} (split(/\s+/, $aliline));
            my @tgtwords = split(/\s+/, $tgtline);
            print("  <tr><td></td></tr>\n");
            print("  <tr>");
            for(my $i = 0; $i<=$#tgtwords; $i++)
            {
                my $ali_word = join('&nbsp;', map {join('-', @{$_})} (grep {$_->[1]==$i} (@alignments)));
                my $ali_ctpart = join('&nbsp;', map {$srcwords[$_->[0]] eq $config{word} ? "<span style='color:red'>$srcwords[$_->[0]]</span>" : $srcwords[$_->[0]]} (grep {$_->[1]==$i} (@alignments)));
                print("<td>$ali_word<br/>$ali_ctpart</td>");
            }
            print("</tr>\n");
            print("  <tr>");
            for(my $i = 0; $i<=$#tgtwords; $i++)
            {
                my $translit = translit::prevest(\%prevod, $tgtwords[$i]);
                if($tgtwords[$i] eq $config{word})
                {
                    print("<td style='color:red'>$tgtwords[$i]<br/>$translit</td>");
                }
                else
                {
                    # Every word except for the current one is a link to its own examples.
                    print("<td><a href='example.pl?word=$tgtwords[$i]'>$tgtwords[$i]</a><br/>$translit</td>");
                }
            }
        }
        print("</tr>\n");
        print("</table>\n");
        # Print links to adjacent examples.
        ###!!! Add links to filters: training only, test/reference, test/hypothesis.
        push(@links, "<a href='example.pl?word=$config{word}&amp;filter=tr'>training data only</a>");
        push(@links, "<a href='example.pl?word=$config{word}&amp;filter=r'>test/reference</a>");
        push(@links, "<a href='example.pl?word=$config{word}&amp;filter=h'>test/hypothesis</a>");
        if(scalar(@links))
        {
            my $links = join(' | ', @links);
            print("<p>$links</p>\n");
        }
        # Compute and print summary of alignments.
        my %alicps;
        foreach my $occ (@examples)
        {
            my $acp = $occ->{aliphrase};
            # Transliteration needed? If $occ is source, then aliphrase is target, i.e. Hindi.
            if($occ->{file} eq 'TRS' || $occ->{file} eq 'S')
            {
                my $translit = translit::prevest(\%prevod, $acp);
                # Punctuation etc. would not differ after transliteration, so check if it made a difference.
                if($translit ne $acp)
                {
                    $acp = "$acp / $translit";
                }
            }
            $alicps{$acp}++;
        }
        my @alicps = sort {$alicps{$b} <=> $alicps{$a}} (keys(%alicps));
        print("<h2>Alignment summary</h2>\n");
        print("<p>The word '$config{word}' got aligned to ", scalar(@alicps), " distinct words/phrases. The most frequent ones follow (with frequencies):</p>\n");
        print("<ol>\n");
        for(my $i = 0; $i<=$#alicps && $i<20; $i++)
        {
            my $acp = $alicps[$i];
            print("  <li>$acp ($alicps{$acp})</li>\n");
        }
        print("</ol>\n");
    }
}
else
{
    print("<p style='color:red'>Unknown word $config{word}.</p>\n");
}
# Close the HTML document.
print("</body>\n");
print("</html>\n");



###############################################################################
# SUBROUTINES
###############################################################################



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
