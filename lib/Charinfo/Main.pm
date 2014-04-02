#line 1 "Charinfo::Main"
package Charinfo::Main;
use strict;
use warnings;
no warnings 'utf8';
use Encode;
use URL::PercentEncode qw(percent_encode_c percent_decode_c
                          percent_encode_b percent_decode_b);
use Charinfo::Name;
use Charinfo::Set;
use Charinfo::Map;

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

sub ucode_with_char ($) {
  if ($_[0] > 0x10FFFF) {
    return sprintf '<a href="/char/%08X">U-%08X</a>', $_[0], $_[0];
  } else {
    return sprintf '<a href="/char/%04X">U+%04X</a>&nbsp;(<bdo>%s</bdo>)',
        $_[0], $_[0], chr $_[0];
  }
} # ucode_with_char

sub ucodes_with_chars ($) {
  if (@{$_[0]} == 0) {
    return '';
  } elsif (@{$_[0]} == 1) {
    if ($_[0]->[0] > 0x10FFFF) {
      return sprintf '<a href="/char/%08X">U-%08X</a>',
          $_[0]->[0], $_[0]->[0];
    } else {
      return sprintf '<a href="/char/%04X">U+%04X</a>&nbsp;(<bdo>%s</bdo>)',
          $_[0]->[0], $_[0]->[0], chr $_[0]->[0];
    }
  } else {
    return '<a href="/string?s='.(
      percent_encode_c join '', map { chr $_ } @{$_[0]}
    ).'"><code>&lt;' . join (',&nbsp;', map {
      if ($_ > 0x10FFFF) {
        sprintf 'U-%08X', $_;
      } else {
        sprintf 'U+%04X', $_;
      }
    } @{$_[0]}) . '&gt;</code></a>&nbsp;(<bdo>'.(
      htescape join '', map { chr $_ } @{$_[0]}
    ).'</bdo>)'
  }
} # ucode_with_char

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
    pf ' (<bdo>%s</bdo>) ', htescape $c;
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
    $v =~ s/ at (?:\Q$0\E|\(eval \d+\)|\S+) line \d+(?:, <[^<>]*> line \d+)?\.?$//;
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

  my $names = Charinfo::Name->char_code_to_names (ord $char[0]);
  __PACKAGE__->char_names ($names);

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
} else {
  my $names = Charinfo::Name->char_seq_to_names ($string);
  if (defined $names) {
    p q{<section id=char><h2>Named character sequence</h2><table>};
    pf q{<tr><th>Characters<td><code class=target-char>%s</code>},
        htescape $string;
    pf q{<tr><th>Code points<td><code>&lt;%s></code>},
        join ', ', map { sprintf 'U+%04X', ord $_ } @char;
    __PACKAGE__->char_names ($names);
    p q{</table>};
    __PACKAGE__->ads;
    p q{</section>};
  }
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

  p q{</table>};

  {
    p q{<section id=encodings><h2>Encodings</h2>};

    p q{<table><tbody><tr class=category><th colspan=3>Unicode encodings};

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
{
  p q{<tr><th>UTF-32LE};
  p_bytes encode 'utf-32le', $string;
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
        pf $prefix . '<td colspan=2><a href="data:text/plain;charset=%s,%s">%s</a>',
            percent_encode_c $encoding,
            percent_encode_b (join '', map { pack 'C', $_ } @$_),
            join ' ', map { sprintf '0x%02X', $_ } @$_;
        $prefix = '<tr>';
      }
    } else {
      push @not_encodable, $encoding;
    }
  }
  if (@not_encodable) {
    p '<tr><td colspan=3><strong>Not encodable in</strong>: ' . join ' ', @not_encodable;
  }
}

    p q{</table></section>};
  }

  {
    p q{<section id=escapes><h2>Escapes</h2><table>};

    {
      p q{<tr><th>Input};
      p_string $string;
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
    p q{</table></section>};
  }

  p q{<h2 id=strdata>String</h2><table>};

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


    {
      pf q{<tr><th>Canonical decomposition};
      p_string +Charinfo::Map->apply_to_string ('unicode:canon_decomposition', $string);
    }
    {
      pf q{<tr><th>Compatibility decomposition};
      p_string +Charinfo::Map->apply_to_string ('unicode:compat_decomposition', $string);
    }
    {
      pf q{<tr><th>Canonical composition};
      p_string +Charinfo::Map->apply_to_string ('unicode:canon_composition', $string);
    }

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

  {
    p q{<tbody><tr class=category><th colspan=3>Cases};

    {
      pf q{<tr><th>ASCII uppercase};
      my $v = $string;
      $v =~ tr/a-z/A-Z/;
      p_string $v;
    }
    {
      pf q{<tr><th>ASCII lowercase};
      my $v = $string;
      $v =~ tr/A-Z/a-z/;
      p_string $v;
    }
    {
      pf q{<tr><th>Uppercase (Perl <code>uc</code>)};
      p_string uc $string;
    }
    {
      pf q{<tr><th>Lowercase (Perl <code>lc</code>)};
      p_string lc $string;
    }
    {
      pf q{<tr><th>Uppercase_Mapping(C)};
      p_string +Charinfo::Map->apply_to_string ('unicode:Uppercase_Mapping', $string);
    }
    {
      pf q{<tr><th>Lowercase_Mapping(C)};
      p_string +Charinfo::Map->apply_to_string ('unicode:Lowercase_Mapping', $string);
    }
    {
      pf q{<tr><th>Case_Folding(X)};
      p_string +Charinfo::Map->apply_to_string ('unicode:Case_Folding', $string);
    }
    {
      pf q{<tr><th>NFKC_Casefold(X)};
      p_string +Charinfo::Map->apply_to_string ('unicode:NFKC_Casefold', $string);
    }
    {
      pf q{<tr><th>Compatibility case folding};
      p_string NFKD +Charinfo::Map->apply_to_string ('unicode:Case_Folding', NFKD +Charinfo::Map->apply_to_string ('unicode:Case_Folding', NFD $string));
    }
  }

  p "</table>";

  p q{<section id=fonts><h2>Fonts</h2>
    <p><em>Note that your system might not have specified fonts.</em>
    <div><table>
  };
  for my $font (
    'serif',
    'sans-serif',
    'monospace',
    'cursive',
    'fantasy',
    "'Times New Roman'",
    "'Arial'",
    "'Arial Unicode MS'",
    "'Helvetica'",
    "'Verdana'",
    "'Lucida Grande'",
    "'Courier New'",
    "'Comic Sans MS'",
    "'MS PMincho'",
    "'MS PGothic'",
    "'Meiryo'",
    "'Osaka'",
    "'Hiragino Kaku Gothic ProN'",
    "'Symbol'",
    "'Wingdings'",
    "'Wingdings 2'",
    "'Wingdings 3'",
    "'Webdings'",
  ) {
    pf q{<tr><th><code>%s</code><td><code style="font-family: %s">%s</code>},
        htescape $font, htescape $font, htescape $string;
  }
  p q{</table></div></section>};

  if (@char == 1) {
    my $sets = Charinfo::Set->get_sets_by_char (ord $char[0]);
    if (@$sets) {
      p q{
        <section class=set-list>
          <h2>Sets</h2>
          <p>The character belongs to following character sets:
          <ul>
      };
      for (sort { $a cmp $b } @$sets) {
        pf q{<li><a href="/set/%s">%s</a>},
            percent_encode_c $_, htescape $_;
      }
      p q{</ul></section>};
    }

    my $maps = Charinfo::Map->get_maps_by_char (ord $char[0]);
    if (@$maps) {
      p q{
        <section class=set-list>
          <h2>Maps</h2>
          <p>The character belongs to following character mappings:
          <ul>
      };
      for (sort { $a cmp $b } @$maps) {
        pf q{<li><a href="/map/%s">%s</a>},
            percent_encode_c $_, htescape $_;
      }
      p q{</ul></section>};
    }
  }

  __PACKAGE__->footer;
} # main

