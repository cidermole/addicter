#!/usr/bin/perl
# Uses XML::Parser to read and parse an XML file into a tree.
# Converts the bloody array maze to a more convenient tree of hashes and arrays.
# Provides further functions to search and manipulate the tree.
# Copyright © 2009 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

package xmltree;
use utf8;
use open ":utf8";
use XML::Parser;



#------------------------------------------------------------------------------
# Reads the XML document, parses it and converts the tree structure defined by
# XML::Parser to a tree structure defined by DZ (hashes and arrays).
#------------------------------------------------------------------------------
sub read
{
    my $file = shift; # path
    my $parser = new XML::Parser(Style => 'Tree');
    my $xml_parser_tree = $parser->parsefile($file);
    my $tree = hash_tree($xml_parser_tree);
    return $tree;
}



#------------------------------------------------------------------------------
# If the XML document has already been loaded into memory, this subroutine will
# parse it and return the tree.
#------------------------------------------------------------------------------
sub parse
{
    my $xml = shift; # XML contents
    my $parser = new XML::Parser(Style => 'Tree');
    my $xml_parser_tree = $parser->parse($xml);
    my $tree = hash_tree($xml_parser_tree);
    return $tree;
}



#==============================================================================
# Parse tree manipulation functions.
# The tree is an array:
#  [0] ... name of the element
#  [1] ... contents of the element (reference to another array)
# Unfortunately, content arrays have a slightly different structure:
#  [0] ... attributes of the surrounding element and their values (reference to a hash)
#  [1] ... name of the first sub-element
#  [2] ... contents of the first sub-element (reference to an array)
#  [3] ... name of the second sub-element
#  [4] ... its contents
#  etc.
# In case of plain text instead of a sub-element:
#  [1] ... "0" (pseudo-tag)
#  [2] ... the contents (plain text, not a reference)
#==============================================================================



#------------------------------------------------------------------------------
# Converts the data of the root element into a few more hashes so that it can
# be more easily manipulated.
#------------------------------------------------------------------------------
sub get_root
{
    my $tree = shift;
    my %hash;
    # If this is a plain text, there is a phony element tag '0'.
    if($tree->[0] eq '0')
    {
        %hash =
        (
            'element' => '0',
            'text' => $tree->[1]
        );
    }
    else
    {
        # Loop over sub-elements and create an array of element-content pairs.
        my @pairs;
        for(my $i = 1; $i<$#{$tree->[1]}; $i += 2)
        {
            my @pair = ($tree->[1][$i], $tree->[1][$i+1]);
            push(@pairs, \@pair);
        }
        %hash =
        (
            'element' => $tree->[0],
            'attributes' => $tree->[1][0],
            'children' => \@pairs
        );
    }
    return \%hash;
}



#------------------------------------------------------------------------------
# Converts the tree to a structure of hashes and arrays by recursively applying
# get_root().
#------------------------------------------------------------------------------
sub hash_tree
{
    my $tree = shift;
    my $root = get_root($tree);
    if(exists($root->{children}))
    {
        my @hash_children;
        foreach my $child (@{$root->{children}})
        {
            my $hash_child = hash_tree($child);
            push(@hash_children, $hash_child);
        }
        # Replace the original list of children (XML parse trees) by the new list of hash children.
        $root->{children} = \@hash_children;
    }
    return $root;
}



#==============================================================================
# The remaining functions operate on the new tree structure (arrays and hashes)
#==============================================================================



#------------------------------------------------------------------------------
# Prints formatted XML of the tree to STDOUT. Text content goes on separate
# lines, whitespace text content is ignored.
#------------------------------------------------------------------------------
sub print_formatted_xml
{
    my $tree = shift;
    my $indent = shift; # string of spaces, not a number!
    if($tree->{element} eq '0')
    {
        # Ignore empty (whitespace) text.
        return if($tree->{text} =~ m/^\s*$/s);
        # Remove extra spaces including line breaks.
        my $text = $tree->{text};
        $text =~ s/^\s+//s;
        $text =~ s/\s+$//s;
        $text =~ s/\s+/ /sg;
        print($indent, $text, "\n");
    }
    else
    {
        print($indent, "<$tree->{element}>\n");
        foreach my $child (@{$tree->{children}})
        {
            print_formatted_xml($child, $indent.'  ');
        }
        print($indent, "</$tree->{element}>\n");
    }
}



#------------------------------------------------------------------------------
# Searches the tree depth-first for the first occurrence of a particular
# element. Returns the subtree of the element.
#------------------------------------------------------------------------------
sub find_element
{
    my $element = shift;
    my $tree = shift;
    if($tree->{element} eq $element)
    {
        return $tree;
    }
    elsif(exists($tree->{children}) && scalar(@{$tree->{children}}))
    {
        foreach my $child (@{$tree->{children}})
        {
            my $result = find_element($element, $child);
            return $result if($result);
        }
    }
    return 0;
}



#------------------------------------------------------------------------------
# Searches the tree depth-first and collects plain text. Ignores markup
# elements.
#------------------------------------------------------------------------------
sub collect_text
{
    my $tree = shift;
    if(exists($tree->{text}))
    {
        return $tree->{text};
    }
    else
    {
        my $text;
        if(exists($tree->{children}) && scalar(@{$tree->{children}}))
        {
            foreach my $child (@{$tree->{children}})
            {
                $text .= collect_text($child);
            }
        }
        return $text;
    }
}



1;
