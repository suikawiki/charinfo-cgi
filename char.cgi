#!/usr/bin/perl
use strict;
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib')->stringify;
use Message::CGI::HTTP;
use Message::CGI::Util qw(htescape percent_encode percent_decode);
use CGI::Carp qw(fatalsToBrowser);
use Encode;

binmode STDOUT, ':encoding(utf-8)';

my $cgi = Message::CGI::HTTP->new;

my $string = decode 'utf8', $cgi->get_parameter ('s');

print "Content-Type: text/html; charset=utf-8\n\n";
print "<!DOCTYPE HTML><html lang=en>";
print qq{
<title>Charinfo &mdash; "@{[htescape $string]}"</title>
<style>
  h1, h2 {
    padding: 0.3em;
    font-size: 100%;
    color: white;
    background-color: #5279e7;
  }
  h1 {
    background-color: #1841ce;
  }

  th {
    text-align: left;
  }
  th, td {
    padding-right: 0.5em;
  }
  th:first-child, td:first-child {
    padding-left: 0.5em;
  }
  .category th {
    padding: 0.3em;
    background-color: #C0C0C0;
  }
  input[type=text] {
    width: 80%;
  }
  .pattern-1 { background-color: #ffdddd }
  .pattern-2 { background-color: #ffffdd }
  .pattern-3 { background-color: #ddffdd }
  .pattern-4 { background-color: #dde5ff }
  .pattern-5 { background-color: #ffcccc }
  .pattern-6 { background-color: #cc99cc }
  .error {
    color: red;
  }
</style>

<h1>Character data</h1>

<form>
  <label>String:
    <input type=text name=s value="@{[htescape $string]}">
  </label>
  <input type=submit>
</form>

};

my $SELF_URL = 'char';

my $color_indexes = {};

sub print_string ($) {
  my $string = shift;
  if (not defined $string) {
    print "<td colspan=2>(undef)";
    return;
  } elsif ($string eq '') {
    print "<td colspan=2>(empty)";
    return;
  }
  my $ci = $color_indexes->{$string} ||= 1 + keys %$color_indexes;
  printf '<td class=pattern-%d><a href="%s?s=%s">%s</a>',
      $ci,
      (htescape $SELF_URL),
      (percent_encode $string),
      $string;
  printf '<td class=pattern-%d>', $ci;
  for my $c (split //, $string) {
    printf 'U+%04X', ord $c;
    printf ' (%s) ', htescape $c;
  }
} # print_string

sub print_ascii_string ($) {
  my $string = shift;
  if (not defined $string) {
    print "<td colspan=2>(undef)";
    return;
  } elsif ($string eq '') {
    print "<td colspan=2>(empty)";
    return;
  }
  my $ci = $color_indexes->{$string} ||= 1 + keys %$color_indexes;
  printf '<td colspan=2 class=pattern-%d><a href="%s?s=%s">%s</a>',
      $ci,
      (htescape $SELF_URL),
      (percent_encode $string),
      $string;
} # print_ascii_string

sub or_print_error (&) {
  my $code = shift;
  my $s = eval { $code->() };
  if ($@) {
    my $v = $@;
    $v =~ s/ at (?:\Q$0\E|\(eval \d+\)|\S+) line \d+(?:, <[^<>]+> line \d+)?\.?$//;
    print q{<td colspan=2 class=error>}, htescape $v;
  }
} # or_print_error

print q{<h2 id=chardata>Characters</h2>

<table>
};

my @char = split //, $string;

{
  print q{<tr><th>Character};
  print q{<td>}, htescape $_ for @char;
}

{
  print q{<tr><th>Code point};
  printf q{<td>U+%04X}, ord $_ for @char;
}

use Unicode::UCD 'charinfo';
my @charinfo = map { charinfo ord $_ or {} } @char;
{
  print q{<tr><th>bidi (Unicode::UCD)};
  print q{<td>}, htescape $_->{bidi} for @charinfo;
}

use Char::Prop::Unicode::BidiClass;
{
  print q{<tr><th>Bidi_Class (DerivedBidiClass.txt)};
  print q{<td>}, htescape (unicode_bidi_class_c $_) for @char;
}
use Char::Prop::Unicode::5_1_0::BidiClass;
{
  print q{<tr><th>Bidi_Class (DerivedBidiClass-5.1.0.txt)};
  print q{<td>}, htescape (unicode_5_1_0_bidi_class_c $_) for @char;
}

use Char::Prop::Unicode::Age;
{
  print q{<tr><th>Age (DerivedAge.txt)};
  print q{<td>}, htescape (unicode_age_c $_) for @char;
}

print q{</table>
<h2 id=strdata>String</h2>
<table>};

{
  print q{<tr><th>Input};
  print_string $string;
}

use AnyEvent::Util;
{
  package AnyEvent::Util;
  require 'AnyEvent/Util/uts46data.pl';
  $INC{'lib/AnyEvent/Util/uts46data.pl'} = 1;
}

print q{<tbody><tr class=category><th colspan=3>Normalization forms};

use Unicode::Normalize;
use Net::LibIDN;

{
  print q{<tr><th>NFC (<code>Unicode::Normalize</code>)};
  print_string NFC $string;
}
{
  print q{<tr><th>NFKC (<code>Unicode::Normalize</code>)};
  print_string NFKC $string;
}
{
  print q{<tr><th>NFD (<code>Unicode::Normalize</code>)};
  or_print_error {
    print_string NFD $string;
  };
}
{
  print q{<tr><th>NFKD (<code>Unicode::Normalize</code>)};
  or_print_error {
    print_string NFKD $string;
  };
}
{
  print q{<tr><th>NFKD (UN) uc (Perl) lc (Perl) NFC (UN)};
  or_print_error {
    my $s = NFKD $string;
    $s = lc uc $s;
    print_string NFC $s;
  };
}

print q{<tbody><tr class=category><th colspan=3>Stringprep};

use Net::IDN::Nameprep;
{
  printf q{<tr><th>Nameprep AllowUnassigned (<code>Net::IDN::Nameprep</code> %s)},
      htescape $Net::IDN::Nameprep::VERSION;
  or_print_error {
    print_string Net::IDN::Nameprep::nameprep $string, AllowUnassigned => 1;
  };
}
{
  printf q{<tr><th>Nameprep (<code>Net::IDN::Nameprep</code> %s)},
      htescape $Net::IDN::Nameprep::VERSION;
  or_print_error {
    print_string Net::IDN::Nameprep::nameprep $string, AllowUnassigned => 0;
  };
}

{
  printf q{<tr><th>Nameprep (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_print_error {
    print_string decode 'utf-8', Net::LibIDN::idn_prep_name $string, 'utf-8';
  };
}

print q{<tbody><tr class=category><th colspan=3>Punycode decoding};

use Net::IDN::Punycode;
{
  printf q{<tr><th>de-Punycode (<code>Net::IDN::Punycode</code> %s)},
      htescape $Net::IDN::Punycode::VERSION;
  or_print_error {
    print_string Net::IDN::Punycode::decode_punycode $string;
  };
}

use Net::IDN::Punycode::PP;
{
  printf q{<tr><th>de-Punycode (<code>Net::IDN::Punycode::PP</code> %s)},
      htescape $Net::IDN::Punycode::PP::VERSION;
  or_print_error {
    print_string Net::IDN::Punycode::PP::decode_punycode $string;
  };
}

use IDNA::Punycode;
IDNA::Punycode::idn_prefix (undef);
{
  printf q{<tr><th>de-Punycode (<code>IDNA::Punycode</code> %s)},
      htescape $IDNA::Punycode::VERSION;
  or_print_error {
    print_string IDNA::Punycode::decode_punycode $string;
  };
}

{
  printf q{<tr><th>de-Punycode (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_print_error {
    print_string decode 'utf-8', Net::LibIDN::idn_punycode_decode $string, 'utf-8';
  };
}

use Mojo::Util;
{
  print q{<tr><th>de-Punycode (<code>Mojo::Util</code>)};
  or_print_error {
    my $s = $string;
    Mojo::Util::punycode_decode $s;
    print_string $s;
  };
}

use URI::_punycode;
{
  printf q{<tr><th>de-Punycode (<code>URI::_punycode</code> %s)},
      htescape $URI::_punycode::VERSION;
  or_print_error {
    print_string URI::_punycode::decode_punycode $string;
  };
}

{
  printf q{<tr><th>de-Punycode (<code>AnyEvent::Util</code> %s)},
      htescape $AnyEvent::Util::VERSION;
  or_print_error {
    print_string AnyEvent::Util::punycode_decode $string;
  };
}

use URI::UTF8::Punycode;
{
  printf q{<tr><th>de-Punycode (<code>URI::UTF8::Punycode</code> %s)},
      htescape $URI::UTF8::Punycode::VERSION;
  or_print_error {
    print_string decode 'utf-8', URI::UTF8::Punycode::puny_dec $string;
  };
}

{
  printf q{<tr><th>Nameprep variant (<code>AnyEvent::Util</code> %s)},
      htescape $AnyEvent::Util::VERSION;
  or_print_error {
    print_string AnyEvent::Util::idn_nameprep $string;
  };
}
{
  printf q{<tr><th>Nameprep variant for display (<code>AnyEvent::Util</code> %s)},
      htescape $AnyEvent::Util::VERSION;
  or_print_error {
    print_string AnyEvent::Util::idn_nameprep $string, 1;
  };
}

{
  printf q{<tr><th>ToUnicode (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_print_error {
    print_string decode 'utf-8', Net::LibIDN::idn_to_unicode $string, 'utf-8';
  };
}
{
  printf q{<tr><th>ToUnicode AllowUnassigned (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_print_error {
    print_string decode 'utf-8', Net::LibIDN::idn_to_unicode $string, 'utf-8', Net::LibIDN::IDNA_ALLOW_UNASSIGNED;
  };
}
{
  printf q{<tr><th>ToUnicode variant (<code>AnyEvent::Util</code> %s)},
      htescape $AnyEvent::Util::VERSION;
  or_print_error {
    print_string AnyEvent::Util::idn_to_unicode $string;
  };
}

print q{<tbody><tr class=category><th colspan=3>Punycode encoding};

{
  printf q{<tr><th>en-Punycode (<code>Net::IDN::Punycode</code> %s)},
      htescape $Net::IDN::Punycode::VERSION;
  or_print_error {
    print_ascii_string Net::IDN::Punycode::encode_punycode $string;
  };
}
{
  printf q{<tr><th>en-Punycode (<code>Net::IDN::Punycode::PP</code> %s)},
      htescape $Net::IDN::Punycode::PP::VERSION;
  or_print_error {
    print_ascii_string Net::IDN::Punycode::PP::encode_punycode $string;
  };
}
{
  printf q{<tr><th>en-Punycode (<code>IDNA::Punycode</code> %s)},
      htescape $IDNA::Punycode::VERSION;
  or_print_error {
    print_ascii_string IDNA::Punycode::encode_punycode $string;
  };
}
{
  printf q{<tr><th>en-Punycode (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_print_error {
    print_ascii_string Net::LibIDN::idn_punycode_encode $string, 'utf-8';
  };
}
{
  print q{<tr><th>en-Punycode (<code>Mojo::Util</code>)};
  or_print_error {
    my $s = $string;
    Mojo::Util::punycode_encode $s;
    print_ascii_string $s;
  };
}
{
  printf q{<tr><th>en-Punycode (<code>URI::_punycode</code> %s)},
      htescape $URI::_punycode::VERSION;
  or_print_error {
    print_ascii_string URI::_punycode::encode_punycode $string;
  };
}
{
  printf q{<tr><th>en-Punycode (<code>AnyEvent::Util</code> %s)},
      htescape $AnyEvent::Util::VERSION;
  or_print_error {
    print_ascii_string AnyEvent::Util::punycode_encode $string;
  };
}
{
  printf q{<tr><th>en-Punycode (<code>URI::UTF8::Punycode</code> %s)},
      htescape $URI::UTF8::Punycode::VERSION;
  or_print_error {
    print_ascii_string URI::UTF8::Punycode::puny_enc $string;
  };
}
{
  printf q{<tr><th>ToASCII (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_print_error {
    print_ascii_string decode 'utf-8', Net::LibIDN::idn_to_ascii $string, 'utf-8';
  };
}
{
  printf q{<tr><th>ToASCII AllowUnassigned (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_print_error {
    print_ascii_string decode 'utf-8', Net::LibIDN::idn_to_ascii $string, 'utf-8', Net::LibIDN::IDNA_ALLOW_UNASSIGNED;
  };
}
{
  printf q{<tr><th>ToASCII variant (<code>AnyEvent::Util</code> %s)},
      htescape $AnyEvent::Util::VERSION;
  or_print_error {
    print_ascii_string AnyEvent::Util::idn_to_ascii $string;
  };
}

print q{<tbody><tr class=category><th colspan=3>Escapes};

{
  print q{<tr><th>percent-decode de-UTF-8};
  or_print_error {
    print_string percent_decode encode 'utf-8', $string;
  };
}
{
  print q{<tr><th>en-UTF-8 percent-encode};
  or_print_error {
    print_ascii_string percent_encode encode 'utf-8', $string;
  };
}

{
  print q{<tr><th>de-\u};
  or_print_error {
    my $s = $string;
    $s =~ s{\\u([0-9A-Fa-f]{4})|\\U([0-9A-Fa-f]{8})}{
      chr hex ($1 || $2 || 0);
    }ge;
    print_string $s;
  };
}
{
  print q{<tr><th>en-\u};
  or_print_error {
    print_ascii_string join '', map { sprintf (($_ <= 0xFFFF ? '\\u%04X' : '\\U%08X'), $_) } map { ord $_ } split //, $string;
  };
}
{
  print q{<tr><th>en-\u non-ASCII};
  or_print_error {
    print_ascii_string join '', map { 0x20 <= $_ && $_ <= 0x7E && $_ != 0x5C ? chr $_ : sprintf (($_ <= 0xFFFF ? '\\u%04X' : '\\U%08X'), $_) } map { ord $_ } split //, $string;
  };
}
{
  print q{<tr><th>de-surrogate};
  or_print_error {
    print_string decode 'utf-16-be', join '', map { $_ > 0x10FFFF ? "\xFF\xFD" : $_ >= 0x10000 ? encode 'utf-16-be', chr $_ : pack 'CC', $_ / 0x100, $_ % 0x100 } map { ord $_ } split //, $string;
  };
}

print "</table>";

my $commit = `git rev-parse HEAD`;
$commit =~ s/[^0-9A-Za-z]+//g;

print qq{

<h2 id=about>About charinfo</h2>

<p>This is Charinfo version <a
href="https://github.com/wakaba/charinfo-cgi/commit/$commit">$commit</a>.

<p>Git repository: <a
href="http://suika.fam.cx/gate/git/wi/char/charinfo.git/tree">Suika</a>
/ <a href="https://github.com/wakaba/charinfo-cgi">GitHub</a>

};

__END__

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Copyright 2011 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