sub char_names ($$) {
  my $names = $_[1];
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
} # char_names

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
        <li><a href="/map">Maps</a>
      </ul>
  };
  __PACKAGE__->ads;
  p q{
    </div>
  };
  __PACKAGE__->footer;
} # top

sub set ($$$) {
  my (undef, $app, $expr) = @_;
  my $has_ads = not $expr =~ /\[/;

  my $set = eval { Charinfo::Set->evaluate_expression ($expr) };
  unless (defined $set) {
    $app->http->set_status (400);
  }

  my $is_set = $expr =~ /\A\$[0-9A-Za-z_.:-]+\z/;

  __PACKAGE__->header (title => 'Character set "'.$expr.'"',
                       class => 'set-info');
  p q{<h1>Character set</h1>};

  if (not defined $set) {
    pf q{<p>Expression error: %s}, $@;
    __PACKAGE__->footer;
    return;
  }

  pf q{<section id=set class="%s"><h2>Set</h2><dl>},
      $has_ads ? 'has-ads' : '';

  my $orig = htescape $expr;
  $orig =~ s{(\$[0-9A-Za-z0-9:_.-]+)}{sprintf '<a href="/set/%s">%s</a>', percent_encode_c $1, $1}ge;
  pf q{<dt>Original expression<dd><code>%s</code>}, $orig;

  pf q{<dt>Normalized<dd><code>%s</code>},
      htescape +Charinfo::Set->serialize_set ($set);

  my $count = 0;
  for my $range (@$set) {
    $count += $range->[1] - $range->[0] + 1;
  }
  pf q{<dt>Number of characters<dd>%d}, $count;

  p q{</dl>};

  p q{<p><em>The set definition is contained in <a href="https://github.com/manakai/data-chars/blob/master/data/sets.json"><code>sets.json</code></a> data file.</em>}
      if $is_set;

  __PACKAGE__->ads if $has_ads;
  p q{</section>};

  p q{<section id=chars><h2>Characters</h2>};
  p q{<p>};
  for my $range (@$set) {
    my $count = $range->[1] - $range->[0];
    if ($count <= 255) {
      for ($range->[0]..$range->[1]) {
        pf ' <span>%s (<bdo>%s</bdo>)</span>', ucode $_, htescape chr $_;
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
  __PACKAGE__->header (title => 'Character sets', class => 'set-info');
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
    pf q{<li><a href="/set/%s">%s</a>},
        percent_encode_c $_, htescape $_;
  }
  p q{
        </ul>
      </section>
    </section>
  };
  __PACKAGE__->footer;
} # set_list

sub map_list ($) {
  __PACKAGE__->header (title => 'Character mappings');
  p q{<h1>Character mappings</h1>};

  p q{
    <section>
      <h2>Compare maps</h2>
      <form action=/map/compare method=get>
        <p><label><strong>Name #1</strong> <input name=expr1></label>
        <p><label><strong>Name #2</strong> <input name=expr2></label>
        <p><button type=Submit>Compare</button>
      </form>
    </section>
  };

  p q{<section class=has-ads>};
  p q{<h2>List of maps</h2>};

  p q{<ul>};
  for (sort { $a cmp $b } @{Charinfo::Map->get_list}) {
    pf q{<li><a href="/map/%s"><code>%s</code></a>},
        percent_encode_c $_, htescape $_;
  }
  p q{</ul>};

  __PACKAGE__->ads;
  p q{</section>};
  __PACKAGE__->footer;
} # map_list

sub print_map ($) {
  my $map = $_[0];
  p q{<p>};
  if (keys %$map) {
    my %entries;
    for (keys %$map) {
      my $w = [map { hex $_ } split / /, $_];
      my $v = [map { hex $_ } split / /, $map->{$_}];
      my $from = ucodes_with_chars $w;
      my $to = ucodes_with_chars $v;
      if ($to eq '') {
        $entries{join '', map { chr $_ } @$w} = $from;
      } else {
        $entries{join '', map { chr $_ } @$w} = "$from&nbsp;->&nbsp;$to";
      }
    }
    p join '; ', map { $entries{$_} } sort { $a cmp $b } keys %entries;
  } else {
    p q{(Empty)};
  }
} # print_map

sub map_page ($$$) {
  my (undef, $app, $name) = @_;

  my $def = Charinfo::Map->get_def_by_name ($name);
  unless (defined $def) {
    $app->http->set_status (404);
    __PACKAGE__->header (title => 'Character mapping "'.$name.'"');
    p q{<h1>Character mappings</h1>};
    pf q{<p>Map <code>%s</code> not found.},
        htescape $name;
    __PACKAGE__->footer;
    return;
  }

  __PACKAGE__->header (title => 'Character mapping "'.$name.'"');
  p q{<h1>Character mapping</h1>};

  p q{<section class=has-ads>};
  pf q{<h2>Mapping <code>%s</code></h2>},
      htescape $name;

  p q{<dl>};
  pf q{<dt>Name<dd><code>%s</code>},
      htescape $name;

  {
    my $n = 0;
    for (qw(char_to_char char_to_empty char_to_seq
            seq_to_char seq_to_empty seq_to_seq)) {
      $n += scalar keys %{$def->{$_}};
    }
    pf q{<dt>Number of non-identical mapping entries
         <dd>%d (<strong>1->1</strong>: %d, <strong>1->n</strong>: %d,
                 <strong>n->1</strong>: %d, <strong>n->n</strong>: %d,
                 <strong>1->0</strong>: %d, <strong>n->0</strong>: %d)},
             $n,
             scalar keys %{$def->{char_to_char}},
             scalar keys %{$def->{char_to_seq}},
             scalar keys %{$def->{seq_to_char}},
             scalar keys %{$def->{seq_to_seq}},
             scalar keys %{$def->{char_to_empty}},
             scalar keys %{$def->{seq_to_empty}};
  }

  p q{</dl>};

  p q{<p><em>The map definition is contained in <a href="https://github.com/manakai/data-chars/blob/master/data/maps.json"><code>maps.json</code></a> data file.</em>};

  for my $x (
    [char_to_char => 'One-to-one mapping entries'],
    [char_to_seq => 'One-to-many mapping entries'],
    [seq_to_char => 'Many-to-one mapping entries'],
    [seq_to_seq => 'Many-to-many mapping entries'],
    [char_to_empty => 'Deleted characters'],
    [seq_to_empty => 'Deleted character sequences'],
  ) {
    next unless keys %{$def->{$x->[0]}};
    pf q{<section class=map-entries><h3>%s</h3>}, $x->[1];
    print_map $def->{$x->[0]};
    p q{</section>};
  } # $x

  __PACKAGE__->ads;
  p q{</section>};
  __PACKAGE__->footer;
} # map_page

sub map_compare ($$$$) {
  my (undef, $app, $name1, $name2) = @_;

  my $diff = Charinfo::Map->get_diff ($name1, $name2);
  unless (defined $diff) {
    $app->http->set_status (404);
    __PACKAGE__->header (title => 'Character mappings "'.$name1.'" and "'.$name2.'"');
    p q{<h1>Character mappings</h1>};
    pf q{<p>Map <code>%s</code> or <code>%s</code> not found.},
        htescape $name1, htescape $name2;
    __PACKAGE__->footer;
    return;
  }

  __PACKAGE__->header (title => 'Character mappings "'.$name1.'" and "'.$name2.'"');
  p q{<h1>Character mappings</h1>};

  p q{<section class=has-ads>};
  pf q{<h2>Mappings</h2>};

  p q{<dl>};
  pf q{<dt>Map #1<dd><a href="/map/%s"><code>%s</code></a>},
      percent_encode_c $name1, htescape $name1;
  pf q{<dt>Map #2<dd><a href="/map/%s"><code>%s</code></a>},
      percent_encode_c $name2, htescape $name2;
  pf q{<dt>Number of differences<dd>%d
           (<a href=#only-1><strong>Only in #1</strong></a>: %d,
            <a href=#only-2><strong>Only in #2</strong></a>: %d,
            <a href=#diff><strong>Different</strong></a>: %d)},
      (keys %{$diff->{only_in_1}}) + (keys %{$diff->{only_in_2}}) +
      (keys %{$diff->{different}}),
      scalar keys %{$diff->{only_in_1}},
      scalar keys %{$diff->{only_in_2}},
      scalar keys %{$diff->{different}};
  p q{</dl>};

  p q{<section class=map-entries id=only-1><h3>Only in #1</h3>};
  print_map $diff->{only_in_1};
  p q{</section>};

  p q{<section class=map-entries id=only-2><h3>Only in #2</h3>};
  print_map $diff->{only_in_2};
  p q{</section>};

  p q{<section class=map-entries id=diff><h3>Different</h3>};
  if (keys %{$diff->{different}}) {
    p q{<table><thead><tr><th>From<th>To #1<th>To #2<tbody>};
    for (keys %{$diff->{different}}) {
      my $v = $diff->{different}->{$_};
      pf q{<tr><td>%s<td>%s<td>%s},
          ucodes_with_chars [map { hex $_ } split / /, $_],
          ucodes_with_chars [map { hex $_ } split / /, $v->[0]],
          ucodes_with_chars [map { hex $_ } split / /, $v->[1]];
    }
    p q{</table>};
  } else {
    p q{<p>(Empty)};
  }
  p q{</section>};

  p q{<section class=map-entries id=same><h3>Common</h3>};
  print_map $diff->{same};
  p q{</section>};

  __PACKAGE__->ads;
  p q{</section>};
  __PACKAGE__->footer;
} # map_compare

sub header ($;%) {
  my ($class, %args) = @_;
  pf q{<!DOCTYPE html><html lang=en class="%s">
       <title>%s</title>},
      htescape ($args{class} // ''),
      htescape ($args{title} // 'Charinfo');
  p q{<link rel=stylesheet href=/css>
<h1 class=site><a href="/">Chars</a>.<a href="//suikawiki.org/"><img src="//suika.suikawiki.org/~wakaba/-temp/2004/sw" alt=SuikaWiki.org></a></h1>};
} # header

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
