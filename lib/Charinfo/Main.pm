#line 1 "Charinfo::Main"
package Charinfo::Main;
use strict;
use warnings;
no warnings 'utf8';
use Encode;
use Web::Encoding;
use Web::URL::Encoding;
use Charinfo::App;
use Charinfo::Name;
use Charinfo::Set;
use Charinfo::Map;
use Charinfo::Seq;
use Charinfo::Number;
use Charinfo::Fonts;
use Charinfo::Keys;

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

sub ucode_list ($) {
  return sprintf q{<code class=code-points>%s</code>},
        join ' ', map { sprintf 'U+%04X', ord $_ } split //, $_[0];
} # ucode_list

sub ucode_range ($%) {
  my ($range, %args) = @_;
  my $count = $range->[1] - $range->[0];
  if ($count <= $args{max}) {
    return join '', map {
      sprintf q{%s<a href="/char/%04X"><bdo>%s</bdo></a> <code class=code-points>%s</code>%s},
          $args{prefix}, $_, htescape chr $_, ucode $_, $args{suffix};
    } $range->[0]..$range->[1];
  } else {
    return sprintf q{%s<a href="/char/%04X"><bdo>%s</bdo></a> <code class=code-points>%s</code>%s
          %s<a href="/set?expr=%s">...</a>%s
          %s<a href="/char/%04X"><bdo>%s</bdo></a> <code class=code-points>%s</code>%s},
        $args{prefix}, $range->[0], htescape chr $range->[0], ucode $range->[0], $args{suffix},
        $args{prefix}, (percent_encode_c sprintf q{[\u{%04X}-\u{%04X}]}, $range->[0], $range->[1]), $args{suffix},
        $args{prefix}, $range->[1], htescape chr $range->[1], ucode $range->[1], $args{suffix};
  }
} # ucode_range

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
  pf q{<td class=pattern-%d>
    <a href="%s?s=%s">%s</a>
    <button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy</button>
  },
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
  pf q{<td colspan=2>
    <code>%s</code>
    <button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy</button>
    <code hidden>%s</code>
    <button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy \x<var>HH</var></button>
  },
      (join ' ', map { sprintf '0x%02X', ord $_ } split //, $string),
      (join '', map { sprintf '\x%02X', ord $_ } split //, $string);
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
  pf q{<td colspan=2 class=pattern-%d>
    <a href="%s?s=%s">%s</a>
    <button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy</button>
  },
      $ci,
      '/string',
      (percent_encode_c $string),
      $string;
} # p_ascii_string

sub p_link_string ($) {
  my $string = shift;
  if (not defined $string) {
    p "<td colspan=2>(undef)";
    return;
  } elsif ($string eq '') {
    p "<td colspan=2>(empty)";
    return;
  }
  pf q{<td colspan=2>
    <a href="%s?s=%s">%s</a>
    <button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy</button>
  },
      '/string',
      (percent_encode_c $string),
      $string;
} # p_link_string

sub or_p_error (&) {
  my $code = shift;
  eval { $code->(); 1 } or do {
    my $v = $@;
    $v =~ s/ at (?:\Q$0\E|\(eval \d+\)|\S+) line \d+(?:, <[^<>]*> line \d+)?\.?$//;
    p q{<td colspan=2 class=error>}, htescape $v;
  };
} # or_p_error

sub main ($$$) {
  my (undef, $string, $app) = @_;
  $color_indexes = {};

  my $sets = $app->text_param_list ('set');
  @$sets = @$sets[0..4] if @$sets > 5;

  my @char = split //, $string;
  my $names = 1 == length $string
      ? Charinfo::Name->char_code_to_names (ord $char[0])
      : Charinfo::Name->char_seq_to_names ($string);

  my $canon;
  if (not @$sets and 1 == length $string) {
    $canon = sprintf '/char/%04X', ord $string;
  }

  my $title;
  my $heading;
  if (defined $names and defined ($names->{name} // $names->{label})) {
    if (1 == length $string) {
      $title = sprintf 'U+%04X %s (%s) - Charinfo',
          ord $string, $names->{name} // $names->{label}, $string;
      $heading = sprintf '<code>U+%04X</code> <code class=charname>%s</code> (<code>%s</code>)',
          ord $string, htescape ($names->{name} // $names->{label}),
          htescape $string;
    } else {
      $title = sprintf '%s (%s) - Charinfo',
          $names->{name} // $names->{label}, $string;
      $heading = sprintf '<code class=charname>%s</code> (<code>%s</code>)',
          htescape ($names->{name} // $names->{label}),
          htescape $string;
    }
  } else {
    if ($string eq '') {
      $title = 'The empty string - Charinfo';
      $heading = 'The empty string';
    } else {
      $title = sprintf '"%s" - Charinfo', $string;
      $heading = sprintf '"<bdi>%s</bdi>"', htescape $string;
    }
  }

  __PACKAGE__->header (title => $title, canonical => $canon);
  pf q{<h1>Charinfo &mdash; %s</h1>}, $heading;

  p qq{
<form action=/string>
  <label>String:
    <input type=text name=s value="@{[htescape $string]}">
  </label>
  <button type=submit>Show</button>
};
  for (@$sets) {
    p qq{<input type=hidden name=set value="@{[htescape $_]}">};
  }
  p qq{</form><menu class=toc data-sections="body > section"></menu>};

  my $print_ads = 0;

  if ($string =~ m{\A\\u([0-9A-Fa-f]{4})\z}) {
    pf q{<div class=suggest>
      &#x2192; <a href="/string?s=%s&amp;escape=u">Unescape <code>\u</code>:
      <code>U+%04X</code> (<bdi>%s</bdi>)</a>
    </div>},
        percent_encode_c $string, hex $1, chr hex $1;
  }

if (@char == 1) {
  p q{<section id=char><h1>Character</h1><table>};

  pf q{<tr><th>Character
           <td><code class=target-char>%s</code>
               <button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy</button>
  },
      $char[0];

  pf q{<tr><th rowspan=2>Code point
       <td><strong><code>%s</code></strong>
           <button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy</button>
           = <a href="https://data.suikawiki.org/number/%d"><code>%d</code><sub>10</sub></a>
             <button type=button class=copy onclick=" copyElement (previousElementSibling.firstElementChild) ">Copy</button>
           = <code>%o</code><sub>8</sub>
             <button type=button class=copy onclick=" copyElement (previousElementSibling.previousElementSibling) ">Copy</button>
       <tr>
       <td>= <code>%08b %08b %08b %08b</code><sub>2</sub>
             <button type=button class=copy onclick=" copyElement (previousElementSibling.previousElementSibling) ">Copy</button>},
      ucode ord $char[0],
      ord $char[0], ord $char[0],
      ord $char[0],
      (ord $char[0]) >> 24, ((ord $char[0]) >> 16) & 0xFF,
      ((ord $char[0]) >> 8) & 0xFF, (ord $char[0]) & 0xFF;

  __PACKAGE__->char_names ($names);

  #use Unicode::CharName;
  #pf q{<tr><th>Block<td>%s},
  #    Unicode::CharName::ublock (ord $char[0]) // '(unassigned)';

  my $area_u = int ((ord $char[0]) / 0x100);
  my $area = sprintf '<a href="/set/%02X%%3F%%3F"><code class=char-range>U+%02X<var>??</var></code></a>', $area_u, $area_u;
  pf q{<tr><th>Nearby<td>
    %s /
    Previous: %s (%s) /
    Next: %s (%s)
  },
      $area,
      ucode (-1 + ord $char[0]), chr (-1 + ord $char[0]),
      ucode (1 + ord $char[0]), chr (1 + ord $char[0]);

  p q{</table>};

  pf q{<p>
    [<a href="https://wiki.suikawiki.org/n/%s"%s>Notes</a>]
    [<a href="http://unicode.org/cldr/utility/character.jsp?a=%04X">Unicode</a>]
    [<a href="http://www.unicode.org/cgi-bin/GetUnihanData.pl?codepoint=%04X&amp;useutf8=true">Unihan</a>]},
      (ord $char[0] > 0x10FFFF ? (sprintf 'U-%08X', ord $char[0]) : (sprintf 'U%%2B%04X', ord $char[0])),
      (ord $char[0] > 0x10FFFF ? 'rel=nofollow' : ''),
      ord $char[0],
      ord $char[0];

  __PACKAGE__->ads;
  p q{</section>};
} else {
  if (defined $names) {
    p q{<section id=char><h1>Named character sequence</h1><table>};
    pf q{<tr><th>Characters
             <td><code class=target-char>%s</code>
                 <button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy</button>
    },
        htescape $string;
    pf q{<tr><th>Code points<td><code>&lt;%s></code>},
        join ', ', map { sprintf 'U+%04X', ord $_ } @char;
    __PACKAGE__->char_names ($names);
    p q{</table>};

    pf q{<p>[<a href="https://wiki.suikawiki.org/n/%s">Notes</a>]},
        percent_encode_c join '', @char;

    __PACKAGE__->ads;
    p q{</section>};
  } elsif ($string =~ m{\A\\u[0-9A-Fa-f]{4}\z}) {
    $print_ads = 1;
  }
}

  my $sets_by_chars = [map { Charinfo::Set->get_sets_by_char (ord $_) } @char];
  p q{<section id=chardata><h1>Characters</h1>};

  pf q{<p>Code point length = <a href="https://data.suikawiki.org/number/%d">%d</a>},
      0+@char, 0+@char;

  p q{<table class=char-info><tbody>};
  {
    p q{<tr><th>Character};
    p q{<td>}, htescape $_ for @char;
  }
  {
    p q{<tr><th>Code point};
    pf q{<td>%s}, ucode ord $_ for @char;
  }

  p q{<tbody>};
  for my $prop (qw(Age Script Bidi_Class Canonical_Combining_Class)) { # Block
    p qq{<tr><th><a href="https://wiki.suikawiki.org/n/$prop"><code>$prop</code></a>};
    my $m = qr{^\$unicode:$prop:};
    for (0..$#char) {
      p q{<td>};
      for my $set (grep { /$m/ } @{$sets_by_chars->[$_]}) {
        my $value = $set;
        $value =~ s/$m//;
        pf qq{<a href="/set/%s"><code>%s</code></a> },
            (percent_encode_c $set),
            (htescape $value);
      }
    }
  }

use Unicode::UCD 'charinfo';
my @charinfo = map { charinfo ord $_ or {} } @char;
{
  p q{<tr><th>bidi (Unicode::UCD)};
  p q{<td>}, htescape $_->{bidi} for @charinfo;
}

{
  p q{<tr><th><a href=https://manakai.github.io/spec-numbers/#value>CJK numeral value</a>};
  for (@char) {
    my $value = Charinfo::Number->char_to_cjk_numeral ($_);
    if (defined $value) {
      pf q{<td><a href="https://data.suikawiki.org/number/%d">%d</a>},
          $value, $value;
    } else {
      p q{<td>-};
    }
  }
}

  {
    next unless @$sets;
    p q{<tbody>};
    for my $set_expr (@$sets) {
      my $set = eval { Charinfo::Set->evaluate_expression ($set_expr) };
      my @in;
      if (defined $set) {
        for (@char) {
          push @in, Charinfo::Set->char_is_in_set (ord $_, $set);
        }
      }
      pf q{<tr><th class="%s"><a href="/set?expr=%s"><code>%s</code></a>},
          htescape (defined $set ? (not grep { not $_ } @in) ? 'in-set' : 'not-in-set' : 'error'),
          percent_encode_c $set_expr,
          htescape $set_expr;
      if (defined $set) {
        for (@in) {
          if ($_) {
            pf q{<td class=in-set>&#x2714;};
          } else {
            pf q{<td class=not-in-set>-};
          }
        }
      } else {
        pf q{<td colspan=%d class=error>Set expression error}, 0+@char;
      }
    }
  }

  p q{</table></section>};

  {
    if ($print_ads) {
      p q{<section id=encodings class=has-ads><h1>Encodings</h1>};
      __PACKAGE__->ads;
    } else {
      p q{<section id=encodings><h1>Encodings</h1>};
    }

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

  {
    p q{<tbody><tr class=category><th colspan=3>Web encodings};

    use Charinfo::Encoding;
    my @not_encodable;
    for my $encoding (@{+encoding_names}) {
      next if $encoding eq 'replacement';
      my $encoded_bytes = encode_web_charset $encoding, $string;
      my $roundtriped = decode_web_charset $encoding, $encoded_bytes;
      if ($roundtriped eq $string) {
        my $encoded = [[map { ord $_ } split //, $encoded_bytes]];
        if ($encoding eq 'iso-2022-jp' and @char == 1) {
          $encoded = Charinfo::Encoding::iso2022jp ord $char[0];
        }
        p qq{<tr><th rowspan="@{[scalar @$encoded]}"><a href="https://encoding.spec.whatwg.org/#$encoding">$encoding</a>};
        my $prefix = '';
        for (@$encoded) {
          pf q{%s<td colspan=2>
                 <a href="data:text/plain;charset=%s,%s">%s</a> <button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy</button>
                 <span hidden>%s</span> <button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy \x<var>HH</var></button>
          },
              $prefix,
              percent_encode_c $encoding,
              oauth1_percent_encode_b (join '', map { pack 'C', $_ } @$_),
              (join ' ', map { sprintf '0x%02X', $_ } @$_),
              (join '', map { sprintf '\x%02X', $_ } @$_);
          $prefix = '<tr>';
        }
      } else {
        push @not_encodable, $encoding;
      }
    }
    if (@not_encodable) {
      p '<tr><td colspan=3><strong>Not encodable in</strong>: ' . join ' ', @not_encodable;
    }
  } # Web Encodings

    p q{</table></section>};
  }

  {
    p q{<section id=escapes><h1>Escapes</h1><table class=char-escapes>};

    {
      p q{<tr><th>Input};
      p_string $string;
    }
p q{<tbody><tr class=category><th colspan=3>Escapes};

# XXX CL/CR range
{
  p q{<tr><th>HTML/XML decimal};
  p_link_string join '', map { sprintf '&amp;#%d;', ord $_ } split //, $string;
}
{
  p q{<tr><th>HTML/XML hexadecimal};
  p_link_string join '', map { sprintf '&amp;#x%X;', ord $_ } split //, $string;
}
{
  p q{<tr><th>CSS};
  p_link_string join '', map { sprintf '\\%06X', ord $_ } split //, $string;
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
    p_ascii_string oauth1_percent_encode_b encode 'utf-8', $string;
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
    p_link_string join '', map { sprintf (($_ <= 0xFFFF ? '\\u%04X' : '\\U%08X'), $_) } map { ord $_ } split //, $string;
  };
}
{
  my $escaped = join '', map { 0x20 <= $_ && $_ <= 0x7E && $_ != 0x5C ? chr $_ : sprintf (($_ <= 0xFFFF ? '\\u%04X' : '\\U%08X'), $_) } map { ord $_ } split //, $string;
  pf q{<tr><th><a href="/string?s=%s&amp;escape=u">en-\u non-ASCII</a>},
      percent_encode_c $escaped;
  or_p_error {
    p_link_string $escaped;
  };
}
{
  p q{<tr><th>de-surrogate};
  or_p_error {
    p_string decode 'utf-16-be', join '', map { $_ > 0x10FFFF ? "\xFF\xFD" : $_ >= 0x10000 ? encode 'utf-16-be', chr $_ : pack 'CC', $_ / 0x100, $_ % 0x100 } map { ord $_ } split //, $string;
  };
}

    {
      p q{<tr><th>Perl bytes};
      or_p_error {
        p_link_string join '', map { sprintf '\x%02X', ord $_ } split //, encode 'utf-8', $string;
      };
    }
    {
      p q{<tr><th>Perl text};
      or_p_error {
        p_link_string join '', map { ord $_ < 0x100 ? sprintf '\x%02X', ord $_ : sprintf '\x{%04X}', ord $_ } split //, $string;
      };
    }

    p q{</table></section>};
  }

  p q{<section id=strdata><h1>String</h1><table>};

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
#use Net::LibIDN;

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

if (0) {
  pf q{<tr><th>Nameprep (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_p_error {
    p_string decode 'utf-8', Net::LibIDN::idn_prep_name ($string, 'utf-8');
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

if (0) {
  pf q{<tr><th>de-Punycode (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_p_error {
    p_string decode 'utf-8', Net::LibIDN::idn_punycode_decode ($string, 'utf-8');
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

if (0) {
  pf q{<tr><th>ToUnicode (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_p_error {
    p_string decode 'utf-8', Net::LibIDN::idn_to_unicode ($string, 'utf-8');
  };
}
if (0) {
  pf q{<tr><th>ToUnicode AllowUnassigned (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_p_error {
    p_string decode 'utf-8', Net::LibIDN::idn_to_unicode ($string, 'utf-8', Net::LibIDN::IDNA_ALLOW_UNASSIGNED ());
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
if (0) {
  pf q{<tr><th>en-Punycode (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_p_error {
    p_ascii_string Net::LibIDN::idn_punycode_encode ($string, 'utf-8');
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
if (0) {
  pf q{<tr><th>ToASCII (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_p_error {
    p_ascii_string decode 'utf-8', Net::LibIDN::idn_to_ascii ($string, 'utf-8');
  };
}
if (0) {
  pf q{<tr><th>ToASCII AllowUnassigned (<code>Net::LibIDN</code> %s)},
      htescape $Net::LibIDN::VERSION;
  or_p_error {
    p_ascii_string decode 'utf-8', Net::LibIDN::idn_to_ascii ($string, 'utf-8', Net::LibIDN::IDNA_ALLOW_UNASSIGNED ());
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

  p q{</table></section>};

  pf q{<section id=fonts><h1>Fonts</h1>
    <section id=langs><h1>Languages</h1>
      <div><table>
        <tr><th><code>lang=en</code><td><data lang=en>%s</data>
        <tr><th><code>lang=ja</code><td><data lang=ja>%s</data>
        <tr><th><code>lang=zh</code><td><data lang=zh>%s</data>
        <tr><th><code>lang=zh-cn</code><td><data lang=zh-cn>%s</data>
        <tr><th><code>lang=zh-tw</code><td><data lang=zh-tw>%s</data>
        <tr><th><code>lang=zh-hk</code><td><data lang=zh-hk>%s</data>
        <tr><th><code>lang=zh-mo</code><td><data lang=zh-mo>%s</data>
        <tr><th><code>lang=zh-sg</code><td><data lang=zh-sg>%s</data>
        <tr><th><code>lang=zh-hans-cn</code><td><data lang=zh-hans-cn>%s</data>
        <tr><th><code>lang=zh-hant-tw</code><td><data lang=zh-hant-tw>%s</data>
        <tr><th><code>lang=ko</code><td><data lang=ko>%s</data>
        <tr><th><code>lang=vi</code><td><data lang=vi>%s</data>
      </table></div>
    </section>
    <section id=writing-modes><h1>Writing modes</h1>
      <div><table>
        <tr><th><code>dir=ltr</code><td><data dir=ltr>%s</data>
        <tr><th><code>dir=rtl</code><td><data dir=rtl>%s</data>
        <tr><th><code>'writing-mode: vertical-rl'</code><td><data style="-webkit-writing-mode:vertical-rl;writing-mode:vertical-rl">%s</data>
      </table></div>
    </section>
    <section id=css-fonts><h1>CSS fonts</h1>
    <div><table>
  }, (htescape $string) x 15;
  for my $font (@{Charinfo::Fonts->css_font_keywords}) {
    pf q{<tr><th><code>%s</code><td><data style="font-family: %s">%s</data>},
        htescape $font, htescape $font, htescape $string;
  }
  pf q{<tr><th><code>font-style: italic</code><td><data style="font-style: italic">%s</data>},
      htescape $string;
  pf q{<tr><th><code>font-variant: small-caps</code><td><data style="font-variant: small-caps">%s</data>},
      htescape $string;
  for my $weight (qw(100 200 300 400 500 600 700 800 900)) {
    pf q{<tr><th><code>font-weight: %s</code><td><data style="font-weight: %s">%s</data>},
        $weight, $weight, htescape $string;
  }
  p q{
    </table></div>
    </section>
    <section id=web-fonts>
    <h1>Web fonts</h1>
    <div><table>
  };
  for (@{Charinfo::Fonts->web_fonts}) {
    pf q{<tr><th><a href="%s"><code>%s</code></a><td>
      <style scoped>
        @font-face {
          font-family: 'wf-%s';
          src: url('/fonts/%s');
        }
      </style>
      <data style="font-family: 'wf-%s';text-rendering: optimizeLegibility;-webkit-font-smoothing: antialiased;">%s</data>
    },
        htescape $_->{url},
        htescape $_->{name},
        htescape $_->{name},
        htescape $_->{file_name},
        htescape $_->{name},
        htescape $string;
  }
  p q{
    </table></div>
    </section>
    <section id=2ch-aa-fonts>
    <h1>2ch-compatible AA fonts</h1>
    <p><em>Note that your system might not have specified fonts.</em>
    <div><table>
  };
  for (@{Charinfo::Fonts->aa_font_names}) {
    pf q{<tr><th><code>%s</code><td><data style="font-family: '%s'">%s</data> <output class=width></output>},
        htescape $_->{name}, htescape $_->{name}, htescape $string;
    if ($_->{has_web_font}) {
      pf q{<tr><th><code>%s (Web font)</code><td><data style="font-family: 'wf-%s';text-rendering: optimizeLegibility;-webkit-font-smoothing: antialiased;">%s</data> <output class=width></output>},
          htescape $_->{name}, htescape $_->{name}, htescape $string;
    }
  }
  p q{
    </table></div>
      <script>
        Array.prototype.forEach.call (document.querySelectorAll ('#\\\\32 ch-aa-fonts data[style]'), function (data) {
          var rect = data.getClientRects ()[0];
          data.nextElementSibling.textContent = 'h=' + rect.height + 'px, w=' + rect.width + 'px';
        });
      </script>
    </section>
    <section id=other-fonts>
    <h1>Other fonts</h1>
    <p><em>Note that your system might not have specified fonts.</em>
    <div><table>
  };
  for my $font (@{Charinfo::Fonts->other_font_names}) {
    pf q{<tr><th><code>%s</code><td><data style="font-family: '%s'">%s</data>},
        htescape $font, htescape $font, htescape $string;
  }
  p q{</table></div></section>};

  if (@char == 1) {
    my $seqs = Charinfo::Seq->seqs_by_char (ord $char[0]);
    if (@$seqs) {
      p q{
        <section class=seq-list>
          <h1>Sequences</h1>
          <ul>
      };
      for (@$seqs) {
        pf q{<li><a href="/string?s=%s">%s</a> <code class=code-points>%s</code>},
            percent_encode_c $_, htescape $_,
            join ' ', map { sprintf 'U+%04X', ord $_ } split //, $_;
      }
      p q{
          </ul>
        </section>
      };
    }

    if (@{$sets_by_chars->[0]}) {
      p q{
        <section class=set-list>
          <h1>Sets</h1>
          <p>The character belongs to following character sets:
          <ul>
      };
      for (sort { $a cmp $b } @{$sets_by_chars->[0]}) {
        pf q{<li><a href="/set/%s">%s</a>},
            percent_encode_c $_, htescape $_;
      }
      p q{</ul></section>};
    }

    my $maps = Charinfo::Map->get_maps_by_char (ord $char[0]);
    if (@$maps) {
      p q{
        <section class=set-list>
          <h1>Maps</h1>
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
       <td><a href="https://wiki.suikawiki.org/n/%s"><code class=charname>%s</code></a> <button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy</button>},
      percent_encode_c ($names->{name} // $names->{label}),
      htescape ($names->{name} // $names->{label})
          if defined $names->{name} or defined $names->{label};
  my @alias;
  for (@{Charinfo::Name->alias_types}) {
    for my $name (keys %{$names->{$_}}) {
      push @alias, sprintf q{<a href="https://wiki.suikawiki.org/n/%s"><code class="charname name-alias-%s">%s</code></a> <button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy</button>},
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
    pf q{<tr><th>Japanese name<td lang=ja><data>%s</data><button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy</button>}, htescape $names->{ja_name};
  }
} # char_names

sub top ($$) {
  my $locale = $_[1];
  pf q{<!DOCTYPE html><html lang="%s" class=set-info><head>
      <meta name="google-site-verification" content="tE5pbEtqbJu0UKbNCIsW2gUzW5bWGhvCwpwynqEIBRs" />
      <title>%s - SuikaWiki</title>},
      htescape $locale->lang,
      htescape $locale->text ('chars');
  p q{<link rel=canonical href="https://chars.suikawiki.org/">
      <link rel=alternate hreflang=x-default href="https://chars.suikawiki.org/">};
  for (@{$locale->avail_langs}) {
    pf q{<link rel=alternate href="https://%s.chars.suikawiki.org/" hreflang="%s">},
        htescape $_, htescape $_;
  }
  p q{<link rel=stylesheet href=/css>
<meta name="viewport" content="width=device-width,initial-scale=1">
<h1 class=site><a href="/">Chars</a>.<a href="https://suikawiki.org/"><img src="https://wiki.suikawiki.org/images/sw.png" alt=SuikaWiki.org></a></h1>};

  pf q{<h1>%s</h1>}, htescape $locale->text ('chars');

  pf q{
    <div class=has-ads>
      <menu>
        <li><a href="/char">%s</a>
        <li><a href="/seq">Character sequences</a>
        <li><a href="/string">%s</a>
          <form action=/string method=get>
            <p><input type=search name=s placeholder=String><button type=submit>%s</button>
          </form>
        <li><a href="/set">%s</a>
        <li><a href="/map">%s</a>
        <li><a href="/keys">Key to character mappings</a>
      </menu>
  },
      htescape $locale->text ('chars'),
      htescape $locale->text ('strings'),
      htescape $locale->text ('go'),
      htescape $locale->text ('sets'),
      htescape $locale->text ('maps');
  __PACKAGE__->ads;
  p q{
    </div>
  };
  __PACKAGE__->footer;
} # top

sub set ($$$) {
  my (undef, $app, $expr) = @_;
  my $has_ads = not $expr =~ /\[/;
  $has_ads = 1 if $expr =~ m{^\[\\u\{[0-9A-Fa-f]+\}-\\u\{[0-9A-Fa-f]+\}\]$};

  my $set = eval { Charinfo::Set->evaluate_expression ($expr) };
  unless (defined $set) {
    $app->http->set_status (400);
    $has_ads = 0;
  }

  my $is_set = $expr =~ /\A\$[0-9A-Za-z_.:-]+\z/;
  my $def = $is_set ? Charinfo::Set->get_set_def ($expr) : undef;

  __PACKAGE__->header (title => 'Character set "'.($def->{label} // $expr).'"',
                       class => 'set-info');
  p q{<h1>Character set</h1>};

  if (not defined $set) {
    pf q{<p>Expression error: %s}, htescape $@;
    __PACKAGE__->footer;
    return;
  }

  pf q{<section id=set class="%s"><h2>Set</h2><dl>},
      $has_ads ? 'has-ads' : '';

  if ($is_set) {
    pf q{<dt>Name<dd><span>%s</span> <button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy</button>}, $def->{label};
  }

  my $orig = htescape $expr;
  $orig =~ s{(\$[0-9A-Za-z0-9:_.-]+)}{sprintf '<a href="/set/%s">%s</a>', percent_encode_c $1, $1}ge;
  pf q{<dt>Original expression<dd><code>%s</code> <button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy</button>}, $orig;

  my $normalized = Charinfo::Set->serialize_set ($set);
  pf q{<dt>Normalized<dd><code>%s</code> <button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy</button>},
      htescape $normalized;
  pf q{<dt>Perl<dd><code>%s</code> <button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy</button>},
      htescape +Charinfo::Set->serialize_set_for_perl ($set);

  p q{</dl>};

  pf q{
    <form action=/string method=get>
      <input type=hidden name=set value="%s">
      <p><label>Test a string: <input type=search name=s required></label>
      <button type=submit>Show</button>
    </form>
  }, htescape $expr;

  pf q{
    <form action=/set/compare method=get>
      <input type=hidden name=expr value="%s">
      <p><label>Compare with: <input type=search name=expr required></label>
      <button type=submit>Show</button>
    </form>
  }, htescape $expr;

  pf q{<p><a href="/set?expr=-%s">Complemetary</a></p>},
      htescape percent_encode_c $normalized;

  if ($is_set) {
    pf q{<p>[<a href="https://wiki.suikawiki.org/n/%s">Notes</a>] },
        percent_encode_c $def->{suikawiki_name};
    if (defined $def->{spec}) {
      if ($def->{spec} =~ /^RFC([0-9]+)$/) {
        pf q{[<a href="https://tools.ietf.org/html/rfc%d">%s</a>] },
            $1, $def->{spec};
      } else {
        pf q{[%s] }, $def->{spec};
      }
    } elsif (defined $def->{url}) {
      pf q{[<a href="%s">Official</a>] }, htescape $def->{url};
    }
  }

  p q{<p><em>The set definition is contained in <a href="https://github.com/manakai/data-chars/blob/master/data/sets.json"><code>sets.json</code></a> data file.</em>}
      if $is_set;

  __PACKAGE__->ads if $has_ads;
  p q{</section>};

  my $count = 0;
  for my $range (@$set) {
    $count += $range->[1] - $range->[0] + 1;
  }
  pf q{<section id=chars><h2>Characters (%d)</h2>}, $count;
  p q{<ul class=seq-list>};
  if (@$set == 1 and $set->[0]->[1] - $set->[0]->[0] > 256) {
    $set = [[$set->[0]->[0], $set->[0]->[0] + 255],
            [$set->[0]->[0] + 256, $set->[0]->[1]]];
  }
  for my $range (@$set) {
    p ucode_range $range, max => 255, prefix => '<li>', suffix => '';
  }
  p q{</ul>};

  if (@$set == 1 and $set->[1] - $set->[0] < 256) {
    p q{<table id=chars-table><thead><tr><th>Code point<th>Character<th>Name<tbody>};
    for my $cp ($set->[0]->[0]..$set->[0]->[1]) {
      my $names = Charinfo::Name->char_code_to_names ($cp);
      pf q{<tr onclick=" querySelector('a').click () "><td><a href=/char/%04X onclick=" event.stopPropagation () ">U+%04X</a><td><code class=char>%s</code><td><code class=charname>%s</code>},
          $cp, $cp, htescape (chr $cp),
          htescape ($names->{name} // $names->{label});
    }
    p q{</table>};
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
<meta name="viewport" content="width=device-width,initial-scale=1">
<h1 class=site><a href="/">Chars</a>.<a href="//suikawiki.org/"><img src="//suika.suikawiki.org/~wakaba/-temp/2004/sw" alt=SuikaWiki.org></a></h1>};

  p q{<h1>Character set &mdash; compare</h1>};

  my $set1 = eval { Charinfo::Set->evaluate_expression ($expr1) };
  if (not defined $set1) {
    pf q{<p>Expression error (expr1): %s}, htescape $@;
    return;
  }
  my $set2 = eval { Charinfo::Set->evaluate_expression ($expr2) };
  if (not defined $set2) {
    pf q{<p>Expression error (expr2): %s}, htescape $@;
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

sub set_compare_multiple ($$) {
  my $exprs = $_[1];

  p q{<!DOCTYPE html><html lang=en class=set-info>
      <title>Compare character sets</title>};
  p q{<link rel=stylesheet href=/css>
<meta name="viewport" content="width=device-width,initial-scale=1">
<h1 class=site><a href="/">Chars</a>.<a href="//suikawiki.org/"><img src="//suika.suikawiki.org/~wakaba/-temp/2004/sw" alt=SuikaWiki.org></a></h1>};

  p q{<h1>Character sets</h1>};

  my @set;
  for my $expr (@$exprs) {
    push @set, scalar eval { Charinfo::Set->evaluate_expression ($expr) };
    if (not defined $set[-1]) {
      pf q{<p>Expression error (<code>%s</code>): %s},
          htescape $expr, htescape $@;
      return;
    }
  }

  p q{<section><h1>Sets</h1><dl>};
  for my $i (0..$#$exprs) {
    pf q{<dt>Set #%d<dd><a href="/set?expr=%s">%s</a>},
        $i, percent_encode_c $exprs->[$i], htescape $exprs->[$i];
  }
  p q{</dl></section>};

  p q{<section class=set-comparison><h1>Comparison</h1><table><thead><tr><th>};

  my $boundaries = {0 => 0b10, 0x10FFFF => 0b01};
  for my $set (@set) {
    for my $range (@$set) {
      $boundaries->{$range->[0] - 1} |= 0b01;
      $boundaries->{$range->[0]} |= 0b10;
      $boundaries->{$range->[1]} |= 0b01;
      $boundaries->{$range->[1] + 1} |= 0b10;
    }
  }
  delete $boundaries->{0 - 1};
  delete $boundaries->{0x10FFFF + 1};
  my $boundary_list = [sort { $a <=> $b } keys %$boundaries];
  my @range;
  while (@$boundary_list) {
    my $b1 = shift @$boundary_list;
    if ($boundaries->{$b1} & 0b01) {
      push @range, [$b1, $b1];
    } else {
      my $b2 = shift @$boundary_list // die;
      push @range, [$b1, $b2];
    }
  }

  for (0..$#$exprs) {
    pf q{<th>#%d}, $_;
  }
  p q{<tbody>};

  for my $range (@range) {
    pf q{<tr><th>%s}, ucode_range $range, max => 5,
        prefix => ' <span class=code-item>', suffix => '</span>';
    for (0..$#$exprs) {
      my $st = $set[$_];
      if (@$st and
          ($st->[0]->[0] <= $range->[0] and $range->[1] <= $st->[0]->[1])) {
        p q{<td class=in-set>&#x2714;};
      } else {
        p q{<td class=not-in-set>-};
      }
      shift @$st if @$st and $st->[0]->[1] <= $range->[0];
    }
  }

  p q{</table></section>};

  __PACKAGE__->footer;
} # set_compare_multiple

sub char_top ($) {
  __PACKAGE__->header (title => 'Characters', class => 'char-top');
  p q{<h1>Characters</h1>

  <menu class=toc data-sections="body > section"></menu>};

  for my $plane (0..0x10) {
    pf q{<section id="plane-%d"><h1>Plane %d</h1><ul>}, $plane, $plane;

    for my $row (0x00..0xFF) {
      pf q{<li><a href="/set/%02X%%3F%%3F"><code class=char-range>U+%02X<var>??</var></code></a>},
          $plane * 0x100 + $row, $plane * 0x100 + $row;
    }

    p q{</ul></section>};
  }
  __PACKAGE__->footer;
} # set_list

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
        <h1>Variables</h1>
        <menu class=toc data-sections="#variables > section"></menu>
  };
  my $cat = '';
  for (sort { $a cmp $b } @{Charinfo::Set->get_set_list}) {
    /^\$([^:]+)/;
    unless ($cat eq $1) {
      pf q{</ul></section>} unless $cat eq '';
      $cat = $1;
      pf q{<section id="sets-%s"><h1><a href="#sets-%s" rel=bookmark>%s</a></h1><ul>},
          htescape $cat,
          htescape $cat,
          htescape $cat;
    }
    pf q{<li><a href="/set/%s">%s</a>},
        percent_encode_c $_, htescape $_;
  }
  p q{
          </ul>
        </section>
      </section>

      <p><em>The set definitions are taken from the <a
      href="https://github.com/manakai/data-chars/blob/master/data/sets.json"><code>sets.json</code></a>
      data file.  (<a
      href="https://github.com/manakai/data-chars/blob/master/doc/sets.txt">documentation</a>)</em>

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

sub seq_list ($) {
  __PACKAGE__->header (title => 'Character sequences', class => 'seq-info');
  p q{<h1>Character sequences</h1>};
  p q{
    <form action=/string>
      <label>String:
        <input type=text name=s>
      </label>
      <button type=submit>Show</button>
    </form>

    <section>
      <h1>List of sequences</h1>

      <p><em>The list of known character sequences is available in the <a href="https://github.com/manakai/data-chars/blob/master/data/seqs.json"><code>seqs.json</code></a> data file (<a href="https://github.com/manakai/data-chars/blob/master/doc/seqs.txt">documentation</a>).</em>

      <menu class=toc data-sections=".seq-list > section"></menu>

      <div class="seq-list">
  };
  my $code = -1;
  for (@{Charinfo::Seq->seqs}) {
    my $current_code = int ((ord substr $_, 0, 1) / 0x100);
    if ($code != $current_code) {
      p q{</ul></section>} unless $code == -1;
      $code = $current_code;
      pf q{<section id="U+%02Xhh"><h1><a href="/set/%02X%%3F%%3F"><code class=char-range>U+%02X<var>??</var></code></a> <var>...</var></h1><ul>}, $code, $code, $code;
    }
    pf q{<li><a href="/string?s=%s"><bdo>%s</bdo></a> %s},
        percent_encode_c $_, htescape $_,
        ucode_list $_;
  }
  p q{
      </ul></section></div>
    </section>
  };
  __PACKAGE__->footer;
} # seq_list

sub key_set_list ($$) {
  __PACKAGE__->header (title => 'Key to character mappings', class => 'key-set-info');
  p q{<h1>Key to character mappings</h1><section class=has-ads>};
  __PACKAGE__->ads;
  p q{
      <p><em>The list of known character sequences is available in the <a href="https://github.com/manakai/data-chars/blob/master/data/keys.json"><code>keys.json</code></a> data file (<a href="https://github.com/manakai/data-chars/blob/master/doc/keys.txt">documentation</a>).</em>

      <ul>
  };
  for (@{Charinfo::Keys->key_set_names}) {
    pf q{<li><a href="/keys/%s">%s</a>},
        percent_encode_c $_, htescape $_;
  }
  p q{
      </ul>
    </section>
  };
  __PACKAGE__->footer;
} # key_set_list

sub key_set ($$$) {
  my $app = $_[1];
  my $set_name = $_[2];
  my $set = Charinfo::Keys->key_set ($set_name);
  unless (defined $set) {
    $app->http->set_status (404);
    __PACKAGE__->header (title => 'Key to character mapping "'.$set_name.'"');
    p q{<h1>Key to character mapping</h1>};
    pf q{<p>Key set <code>%s</code> not found.},
        htescape $set_name;
    __PACKAGE__->footer;
    return;
  }

  __PACKAGE__->header (title => 'Key to character mapping "'.$set_name.'"', class => 'key-set');
  pf q{<h1>Key to character mapping "%s"</h1>}, htescape $set_name;
  p q{
    <menu class=toc data-sections=".key-set > section"></menu>
    <section class=has-ads>
      <h1>Key set</h1>
  };
  __PACKAGE__->ads;
  pf q{
    <dl>
    <dt>Identifier<dd><code>%s</code>
    <dt>Name<dd>%s
    </dl>
    <p>
  }, htescape $set_name, htescape $set->{label};
  pf q{[<a href="https://wiki.suikawiki.org/n/%s">Notes</a>]},
      $set->{sw} // $set->{name};
  if (defined $set->{url}) {
    pf q{ [<a href="%s">Source</a>]}, htescape $set->{url};
  }
  p q{</section>};

  if (keys %{$set->{key_to_char} or {}}) {
    p q{<section id=key_to_char><h1>To a character</h1>
      <main>
        <ul>
    };
    for my $key (sort { $a cmp $b } keys %{$set->{key_to_char}}) {
      pf q{<li><code>%s</code>
             <span class=char-item><a href="/char/%04X"><bdo>%s</bdo></a> <span class=code-points>%s</span></span>},
          htescape $key,
          hex $set->{key_to_char}->{$key},
          chr hex $set->{key_to_char}->{$key},
          ucode hex $set->{key_to_char}->{$key};
    }
    p q{</ul></main></section>};
  }

  if (keys %{$set->{key_to_seq} or {}}) {
    p q{<section id=key_to_seq><h1>To characters</h1>
      <main>
        <ul>
    };
    for my $key (sort { $a cmp $b } keys %{$set->{key_to_seq}}) {
      my $s = join '', map { chr hex $_ } split / /, $set->{key_to_seq}->{$key};
      pf q{<li><code>%s</code>
             <span class=char-item><a href="/string?s=%s"><bdo>%s</bdo></a> <span class=code-points>%s</span></span>},
          htescape $key,
          $s, $s, ucode_list $s;
    }
    p q{</ul></main></section>};
  }

  __PACKAGE__->footer;
} # key_set

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
  pf q{<dt>Name<dd><code>%s</code> <button type=button class=copy onclick=" copyElement (previousElementSibling) ">Copy</button>},
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

  p q{<p><em>The map definition is available in the <a href="https://github.com/manakai/data-chars/blob/master/data/maps.json"><code>maps.json</code></a> data file (<a href="https://github.com/manakai/data-chars/blob/master/doc/maps.txt">documentation</a>).</em>};

  p q{<menu class=toc data-sections="body > section > section"></menu>};

  for my $x (
    [char_to_char => 'One-to-one mapping entries'],
    [char_to_seq => 'One-to-many mapping entries'],
    [seq_to_char => 'Many-to-one mapping entries'],
    [seq_to_seq => 'Many-to-many mapping entries'],
    [char_to_empty => 'Deleted characters'],
    [seq_to_empty => 'Deleted character sequences'],
  ) {
    next unless keys %{$def->{$x->[0]}};
    pf q{<section class=map-entries id="%s"><h1>%s</h1>}, $x->[0], $x->[1];
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

  p q{<section class=map-entries id=only-1><h1>Only in #1</h1>};
  print_map $diff->{only_in_1};
  p q{</section>};

  p q{<section class=map-entries id=only-2><h1>Only in #2</h1>};
  print_map $diff->{only_in_2};
  p q{</section>};

  p q{<section class=map-entries id=diff><h1>Different</h1>};
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

  p q{<section class=map-entries id=same><h1>Common</h1>};
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
  if (defined $args{canonical}) {
    pf q{<link rel=canonical href="%s">}, htescape $args{canonical};
  }
  p q{<link rel=stylesheet href=/css>
<meta name="viewport" content="width=device-width,initial-scale=1">

<script>
  function copyElement (el) {
    var hidden = el.hidden;
    if (hidden) el.hidden = false;
    var range = document.createRange ();
    range.selectNode (el);
    getSelection ().empty ();
    getSelection ().addRange (range);
    document.execCommand ('copy');
    if (hidden) el.hidden = true;
  } // copyElement
</script>

<h1 class=site><a href="/">Chars</a>.<a href="https://suikawiki.org/"><img src="https://wiki.suikawiki.org/images/sw.png" alt=SuikaWiki.org></a></h1>};
} # header

sub footer ($) {
  pf q{
    <script>
      var toc = document.querySelector ('.toc');
      if (toc)
      Array.prototype.forEach.call (document.querySelectorAll (toc.getAttribute ('data-sections')), function (section) {
        var header = section.querySelector ('h1');
        if (!header) return;
        var link = document.createElement ('a');
        link.href = '#' + encodeURIComponent (section.id);
        link.textContent = header.textContent;
        var li = document.createElement ('li');
        li.appendChild (link);
        toc.appendChild (li);
      });
    </script>

    <footer class=site>

      <p class=links><a href=/char>Characters</a>
      <a href=/seq>Sequences</a>
      <a href=/string>Strings</a>
      <a href=/set>Sets</a>
      <a href=/map>Maps</a>
      <a href=/keys>Keys</a>

      <p class=links><a href=/ rel=top>Chars.SuikaWiki.org</a>
      / <a href=https://data.suikawiki.org>Data.SuikaWiki.org</a>
      by&nbsp;<a href=https://suikawiki.org>SuikaWiki project</a>

      <p id=about>This is <a href=https://github.com/wakaba/charinfo-cgi>Charinfo</a> version <a href="https://github.com/wakaba/charinfo-cgi/commit/%s">%s</a>.

    </footer>

<script>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-39820773-3', 'suikawiki.org');
  ga('send', 'pageview');
</script>

},
    percent_encode_c $Charinfo::App::Commit,
    htescape $Charinfo::App::Commit;
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
        <script src="https://pagead2.googlesyndication.com/pagead/show_ads.js"></script>
        <p><script src="https://www.gstatic.com/xads/publisher_badge/contributor_badge.js" data-width="300" data-height="62" data-theme="white" data-pub-name="SuikaWiki" data-pub-id="ca-pub-6943204637055835"></script>
      </aside>
  };
} # ads

1;

=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 LICENSE

Copyright 2011-2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
