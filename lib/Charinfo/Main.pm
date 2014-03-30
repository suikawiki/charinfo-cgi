#line 1 "Charinfo::Main"
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
      '/string',
      (percent_encode_c $string),
      $string;
  pf '<td class=pattern-%d>', $ci;
  for my $c (split //, $string) {
    p ucode ord $c;
    pf ' (%s) ', htescape $c;
  }
} # p_string

sub p_bytes ($) {
  my $string = shift;
  if (not defined $string) {
    p "<td colspan=2>(undef)";
    return;
  } elsif ($string eq '') {
    p "<td colspan=2>(empty)";
    return;
  }
  p '<td colspan=2>';
  for my $b (split //, $string) {
    pf '0x%02X ', ord $b;
  }
} # p_bytes

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
      '/string',
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
<head>
<title>Charinfo &mdash; "@{[htescape $string]}"</title>
<link rel=stylesheet href=/css>
</head>

<h1 class=site><a href="/">Chars</a>.<a href="//suikawiki.org/"><img src="//suika.suikawiki.org/~wakaba/-temp/2004/sw" alt=SuikaWiki.org></a></h1>

<h1>Charinfo &mdash; "@{[htescape $string]}"</h1>

<form action=/string>
  <label>String:
    <input type=text name=s value="@{[htescape $string]}">
  </label>
  <button type=submit>Show</button>
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
           <code>%o</code><sub>8</sub>
           <code>%08b %08b %08b %08b</code><sub>2</sub>},
      ucode ord $char[0], ord $char[0], ord $char[0],
      (ord $char[0]) >> 24, ((ord $char[0]) >> 16) & 0xFF,
      ((ord $char[0]) >> 8) & 0xFF, (ord $char[0]) & 0xFF;

  use Charinfo::Name;
  my $names = Charinfo::Name->char_code_to_names (ord $char[0]);
  pf q{<tr><th>Character name
       <td><a href="http://suika.suikawiki.org/~wakaba/wiki/sw/n/%s"><code class=charname>%s</code></a>},
      percent_encode_c ($names->{name} // $names->{label}),
      htescape ($names->{name} // $names->{label})
          if defined $names->{name} or defined $names->{label};
  my @alias;
  for (@{Charinfo::Name->alias_types}) {
    for my $name (keys %{$names->{$_}}) {
      push @alias, sprintf q{<a href="http://suika.suikawiki.org/~wakaba/wiki/sw/n/%s"><code class="charname name-alias-%s">%s</code></a>},
          percent_encode_c $name,
          htescape $_,
          htescape $name;
    }
  }
  if (@alias) {
    p q{ (};
    p join ', ', @alias;
    p q{)};
  }

  if (defined $names->{ja_name}) {
    pf q{<tr><th>Japanese name<td lang=ja>%s}, htescape $names->{ja_name};
  }

  use Unicode::CharName;
  pf q{<tr><th>Block<td>%s},
      Unicode::CharName::ublock (ord $char[0]) // '(unassigned)';

  pf q{<tr><th>Previous<td>%s (%s)},
      ucode (-1 + ord $char[0]), chr (-1 + ord $char[0]);
  pf q{<tr><th>Next<td>%s (%s)},
      ucode (1 + ord $char[0]), chr (1 + ord $char[0]);

  p q{</table>};

  pf q{<p>[<a href="http://unicode.org/cldr/utility/character.jsp?a=%04X">Unicode properties</a>]},
      ord $char[0];

  __PACKAGE__->ads;
  p q{</section>};
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

p q{<tbody><tr class=category><th colspan=3>Unicode encodings};

{
  p q{<tr><th>UTF-8};
  p_bytes encode 'utf-8', $string;
}
{
  p q{<tr><th>UTF-16BE};
  p_bytes encode 'utf-16be', $string;
}
{
  p q{<tr><th>UTF-16LE};
  p_bytes encode 'utf-16le', $string;
}
{
  p q{<tr><th>UTF-32BE};
  p_bytes encode 'utf-32be', $string;
}

if (@char == 1) {
  p q{<tbody><tr class=category><th colspan=3>Web encodings};

  use Charinfo::Encoding;
  my @not_encodable;
  for my $encoding (@$Charinfo::Encoding::EncodingNames) {
    my $encoded = Charinfo::Encoding->from_unicode (ord $char[0] => $encoding);
    if ($encoded and @$encoded) {
      p qq{<tr><th rowspan="@{[scalar @$encoded]}"><a href="http://encoding.spec.whatwg.org/#$encoding">$encoding</a>};
      my $prefix = '';
      for (@$encoded) {
        p $prefix . '<td colspan=2>' . join ' ', map { sprintf '0x%02X', $_ } @$_;
        $prefix = '<tr>';
      }
    } else {
      push @not_encodable, $encoding;
    }
  }
  if (@not_encodable) {
    p '<tr><th>Not encodable in<td colspan=2>' . join ' ', @not_encodable;
  }
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

# XXX CL/CR range
{
  p q{<tr><th>HTML/XML decimal<td colspan=2>};
  p join '', map { sprintf '&amp;#%d;', ord $_ } split //, $string;
}
{
  p q{<tr><th>HTML/XML hexadecimal<td colspan=2>};
  p join '', map { sprintf '&amp;#x%X;', ord $_ } split //, $string;
}

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

  __PACKAGE__->footer;
} # main

sub top ($) {
  p q{<!DOCTYPE html><html lang=en class=set-info>
      <meta name="google-site-verification" content="tE5pbEtqbJu0UKbNCIsW2gUzW5bWGhvCwpwynqEIBRs" />
      <title>Characters - SuikaWiki</title>};
  p q{<link rel=stylesheet href=/css>
<h1 class=site><a href="/">Chars</a>.<a href="//suikawiki.org/"><img src="//suika.suikawiki.org/~wakaba/-temp/2004/sw" alt=SuikaWiki.org></a></h1>};

  p q{<h1>Characters</h1>};

  p q{
    <div class=has-ads>
      <ul>
        <li><a href="/char/0000">Characters</a>
        <li><a href="/string">Strings</a>
        <li><a href="/set">Sets</a>
      </ul>
  };
  __PACKAGE__->ads;
  p q{
    </div>
  };
  __PACKAGE__->footer;
} # top

sub set ($$) {
  my $expr = $_[1];
  my $has_ads = not $expr =~ /\[/;

  p q{<!DOCTYPE html><html lang=en class=set-info>
      <title>Character set "} . (htescape $expr) . q{"</title>};
  p q{<link rel=stylesheet href=/css>
<h1 class=site><a href="/">Chars</a>.<a href="//suikawiki.org/"><img src="//suika.suikawiki.org/~wakaba/-temp/2004/sw" alt=SuikaWiki.org></a></h1>};

  p q{<h1>Character set</h1>};

  use Charinfo::Set;
  my $set = eval { Charinfo::Set->evaluate_expression ($expr) };
  if (not defined $set) {
    pf q{<p>Expression error: %s}, $@;
    return;
  }

  pf q{<section id=set class="%s"><h2>Set</h2><dl>},
      $has_ads ? 'has-ads' : '';

  pf q{<dt>Original expression<dd><code>%s</code>}, htescape $expr;

  pf q{<dt>Normalized<dd><code>%s</code>},
      htescape +Charinfo::Set->serialize_set ($set);

  my $count = 0;
  for my $range (@$set) {
    $count += $range->[1] - $range->[0] + 1;
  }
  pf q{<dt>Number of characters<dd>%d}, $count;

  p q{</dl>};
  __PACKAGE__->ads if $has_ads;
  p q{</section>};

  p q{<section id=chars><h2>Characters</h2>};
  p q{<p>};
  for my $range (@$set) {
    my $count = $range->[1] - $range->[0];
    if ($count <= 255) {
      for ($range->[0]..$range->[1]) {
        pf ' <span>%s (%s)</span>', ucode $_, htescape chr $_;
      }
    } else {
      pf ' <span>%s (%s) .. %s (%s)</span>',
          ucode $range->[0], htescape chr $range->[0],
          ucode $range->[1], htescape chr $range->[1];
    }
  }
  p q{</section>};

  __PACKAGE__->footer;
} # set

sub set_compare ($$$) {
  my $expr1 = $_[1];
  my $expr2 = $_[2];
  my $has_ads = not ($expr1 =~ /\[/ or $expr2 =~ /\[/);

  p q{<!DOCTYPE html><html lang=en class=set-info>
      <title>Compare character sets "} . (htescape $expr1) . q{" and "} . (htescape $expr2) . q{"</title>};
  p q{<link rel=stylesheet href=/css>
<h1 class=site><a href="/">Chars</a>.<a href="//suikawiki.org/"><img src="//suika.suikawiki.org/~wakaba/-temp/2004/sw" alt=SuikaWiki.org></a></h1>};

  p q{<h1>Character set &mdash; compare</h1>};

  use Charinfo::Set;
  my $set1 = eval { Charinfo::Set->evaluate_expression ($expr1) };
  if (not defined $set1) {
    pf q{<p>Expression error (expr1): %s}, $@;
    return;
  }
  my $set2 = eval { Charinfo::Set->evaluate_expression ($expr2) };
  if (not defined $set2) {
    pf q{<p>Expression error (expr2): %s}, $@;
    return;
  }

  my $only_in_1 = Charinfo::Set::set_minus $set1, $set2;
  my $only_in_2 = Charinfo::Set::set_minus $set2, $set1;
  my $common = Charinfo::Set::set_minus $set1, $only_in_1;

  pf q{<section id=set class="%s"><h2>Set</h2><dl>},
      $has_ads ? 'has-ads' : '';
  for (Charinfo::Set->serialize_set ($set1)) {
    pf q{<dt>Set #1<dd><a href="/set?expr=%s">%s</a><dd><a href="/set?expr=%s">%s</a>},
        htescape percent_encode_c $expr1, htescape $expr1,
        htescape percent_encode_c $_, htescape $_;
  }
  for (Charinfo::Set->serialize_set ($set2)) {
    pf q{<dt>Set #2<dd><a href="/set?expr=%s">%s</a><dd><a href="/set?expr=%s">%s</a>},
        htescape percent_encode_c $expr2, htescape $expr2,
        htescape percent_encode_c $_, htescape $_;
  }
  for (Charinfo::Set->serialize_set ($common)) {
    pf q{<dt>Common set<dd><a href="/set?expr=%s">%s</a>},
        htescape percent_encode_c $_, htescape $_;
  }
  for (Charinfo::Set->serialize_set ($only_in_1)) {
    pf q{<dt>Only in #1<dd><a href="/set?expr=%s">%s</a>},
        htescape percent_encode_c $_, htescape $_;
  }
  for (Charinfo::Set->serialize_set ($only_in_2)) {
    pf q{<dt>Only in #2<dd><a href="/set?expr=%s">%s</a>},
        htescape percent_encode_c $_, htescape $_;
  }

  p q{</dl>};
  __PACKAGE__->ads if $has_ads;
  p q{</section>};
  __PACKAGE__->footer;
} # set_compare

sub set_list ($) {
  p q{<!DOCTYPE html><html lang=en class=set-info>
      <title>Character sets</title>};
  p q{<link rel=stylesheet href=/css>
<h1 class=site><a href="/">Chars</a>.<a href="//suikawiki.org/"><img src="//suika.suikawiki.org/~wakaba/-temp/2004/sw" alt=SuikaWiki.org></a></h1>};

  p q{<h1>Character sets</h1>};

  p q{
    <section id=form>
      <dl>
        <dt>Show characters in the set
        <dd>
          <form action=/set method=get>
            <p><label><strong>Expression</strong>: <input name=expr></label><button type=submit>Evaluate</button>
          </form>
        <dt>Compare characters in sets
        <dd>
          <form action=/set/compare method=get>
            <p><label><strong>Expression #1</strong>: <input name=expr1></label>
            <p><label><strong>Expression #2</strong>: <input name=expr2></label>
            <p><button type=submit>Compare</button>
          </form>
      </dl>
  };
  __PACKAGE__->ads;
  p q{
      <section id=variables>
        <h3>Variables</h3>
        <ul>
  };
  for (sort { $a cmp $b } @{Charinfo::Set->get_set_list}) {
    pf q{<li><a href="/set?expr=%s">%s</a>},
        percent_encode_c $_, htescape $_;
  }
  p q{
        </ul>
      </section>
    </section>
  };
  __PACKAGE__->footer;
} # set_list

my $Commit = `git rev-parse HEAD`;
$Commit =~ s/[^0-9A-Za-z]+//g;

sub footer ($) {
  p qq{

<h2 id=about>About charinfo</h2>

<p>This is Charinfo version <a
href="https://github.com/wakaba/charinfo-cgi/commit/$Commit">$Commit</a>.

<p>Git repository: <a
href="http://suika.suikawiki.org/gate/git/wi/char/charinfo.git/tree">Suika</a>
/ <a href="https://github.com/wakaba/charinfo-cgi">GitHub</a>

<script>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-39820773-3', 'suikawiki.org');
  ga('send', 'pageview');
</script>

};
} # footer

sub ads ($) {
  p q{
      <aside class=ads>
        <script>
          google_ad_client = "ca-pub-6943204637055835";
          google_ad_slot = "1478788718";
          google_ad_width = 300;
          google_ad_height = 250;
        </script>
        <script src="http://pagead2.googlesyndication.com/pagead/show_ads.js"></script>
      </aside>
  };
} # ads

1;

=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 LICENSE

Copyright 2011-2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
