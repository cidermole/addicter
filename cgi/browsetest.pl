#!/usr/bin/perl
# Displays HTML page with one segment of test data (source language, reference translation, MT system hypothesis).
# Copyright © 2011 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use dzcgi;
use AddicterHTML;
use ReadFindErrs;

# Print the HTML header (so that any debugging can possibly also output to the browser).
print("Content-type: text/html; charset=utf8\n\n");
print("<html>\n");
print("<head>\n");
print("  <meta http-equiv='content-type' content='text/html; charset=utf8'/>\n");
print("  <title>Addicter: Test Data Browsing</title>\n");
# CSS tab navigation tutorial found at http://blixt.org/articles/tabbed-navigation-using-css
print("  <style>\n");
print("    ol#toc { height: 2em; list-style: none; margin: 0; padding: 0; }\n");
print("    ol#toc li { float: left; margin: 0 1px 0 0; }\n");
print("    ol#toc a { background: #bdf url(../tabs.gif); color: #008; display: block; float: left; height: 2em; padding-left: 10px; text-decoration: none; }\n");
print("    ol#toc a:hover { background-color: #3af; background-position: 0 -120px; }\n");
print("    ol#toc a:hover span { background-position: 100% -120px; }\n");
print("    ol#toc li a.active { background-color: #48f; background-position: 0 -60px; }\n");
print("    ol#toc li a.active span { background-position: 100% -60px; }\n");
print("    ol#toc span { background: url(../tabs.gif) 100% 0; display: block; line-height: 2em; padding-right: 10px; }\n");
print("    div.content { border: #48f solid 3px; clear: left; padding: 1em; }\n");
print("    div.inactive { display: none }\n");
# Note: reportedly, Internet Explorer only supports :hover subclass for the <a> element. This might work in other browsers, though.
#print("    td:hover { background-color: yellow; }\n");
#print("    td a:hover { background-color: yellow; }\n");
#print("    td.a8_8:hover { background-color: yellow; }\n");
print("  </style>\n");
print <<EOF
<script>
// Gets the list of classes of an element.
// Sets the background color of all those classes to yellow.
// Used to highlight all corresponding table cells when mouse is over one of them.
// Each cell should have something like onmouseover='javascript:highlightCells(this)'
function highlightCells(cellId)
{
    // Remove the highlighting stylesheet if already present in the document.
    // getElementById() returns null if the stylesheet does not exist.
    var sheetToBeRemoved = document.getElementById('highlightStyle');
    if (sheetToBeRemoved != null)
    {
        var sheetParent = sheetToBeRemoved.parentNode;
        sheetParent.removeChild(sheetToBeRemoved);
    }
    // Create a new stylesheet.
    var sheet = document.createElement('style');
    sheet.id = 'highlightStyle';
    // Now fill the stylesheet with highlighting rules.
    var cell = document.getElementById(cellId);
    var classes = cell.className.split(/\s+/);
    for (var i = 0; i < classes.length; i++)
    {
        //alert('highlighting td.'+classes[i]+" { background-color: yellow; }");
        // Set the background color of the class to yellow.
        //sheet.insertRule("td."+classes[i]+" { background-color: yellow; }", i);
        sheet.innerHTML = sheet.innerHTML+"td."+classes[i]+" { background-color: yellow; }";
    }
    document.body.appendChild(sheet);
}
</script>
EOF
;
print("</head>\n");
print("<body>\n");
# We do not want underlined hyperlinks unless the mouse goes over them.
print("  <style><!-- A:link, A:visited { text-decoration: none } A:hover { text-decoration: underline } --></style>\n");
# Read cgi parameters.
dzcgi::cist_parametry(\%config);
if(exists($config{experiment}))
{
    my $path = "$config{experiment}/";
    print("  <h1>Test Data of $config{experiment}</h1>\n");
    print("  <div><a href='index.pl?experiment=$config{experiment}'>Back to Experiment Main Page</a></div>");
    print("  <div><a href='tcerrread.pl?experiment=$config{experiment}'>Back to Error Summary</a></div>");
    # How many lines (sentences) are there in the test data?
    my $numsnt = count_lines("$config{experiment}/test.src");
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
    # Are there subfolders with alternative RH alignments?
    my $subfolders = get_subfolders($experiment);
    $sentence{sub} = $subfolders;
    $sentence{sntno} = $sntno;
    return \%sentence;
}



