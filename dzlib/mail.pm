#!/usr/bin/perl
# Modul pro odeslání mailu (např. při zpracování skriptu CGI).
# (c) 2007 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

package mail;
use utf8;
use ascii;
use Encode;
use MIME::QuotedPrint;



#------------------------------------------------------------------------------
# Převezme adresáty a text mailu a odešle je prostřednictvím externího
# unixového programu sendmail.
#------------------------------------------------------------------------------
sub odeslat
{
    # Očekávané parametry: From, Reply-to, To, Cc, Bcc, Subject, text, debug
    # Nepovinně: Content-Transfer-Encoding (default: "quoted-printable"; lze přepnout na: "8bit")
    my %m = @_;
    # Při ladění lze mail vypsat ne do sendmailu, ale na standardní výstup.
    my $sendmail;
    if($m{debug})
    {
        *SENDMAIL = *STDOUT;
    }
    else
    {
        if(-e "/usr/lib/sendmail")
        {
            $sendmail = "|/usr/lib/sendmail -oi -t";
        }
        else
        {
            die("Nemůžu najít /usr/lib/sendmail.\n");
        }
        open(SENDMAIL, $sendmail) or die("Nemůžu najít sendmail: $!\n");
    }
    binmode(SENDMAIL, ":utf8");
    # Adresa odesílatele.
    foreach my $pole ("From", "Reply-to", "To", "Cc", "Bcc", "Subject")
    {
        if(exists($m{$pole}) && $m{$pole} ne '')
        {
            my $ascii = ascii::ascii($m{$pole});
            print SENDMAIL ("$pole: $ascii\n");
        }
    }
    my $osmibit = $m{'Content-Transfer-Encoding'} eq '8bit';
    print SENDMAIL ("Content-Type: text/plain; charset=\"utf-8\"\n");
    if($osmibit)
    {
        print SENDMAIL ("Content-Transfer-Encoding: 8bit\n");
        print SENDMAIL ("\n");
        print SENDMAIL ($m{text});
    }
    else
    {
        print SENDMAIL ("Content-Transfer-Encoding: quoted-printable\n");
        print SENDMAIL ("\n");
        # Před předáním kodéru MIME zrušit příznak UTF-8.
        my $encoded = encode_qp(encode("utf8", $m{text}));
        print SENDMAIL ($encoded);
    }
    # Pokud jsme si SENDMAIL nahradili STDOUTem, nechceme ho teď zavřít!
    unless($m{debug})
    {
        close(SENDMAIL);
    }
}



1;
