package Charinfo::Main;
use strict;
use warnings;
no warnings 'utf8';
use Encode;
use URL::PercentEncode qw(percent_encode_c percent_decode_c
                          percent_encode_b percent_decode_b);

sub htescape ($) {
  my $s = shift;
  $s =~ s/&/&amp;/g;
  $s =~ s/</&lt;/g;
  $s =~ s/"/&quot;/g;
  return $s;
} # htescape

our $Output = sub { die "|\$Output| not defined" };
our $SELF_URL = 'char';

sub ucode ($) {
  if ($_[0] > 0x10FFFF) {
    return sprintf '<a href="/char/%08X">U-%08X</a>', $_[0], $_[0];
  } else {
    return sprintf '<a href="/char/%04X">U+%04X</a>', $_[0], $_[0];
  }
} # ucode

sub p (@) {
  $Output->(@_);
} # p

sub pf ($@) {
  my $format = shift;
  $Output->(sprintf $format, @_);
} # pf

my $color_indexes = {};

sub p_string ($) {
  my $string = shift;
  if (not defined $string) {
    p "<td colspan=2>(undef)";
    return;
  } elsif ($string eq '') {
    p "<td colspan=2>(empty)";
    return;
  }
  my $ci = $color_indexes->{$string} ||= 1 + keys %$color_indexes;
  pf '<td class=pattern-%d><a href="%s?s=%s">%s</a>',
      $ci,
      (htescape $SELF_URL),
      (percent_encode_c $string),
      $string;
  pf '<td class=pattern-%d>', $ci;
  for my $c (split //, $string) {
    p ucode ord $c;
    pf ' (%s) ', htescape $c;
  }
} # p_string

sub p_ascii_string ($) {
  my $string = shift;
  if (not defined $string) {
    p "<td colspan=2>(undef)";
    return;
  } elsif ($string eq '') {
    p "<td colspan=2>(empty)";
    return;
  }
  my $ci = $color_indexes->{$string} ||= 1 + keys %$color_indexes;
  pf '<td colspan=2 class=pattern-%d><a href="%s?s=%s">%s</a>',
      $ci,
      (htescape $SELF_URL),
      (percent_encode_c $string),
      $string;
} # p_ascii_string

sub or_p_error (&) {
  my $code = shift;
  eval { $code->(); 1 } or do {
    my $v = $@;
    $v =~ s/ at (?:\Q$0\E|\(eval \d+\)|\S+) line \d+(?:, <[^<>]+> line \d+)?\.?$//;
    p q{<td colspan=2 class=error>}, htescape $v;
  };
} # or_p_error

