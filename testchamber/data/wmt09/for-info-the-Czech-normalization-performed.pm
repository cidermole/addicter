package Normalize_plaintext::Czech;
# Written by Ondrej Bojar
# Reduce Czech plaintext data sparseness

use 5.008;
use strict;
use warnings;
use utf8; # this file is in utf8

use base qw(TectoMT::Block);


sub process_bundle {
    my ( $self, $bundle ) = @_;
    my $s = $bundle->get_attr('czech_source_sentence');

    $s = fix_tokenized_Czech_decimal_numbers($s);
    $s = fix_Czech_quotation_pairs($s);

    # whitespace
    $s =~ s/\x{00A0}/ /g;  # nbsp
    $s =~ s/&nbsp;/ /gi;  # nbsp
    $s =~ s/\s+/ /g;
    # quotation marks
    #$s =~ s/,,/"/g;
    #$s =~ s/``/"/g;
    #$s =~ s/''/"/g;
    #$s =~ s/[“”„‟«»]/"/g;
    # single quotation marks
    #$s =~ s/[´`'‘’‚‛]/'/g;
    $s =~ s/[´`’‛]/'/g; # these are not valid Czech ‚...‘

    # dashes
    $s =~ s/[-–­֊᠆‐‑‒–—―⁃⸗﹣－⊞⑈︱︲﹘]+/-/g;
    # dots
    $s =~ s/…/.../g;

    $bundle->set_attr('czech_source_sentence', $s);
}

sub fix_tokenized_Czech_decimal_numbers {
  # try to improve malformed input
  $_ = shift;
  # print STDERR "BEF $_\n";
  return $_ if /[0-9],[0-9]/;
    # evidence that this sentence is correct

  if (/[0-9] *, +[0-9]{1,3} ?(%|(mili?[óo]n[ůu]|miliardy?|%|let[áýé]|µg|l|měsíc(e|ících|ů)|ml|mg|dolar[ůy]|dolarech|americk(ých|ým|é)|ti|let|mmol|mikrogram(ům|y|ech)|kg|ng|násob(ek|ku|ky)|fraktur|rok[ůyu])\b)/
    || /\b(o|na) [0-9]{1,3} *, +[0-9]{1,3}/
    || /\b(od|z) [0-9]{1,3} *, +[0-9]{1,3} (do|na)\b/
    || /\D +\d{1,3} *, \d{1,3} (a|až|-+) [0-9]{1,3} *, +[0-9]{1,3} /
    || /index.*klesl/ || /richterov.*škál/i) {
    # this is wrong
    my $old;
    do {
      $old = $_;
      $_ =~ s/(([^[:digit:]] |^|[[:punct:]])[0-9]{1,3}) *, +([0-9]{1,3} ?([^[:digit:]])|$|[[:punct:]])/$1,$3/g;
    } while ($_ ne $old);
  }
  # print STDERR "AFT $_\n";
  return $_;
}

my $quo = "„“”\"";
my $apo = "‚‘’‛`'";
my $noquo = "[^$quo]";
my $noapo = "[^$apo]";
my $noquoapo = "[^$quo$apo]";
# my @single_pairs = map {[split /---/,$_]} qw( ‚---‘  );
my $doubleopenmark = "DoUbLeOpEnMaRk";
my $doubleclosemark = "DoUbLeClOsEMaRk";
my $singleopenmark = "SiNgLeOpEnMaRk";
my $singleclosemark = "SiNgLeClOsEMaRk";
sub fix_Czech_quotation_pairs {
  my $s = shift;

  $s =~ s/„($noquo*)“/$doubleopenmark$1$doubleclosemark/go;
  $s =~ s/„($noquo*)”/$doubleopenmark$1$doubleclosemark/go;
  $s =~ s/“($noquo*)”/$doubleopenmark$1$doubleclosemark/go;
  $s =~ s/„($noquo*)"/$doubleopenmark$1$doubleclosemark/go;
  $s =~ s/"($noquo*)"/$doubleopenmark$1$doubleclosemark/go;
  $s =~ s/,,($noquoapo*)"/$doubleopenmark$1$doubleclosemark/go;
  $s =~ s/,,($noquoapo*)``/$doubleopenmark$1$doubleclosemark/go;
  $s =~ s/``($noquoapo*)''/$doubleopenmark$1$doubleclosemark/go;

  $s =~ s/,,($noquo*)"/$doubleopenmark$1$doubleclosemark/go;
  $s =~ s/,,($noquo*)``/$doubleopenmark$1$doubleclosemark/go;
  $s =~ s/``($noquo*)''/$doubleopenmark$1$doubleclosemark/go;

  $s =~ s/`($noapo*)'/$singleopenmark$1$singleclosemark/go;
  $s =~ s/‚($noapo*)‘/$singleopenmark$1$singleclosemark/go;
  $s =~ s/‘($noapo*)’/$singleopenmark$1$singleclosemark/go;

  $s =~ s/"( )/$doubleclosemark$1/go;
  $s =~ s/"$/$doubleclosemark/go;
  $s =~ s/"([[:punct:]])$/$doubleclosemark$1/go;
  $s =~ s/( )"/$1$doubleopenmark/go;
  $s =~ s/^"/$doubleopenmark/go;
  $s =~ s/(\S)''/$1$doubleclosemark/go;
  $s =~ s/(\S)``/$1$doubleclosemark/go;
  $s =~ s/''(\S)/$doubleopenmark$1/go;
  $s =~ s/``(\S)/$doubleopenmark$1/go;

  $s =~ s/$doubleopenmark/„/go;
  $s =~ s/$doubleclosemark/“/go;

  $s =~ s/$singleopenmark/‚/go;
  $s =~ s/$singleclosemark/‘/go;

  return $s;
}

1;

=over

=item Normalize_plaintext::Czech

Modify czech_source_sentence in place for a better normalization.
E.g. contracted negations are expanded etc.

=back

=cut

# Copyright 2008 Ondrej Bojar

# This file is distributed under the GNU General Public License v2. See $TMT_ROOT/README.
