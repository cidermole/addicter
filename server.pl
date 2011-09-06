#!/usr/bin/perl
# Simple web server to serve Addicter's output.
# Copyright © 2011 Dan Zeman <zeman@ufal.mff.cuni.cz>
# (well, it's heavily based on documentation of HTTP::Daemon)
# License: GNU GPL

use utf8;
use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

use HTTP::Daemon;
use HTTP::Status;
use HTTP::Response;
use Encode;

if($ARGV[0] =~ m/^\d+$/)
{
    $d = HTTP::Daemon->new(LocalPort => $ARGV[0]) || die;
}
else
{
    $d = HTTP::Daemon->new || die;
}
print("Please contact me at: <URL:", $d->url, "cgi/index.pl>\n");
while (my $c = $d->accept)
{
    while (my $r = $c->get_request)
    {
        if ($r->method() eq 'GET' and $r->url()->as_string() =~ m-^/cgi/(.*\.pl)(?:\?(.*))$-)
        {
            my $script = $1;
            my $params = $2;
            $ENV{QUERY_STRING} = $params;
            my $r = HTTP::Response->new(RC_OK);
            $r->push_header('Content-type' => 'text/html; charset=utf8');
            chdir('cgi');
            print STDERR (`cd`);
            print STDERR ("$script\n");
            print STDERR ("$ENV{QUERY_STRING}\n");
            my $cgiout = `perl $script`;
            # $cgiout starts with the header so get rid of it.
            $cgiout =~ s/^.*\r?\n\r?\n//s;
            $r->add_content(encode('utf8', $cgiout));
            $c->send_response($r);
        }
        else
        {
            $c->send_error(RC_FORBIDDEN);
        }
    }
    $c->close;
    undef($c);
}
