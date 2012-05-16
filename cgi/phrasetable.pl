#!/usr/bin/perl
# Addicter CGI viewer: searching the phrase table
# Copyright © 2011-2012 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
use dzcgi;
use cas;

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
    $path = "$experiment/";
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
        @examples = grep {$_->{file} =~ m/^PT$/} (@{$index{$config{word}}});
        if(scalar(@examples))
        {
            print("<h2>Phrase table</h2>\n");
            # A phrase table may be huge (millions of lines) and we cannot seek every example from scratch.
            # So we cannot use AddicterHTML::get_nth_line().
            print("<table border>\n");
            my $phrase_table = $path.'phrase_table.txt';
            open(IN, $phrase_table) or print("<p style='color:red'>Cannot read $phrase_table: $!</p>\n");
            my $i_example = 0;
            my $i_line = 0;
            while(my $line = <IN>)
            {
                if($i_line==$examples[$i_example]->{line})
                {
                    # Chop off the line break.
                    $line =~ s/\r?\n$//;
                    # Fields are separated by three vertical bars.
                    # List of fields: left hand side ||| source right hand side ||| target right hand side ||| weights
                    # Example:
                    # [X] ||| 100 [X,1] du [X,2] ||| 100 [X,1] of the [X,2] ||| 0.30103 1.0637686 1.1094114
                    my @fields = split(/\s*\|\|\|\s*/, $line);
                    my $ie = $i_example+1;
                    my $il = $i_line+1;
                    print("  <tr><td>$ie</td><td>$il</td><td>".join('</td><td>', @fields)."</td></tr>\n");
                    $i_example++;
                    last if($i_example>$#examples);
                }
                $i_line++;
            }
            close(IN);
            print("</table>\n");
        }
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