#------------------------------------------------------------------------------
# Scans the experiment folder for subfolders. E.g. there could be alternative
# reference-hypothesis alignments created using different methods.
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
    $html .= "  <dt><b>reference translation</b></dt>\n";
    $html .= "  <dd>$sentence->{R}</dd>\n";
    $html .= "  <dt><b>system hypothesis</b></dt>\n";
    $html .= "  <dd>$sentence->{H}</dd>\n";
    $html .= "</dl>\n";
    $html .= "<ol id='toc'>\n";
    # Make the first alignment active.
    my $activealiid = $sentence->{sub}[0];
    foreach my $aliid (@{$sentence->{sub}})
    {
        ###!!! If I set the active class when generating the page It will appear active even after the user clicks another tab.
        ###!!! If I do not set it here no tab will appear active until the user clicks one.
        #my $class = $aliid eq $activealiid ? 'active' : 'inactive';
        #$html .= "  <li><a href='#$aliid' class='$class'><span>$aliid</span></a></li>\n";
        $html .= "  <li><a href='#$aliid'><span>$aliid</span></a></li>\n";
    }
    $html .= "</ol>\n";
    # Decompose alignments into array of arrays (pairs).
    my @srcwords = split(/\s+/, $sentence->{S});
    my @tgtwords = split(/\s+/, $sentence->{R});
    my @hypwords = split(/\s+/, $sentence->{H});
    my @alignments;
    my @halignments;
    my @rhalignments;
    @alignments = map {my @pair = split(/-/, $_); \@pair} (split(/\s+/, $sentence->{RA})) if(exists($sentence->{RA}));
    @halignments = map {my @pair = split(/-/, $_); \@pair} (split(/\s+/, $sentence->{HA})) if(exists($sentence->{HA}));
    # There may be more than one RH (reference-hypothesis) alignment.
    foreach my $aliid (@{$sentence->{sub}})
    {
        ###!!! If I set the active class when generating the page It will appear active even after the user clicks another tab.
        ###!!! If I do not set it here no tab will appear active until the user clicks one.
        #my $class = $aliid eq $activealiid ? 'content active' : 'content inactive';
        my $class = 'content';
        $html .= "<div class='$class' id='$aliid'>\n";
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
        ###!!! If we have found a subfolder we automatically expect it to contain test.refhyp.ali.
        # In future, we may just assume that it contains any of the expected files, for which tehere are alternatives.
        # Files that are not present in a subfolder may be present in the superfolder as alternatives.
        my $aliseq = AddicterHTML::get_nth_line("$config{experiment}/$aliid/test.refhyp.ali", $sentence->{sntno});
        my $rhalignments = AddicterHTML::ali_line_to_array($aliseq);
        my $rhalindex = AddicterHTML::ali_array_index($rhalignments);
        # Additional information by finderrs.pl from Mark's Testchamber.
        my $xmlfile = "$config{experiment}/$aliid/tcerr.txt";
        my @srcstyles;
        my @tgtstyles;
        my $htmlerr; # first construct, show later (after the alignments)
        if(-f $xmlfile)
        {
            my $xmlrecord = ReadFindErrs::get_nth_sentence($xmlfile, $sentence->{sntno});
            $htmlerr .= "<h2>Automatically Identified Errors</h2>\n";
            if($xmlrecord->{state} eq 'waiting')
            {
                $htmlerr .= "<p>No information from <tt>finderrs.pl</tt> found.</p>\n";
            }
            elsif($xmlrecord->{state} eq 'finished')
            {
                $htmlerr .= "<dl>\n";
                foreach my $key (keys(%{$xmlrecord->{errors}}))
                {
                    if($key eq 'missingRefWord')
                    {
                        $htmlerr .= "<dt><b style='background-color: lightblue'>$key</b></dt>\n";
                    }
                    elsif($key eq 'extraHypWord')
                    {
                        $htmlerr .= "<dt><b style='background-color: lightblue'>$key</b></dt>\n";
                    }
                    elsif($key eq 'untranslatedHypWord')
                    {
                        $htmlerr .= "<dt><b style='background-color: orange'>$key</b></dt>\n";
                    }
                    elsif($key eq 'unequalAlignedTokens') 
                    {
                        $htmlerr .= "<dt><b>$key (ref/hyp)</b></dt>\n";
                        $htmlerr .= "<dd><b style='background-color: red'>with different lemma:</b> ";
                        $htmlerr .= join("  ", map {my$t=$_->{refToken}; $t=~s/\|.*//; my $u=$_->{hypToken}; $u=~s/\|.*//; $t."/".$u} grep {$_->{unequalFactorList} =~ m/2/} (@{$xmlrecord->{errors}{$key}}));
                        $htmlerr .= "</dd>\n";
                        $htmlerr .= "<dd><b  style='background-color: pink'>with same lemma:</b> ";
                        $htmlerr .= join(' ', map {my$t=$_->{refToken}; $t=~s/\|.*//; my $u=$_->{hypToken}; $u=~s/\|.*//; $t."/".$u} grep {$_->{unequalFactorList} !~ m/2/} (@{$xmlrecord->{errors}{$key}}));
                        $htmlerr .= "</dd>\n";
                    }
                    elsif($key eq 'ordErrorShiftWord')
                    {
                        $htmlerr .= "<dt><b style='background-color: lightgreen'>$key</b></dt>\n";
                        $htmlerr .= "<dd> ";
                        $htmlerr .= join(' ', map {my $t=$_->{hypToken}; $t=~s/\|.*//; $t} (@{$xmlrecord->{errors}{$key}}));
                        $htmlerr .= "</dd>\n";
                    }
                        elsif($key eq 'ordErrorSwitchWords')
                    {
                        $htmlerr .= "<dt><b style='background-color: lightgreen'>$key</b></dt>\n";
                        $htmlerr .= "<dd> ";
                        $htmlerr .= join(' ', map {my $t1=$_->{hypToken1}; my $t2=$_->{hypToken2}; $t1=~s/\|.*//; $t2=~s/\|.*//; $t1."-".$t2} (@{$xmlrecord->{errors}{$key}}));
                        $htmlerr .= "</dd>\n";
                    }
                    elsif($key eq 'reorderingError')
		    {
			$htmlerr .= "<dt><b style='background-color: chartreuse'>$key</b></dt>\n";
		    }
		    elsif($key eq 'inflectionalError')
		    {
			$htmlerr .= "<dt><b style='background-color: darkkhaki'>$key</b></dt>\n";
		    }
		    elsif($key eq 'otherMismatch')
		    {
			$htmlerr .= "<dt><b style='background-color: darkgreen'>$key</b></dt>\n";
		    }
		    else
                    {
                        $htmlerr .= "<dt><b>$key</b></dt>\n";
                    }
                    if (not ($key eq 'unequalAlignedTokens') and not ($key eq 'ordErrorShiftWord') and not ($key eq "ordErrorSwitchWords"))
                    {
                        $htmlerr .= "<dd>".join(' ', map {$_->{surfaceForm}} (@{$xmlrecord->{errors}{$key}}))."</dd>\n";
                    }
                    # styles for table
                    foreach my $token (@{$xmlrecord->{errors}{$key}})
                    {
                        if($key eq 'missingRefWord')
                        {
                            $srcstyles[$token->{idx}] = 'background-color: lightblue';
                        }
                        elsif($key eq 'extraHypWord')
                        {
                            $tgtstyles[$token->{idx}] = 'background-color: lightblue';
                        }
                        elsif($key eq 'untranslatedHypWord')
                        {
                            $tgtstyles[$token->{idx}] = 'background-color: orange';
                        }
                        elsif($key eq 'unequalAlignedTokens')
                        {
                            # There are three factors in this order: form|tag|lemma.
                            # If unequalFactorList includes 2 (the lemma) we'll interpret it as lexical difference.
                            # Otherwise it's morphological difference.
                            if($token->{unequalFactorList} =~ m/2/)
                            {
                                $srcstyles[$token->{refIdx}] = 'background-color: red';
                                $tgtstyles[$token->{hypIdx}] = 'background-color: red';
                            }
                            else # morphology only
                            {
                                $srcstyles[$token->{refIdx}] = 'background-color: pink';
                                $tgtstyles[$token->{hypIdx}] = 'background-color: pink';
                            }
                        }
                        elsif($key eq 'ordErrorShiftWord')
                        {
                            $tgtstyles[$token->{hypPos}] = 'background-color: lightgreen';
                            # We should use the same color for the aligned counterpart of the reordered word.
                            ###!!! OOPS! Although I called the alignment RH everywhere, it's actually HR, i.e. hypothesis left, reference right!
                            ###!!! let's do something about this later when there's time
                            foreach my $r (@{$rhalindex->{l2r}[$token->{hypPos}]})
                            {
                                $srcstyles[$r] = 'background-color: lightgreen';
                            }
                        }
                        elsif($key eq 'ordErrorSwitchWords')
                        {
                            $tgtstyles[$token->{hypIdx1}] = 'background-color: lightgreen';
                            $tgtstyles[$token->{hypIdx2}] = 'background-color: lightgreen';
                            foreach my $r (@{$rhalindex->{l2r}[$token->{hypIdx1}]}, @{$rhalindex->{l2r}[$token->{hypIdx2}]})
                            {
                                $srcstyles[$r] = 'background-color: lightgreen';
                            }
                        }
			elsif($key eq 'reorderingError')
			{
			    $srcstyles[$token->{refIdx}] = 'background-color: chartreuse';
			    $tgtstyles[$token->{hypIdx}] = 'background-color: chartreuse';
			}
			elsif($key eq 'inflectionalError')
			{
				$srcstyles[$token->{refIdx}] = 'background-color: darkkhaki';
				$tgtstyles[$token->{hypIdx}] = 'background-color: darkkhaki';
			}
			elsif($key eq 'otherMismatch')
			{
				$srcstyles[$token->{refIdx}] = 'background-color: darkgreen';
                            	$tgtstyles[$token->{hypIdx}] = 'background-color: darkgreen';
			}
                    }
                }
                $htmlerr .= "</dl>\n";
            }
            else
            {
                $htmlerr .= "<p style='color:red'>Parsing the XML file <tt>$findersxmlfile</tt> resulted in unknown state '$xmlrecord->{state}'.</p>\n";
            }
        }
        $rhrow = AddicterHTML::sentence_to_table_row($config{experiment}, \@tgtwords, \@hypwords, $rhalignments, 1, 0, 0, 0, \@srcstyles);
        $hrrow = AddicterHTML::sentence_to_table_row($config{experiment}, \@hypwords, \@tgtwords, $rhalignments, 0, 0, 0, 0, \@tgtstyles);
        
	$srcrow = substr($srcrow,0,6) .  "<th rowspan=2>src-ref</th>" . substr($srcrow,6);
	$tgtrow = substr($tgtrow,0,6) .  "<th rowspan=2>ref-src</th>" . substr($tgtrow,6);
	$hyprow = substr($hyprow,0,6) .  "<th rowspan=2>hyp-src</th>" . substr($hyprow,6);
	$rhrow = substr($rhrow,0,6) .  "<th rowspan=2>ref-hyp</th>" . substr($rhrow,6);
	$hrrow = substr($hrrow,0,6) .  "<th rowspan=2>hyp-ref</th>" . substr($hrrow,6);
	my @rowpairs = ($srcrow, $tgtrow, $hyprow, $rhrow, $hrrow);
        # We can display all three pairs of rows in one table or we can display them in separate tables.
        my $onetable = 1;
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
        $html .= $htmlerr;
        $html .= "</div>\n";
    }
    $html .= "  <script src='../activatables.js' type='text/javascript'></script>\n";
    $html .= "  <script type='text/javascript'>\n";
    $html .= "    activatables('page', [".join(', ', map {"'$_'"} (@{$sentence->{sub}}))."]);\n";
    $html .= "  </script>\n";
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