sub main ($$) {
  my (undef, $string) = @_;
  $color_indexes = {};

p "<!DOCTYPE HTML><html lang=en>";
p qq{
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

  .target-char {
    font-size: 400%;
  }

  .charname {
    text-transform: lowercase;
    font-variant: small-caps;
  }

  aside.ads {
    display: none;
  }

  \@media screen and (min-width: 600px) {
    section#char {
      position: relative;
      padding-right: 300px;
      min-height: 250px;
    }

    section.ads {
      display: block;
      position: absolute;
      right: 0;
      top: 0;
    }
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

my @char = split //, $string;

if (@char == 1) {
  p q{<section id=char><h2>Character</h2><table>};

  pf q{<tr><th>Character<td><code class=target-char>%s</code>},
      $char[0];

  pf q{<tr><th>Code point
       <td><code>%s</code>
           <code>%d</code><sub>10</sub>
           <code>%o</code><sub>8</sub>},
      ucode ord $char[0], ord $char[0], ord $char[0];

  require Unicode::CharName;
  pf q{<tr><th>Character name<td><code class=charname>%s</code>},
      Unicode::CharName::uname (ord $char[0]) // '(unassigned)';
  pf q{<tr><th>Block<td>%s},
      Unicode::CharName::ublock (ord $char[0]) // '(unassigned)';

  pf q{<tr><th>Previous<td>%s (%s)},
      ucode (-1 + ord $char[0]), chr (-1 + ord $char[0]);
  pf q{<tr><th>Next<td>%s (%s)},
      ucode (1 + ord $char[0]), chr (1 + ord $char[0]);

  p q{</table>

      <aside class=ads>
        <script>
          google_ad_client = "ca-pub-6943204637055835";
          google_ad_slot = "1478788718";
          google_ad_width = 300;
          google_ad_height = 250;
        </script>
        <script src="http://pagead2.googlesyndication.com/pagead/show_ads.js"></script>
      </aside>
    </section>
  };
}

p q{<h2 id=chardata>Characters</h2>

<table>
};

{
  p q{<tr><th>Character};
  p q{<td>}, htescape $_ for @char;
}

{
  p q{<tr><th>Code point};
  pf q{<td>%s}, ucode ord $_ for @char;
}

use Unicode::UCD 'charinfo';
my @charinfo = map { charinfo ord $_ or {} } @char;
{
  p q{<tr><th>bidi (Unicode::UCD)};
  p q{<td>}, htescape $_->{bidi} for @charinfo;
}

use Char::Prop::Unicode::BidiClass;
{
  p q{<tr><th>Bidi_Class (DerivedBidiClass.txt)};
  p q{<td>}, htescape (unicode_bidi_class_c $_) for @char;
}
use Char::Prop::Unicode::5_1_0::BidiClass;
{
  p q{<tr><th>Bidi_Class (DerivedBidiClass-5.1.0.txt)};
  p q{<td>}, htescape (unicode_5_1_0_bidi_class_c $_) for @char;
}

use Char::Prop::Unicode::Age;
{
  p q{<tr><th>Age (DerivedAge.txt)};
  p q{<td>}, htescape (unicode_age_c $_) for @char;
}

p q{</table>
<h2 id=strdata>String</h2>
<table>};

{
  p q{<tr><th>Input};
  p_string $string;
}

use AnyEvent::Util;
{
  package AnyEvent::Util;
  require 'AnyEvent/Util/uts46data.pl';
  $INC{'lib/AnyEvent/Util/uts46data.pl'} = 1;
}

p q{<tbody><tr class=category><th colspan=3>Normalization forms};

use Unicode::Normalize;
use Net::LibIDN;

{
  p q{<tr><th>NFC (<code>Unicode::Normalize</code>)};
  p_string NFC $string;
}
{
  p q{<tr><th>NFKC (<code>Unicode::Normalize</code>)};
  p_string NFKC $string;
}
{
  p q{<tr><th>NFD (<code>Unicode::Normalize</code>)};
  or_p_error {
    p_string NFD $string;
  };
}
{
  p q{<tr><th>NFKD (<code>Unicode::Normalize</code>)};
  or_p_error {
    p_string NFKD $string;
  };
}
{
  p q{<tr><th>NFKD (UN) uc (Perl) lc (Perl) NFC (UN)};
  or_p_error {
    my $s = NFKD $string;
    $s = lc uc $s;
    p_string NFC $s;
  };
}

p q{<tbody><tr class=category><th colspan=3>Stringprep};

use Net::IDN::Nameprep;
{
  pf q{<tr><th>Nameprep AllowUnassigned (<code>Net::IDN::Nameprep</code> %s)},
      htescape $Net::IDN::Nameprep::VERSION;
  or_p_error {
    p_string Net::IDN::Nameprep::nameprep $string, AllowUnassigned => 1;
  };
}
{
  pf q{<tr><th>Nameprep (<code>Net::IDN::Nameprep</code> %s)},
      htescape $Net::IDN::Nameprep::VERSION;
  or_p_error {
    p_string Net::IDN::Nameprep::nameprep $string, AllowUnassigned => 0;
  };
}

{
  pf q{<tr><th>Nameprep (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_p_error {
    p_string decode 'utf-8', Net::LibIDN::idn_prep_name $string, 'utf-8';
  };
}

p q{<tbody><tr class=category><th colspan=3>Punycode decoding};

use Net::IDN::Punycode;
{
  pf q{<tr><th>de-Punycode (<code>Net::IDN::Punycode</code> %s)},
      htescape $Net::IDN::Punycode::VERSION;
  or_p_error {
    p_string Net::IDN::Punycode::decode_punycode $string;
  };
}

use Net::IDN::Punycode::PP;
{
  pf q{<tr><th>de-Punycode (<code>Net::IDN::Punycode::PP</code> %s)},
      htescape $Net::IDN::Punycode::PP::VERSION;
  or_p_error {
    p_string Net::IDN::Punycode::PP::decode_punycode $string;
  };
}

use IDNA::Punycode;
IDNA::Punycode::idn_prefix (undef);
{
  pf q{<tr><th>de-Punycode (<code>IDNA::Punycode</code> %s)},
      htescape $IDNA::Punycode::VERSION;
  or_p_error {
    p_string IDNA::Punycode::decode_punycode $string;
  };
}

{
  pf q{<tr><th>de-Punycode (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_p_error {
    p_string decode 'utf-8', Net::LibIDN::idn_punycode_decode $string, 'utf-8';
  };
}

use Mojo::Util;
{
  p q{<tr><th>de-Punycode (<code>Mojo::Util</code>)};
  or_p_error {
    my $s = $string;
    Mojo::Util::punycode_decode $s;
    p_string $s;
  };
}

use URI::_punycode;
{
  pf q{<tr><th>de-Punycode (<code>URI::_punycode</code> %s)},
      htescape $URI::_punycode::VERSION;
  or_p_error {
    p_string URI::_punycode::decode_punycode $string;
  };
}

{
  pf q{<tr><th>de-Punycode (<code>AnyEvent::Util</code> %s)},
      htescape $AnyEvent::Util::VERSION;
  or_p_error {
    p_string AnyEvent::Util::punycode_decode $string;
  };
}

use URI::UTF8::Punycode;
{
  pf q{<tr><th>de-Punycode (<code>URI::UTF8::Punycode</code> %s)},
      htescape $URI::UTF8::Punycode::VERSION;
  or_p_error {
    p_string decode 'utf-8', URI::UTF8::Punycode::puny_dec $string;
  };
}

{
  pf q{<tr><th>Nameprep variant (<code>AnyEvent::Util</code> %s)},
      htescape $AnyEvent::Util::VERSION;
  or_p_error {
    p_string AnyEvent::Util::idn_nameprep $string;
  };
}
{
  pf q{<tr><th>Nameprep variant for display (<code>AnyEvent::Util</code> %s)},
      htescape $AnyEvent::Util::VERSION;
  or_p_error {
    p_string AnyEvent::Util::idn_nameprep $string, 1;
  };
}

{
  pf q{<tr><th>ToUnicode (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_p_error {
    p_string decode 'utf-8', Net::LibIDN::idn_to_unicode $string, 'utf-8';
  };
}
{
  pf q{<tr><th>ToUnicode AllowUnassigned (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_p_error {
    p_string decode 'utf-8', Net::LibIDN::idn_to_unicode $string, 'utf-8', Net::LibIDN::IDNA_ALLOW_UNASSIGNED;
  };
}
{
  pf q{<tr><th>ToUnicode variant (<code>AnyEvent::Util</code> %s)},
      htescape $AnyEvent::Util::VERSION;
  or_p_error {
    p_string AnyEvent::Util::idn_to_unicode $string;
  };
}

p q{<tbody><tr class=category><th colspan=3>Punycode encoding};

{
  pf q{<tr><th>en-Punycode (<code>Net::IDN::Punycode</code> %s)},
      htescape $Net::IDN::Punycode::VERSION;
  or_p_error {
    p_ascii_string Net::IDN::Punycode::encode_punycode $string;
  };
}
{
  pf q{<tr><th>en-Punycode (<code>Net::IDN::Punycode::PP</code> %s)},
      htescape $Net::IDN::Punycode::PP::VERSION;
  or_p_error {
    p_ascii_string Net::IDN::Punycode::PP::encode_punycode $string;
  };
}
{
  pf q{<tr><th>en-Punycode (<code>IDNA::Punycode</code> %s)},
      htescape $IDNA::Punycode::VERSION;
  or_p_error {
    p_ascii_string IDNA::Punycode::encode_punycode $string;
  };
}
{
  pf q{<tr><th>en-Punycode (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_p_error {
    p_ascii_string Net::LibIDN::idn_punycode_encode $string, 'utf-8';
  };
}
{
  p q{<tr><th>en-Punycode (<code>Mojo::Util</code>)};
  or_p_error {
    my $s = $string;
    Mojo::Util::punycode_encode $s;
    p_ascii_string $s;
  };
}
{
  pf q{<tr><th>en-Punycode (<code>URI::_punycode</code> %s)},
      htescape $URI::_punycode::VERSION;
  or_p_error {
    p_ascii_string URI::_punycode::encode_punycode $string;
  };
}
{
  pf q{<tr><th>en-Punycode (<code>AnyEvent::Util</code> %s)},
      htescape $AnyEvent::Util::VERSION;
  or_p_error {
    p_ascii_string AnyEvent::Util::punycode_encode $string;
  };
}
{
  pf q{<tr><th>en-Punycode (<code>URI::UTF8::Punycode</code> %s)},
      htescape $URI::UTF8::Punycode::VERSION;
  or_p_error {
    p_ascii_string URI::UTF8::Punycode::puny_enc $string;
  };
}
{
  pf q{<tr><th>ToASCII (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_p_error {
    p_ascii_string decode 'utf-8', Net::LibIDN::idn_to_ascii $string, 'utf-8';
  };
}
{
  pf q{<tr><th>ToASCII AllowUnassigned (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_p_error {
    p_ascii_string decode 'utf-8', Net::LibIDN::idn_to_ascii $string, 'utf-8', Net::LibIDN::IDNA_ALLOW_UNASSIGNED;
  };
}
{
  pf q{<tr><th>ToASCII variant (<code>AnyEvent::Util</code> %s)},
      htescape $AnyEvent::Util::VERSION;
  or_p_error {
    p_ascii_string AnyEvent::Util::idn_to_ascii $string;
  };
}

p q{<tbody><tr class=category><th colspan=3>Escapes};

{
  p q{<tr><th>percent-decode de-UTF-8};
  or_p_error {
    p_string percent_decode_b encode 'utf-8', $string;
  };
}
{
  p q{<tr><th>en-UTF-8 percent-encode};
  or_p_error {
    p_ascii_string percent_encode_b encode 'utf-8', $string;
  };
}

{
  p q{<tr><th>de-\u};
  or_p_error {
    my $s = $string;
    $s =~ s{\\u([0-9A-Fa-f]{4})|\\U([0-9A-Fa-f]{8})}{
      chr hex ($1 || $2 || 0);
    }ge;
    p_string $s;
  };
}
{
  p q{<tr><th>en-\u};
  or_p_error {
    p_ascii_string join '', map { sprintf (($_ <= 0xFFFF ? '\\u%04X' : '\\U%08X'), $_) } map { ord $_ } split //, $string;
  };
}
{
  p q{<tr><th>en-\u non-ASCII};
  or_p_error {
    p_ascii_string join '', map { 0x20 <= $_ && $_ <= 0x7E && $_ != 0x5C ? chr $_ : sprintf (($_ <= 0xFFFF ? '\\u%04X' : '\\U%08X'), $_) } map { ord $_ } split //, $string;
  };
}
{
  p q{<tr><th>de-surrogate};
  or_p_error {
    p_string decode 'utf-16-be', join '', map { $_ > 0x10FFFF ? "\xFF\xFD" : $_ >= 0x10000 ? encode 'utf-16-be', chr $_ : pack 'CC', $_ / 0x100, $_ % 0x100 } map { ord $_ } split //, $string;
  };
}

p "</table>";

my $commit = `git rev-parse HEAD`;
$commit =~ s/[^0-9A-Za-z]+//g;

p qq{

<h2 id=about>About charinfo</h2>

<p>This is Charinfo version <a
href="https://github.com/wakaba/charinfo-cgi/commit/$commit">$commit</a>.

<p>Git repository: <a
href="http://suika.suikawiki.org/gate/git/wi/char/charinfo.git/tree">Suika</a>
/ <a href="https://github.com/wakaba/charinfo-cgi">GitHub</a>

};

} # main

1;

__END__

=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 LICENSE

Copyright 2011-2013 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
