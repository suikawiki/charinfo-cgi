package Charinfo::Encoding;
use strict;
use warnings;
no warnings 'utf8';
use integer;
use JSON::Functions::XS qw(file2perl);
use Path::Class;

## Spec: <https://encoding.spec.whatwg.org/>.

BEGIN {
  my $data = file2perl file (__FILE__)->dir->parent->parent->subdir ('local')->file ('indexes.json');
  for my $index (keys %$data) {
    next if $index eq 'gb18030-ranges';
    my $index_pointers = {};
    for my $i (0..$#{$data->{$index}}) {
      my $code_point = $data->{$index}->[$i];
      next unless defined $code_point;
      push @{$index_pointers->{$code_point} ||= []}, $i;
    }
    $data->{$index} = $index_pointers;
  }
  sub DATA () { $data }
} # BEGIN

sub utf8 ($) {
  my $code_point = $_[0];
  if (0xD800 <= $code_point and $code_point <= 0xDFFF) {
    return undef;
  } elsif (0x0000 <= $code_point and $code_point <= 0x007F) {
    return [[$code_point]];
  } else {
    my $count;
    my $offset;
    if (0x0080 <= $code_point and $code_point <= 0x07FF) {
      $count = 1;
      $offset = 0xC0;
    } elsif (0x0800 <= $code_point and $code_point <= 0xFFFF) {
      $count = 2;
      $offset = 0xE0;
    } elsif (0x10000 <= $code_point and $code_point <= 0x10FFFF) {
      $count = 3;
      $offset = 0xF0;
    } else {
      return undef;
    }
    my $bytes = [$code_point / 64**$count + $offset];
    while ($count > 0) {
      my $temp = $code_point / 64**($count-1);
      push @$bytes, 0x80 + ($temp % 64);
      $count--;
    }
    return [$bytes];
  }
}

sub single_byte ($$) {
  my ($index, $code_point) = @_;
  if (0x0000 <= $code_point and $code_point <= 0x007F) {
    return [[$code_point]];
  } elsif (DATA->{$index}->{$code_point}) {
    return [map { [$_ + 0x80] } @{DATA->{$index}->{$code_point}}];
  } else {
    return undef;
  }
}

sub big5 ($) {
  my $code_point = $_[0];
  if (0x0000 <= $code_point and $code_point <= 0x007F) {
    return [[$code_point]];
  } elsif (DATA->{big5}->{$code_point}) {
    return [map { [$_ / 157 + 0x81, do { my $t = $_ % 157; $t + ($t < 0x3F ? 0x40 : 0x62) }] } @{DATA->{big5}->{$code_point}}];
  } else {
    return undef;
  }
}

sub iso2022jp ($) {
  my $code_point = $_[0];
  if (0x0000 <= $code_point and $code_point <= 0x007F) {
    return [[$code_point], [0x1B, 0x28, 0x4A, $code_point, 0x1B, 0x28, 0x42]];
  } elsif ($code_point == 0x00A5) {
    return [[0x5C], [0x1B, 0x28, 0x4A, 0x5C, 0x1B, 0x28, 0x42]];
  } elsif ($code_point == 0x203E) {
    return [[0x7E], [0x1B, 0x28, 0x4A, 0x7E, 0x1B, 0x28, 0x42]];
  } elsif (0xFF61 <= $code_point and $code_point <= 0xFF9F) {
    return [[0x1B, 0x28, 0x49, $code_point - 0xFF61 + 0x21, 0x1B, 0x28, 0x42]];
  } else {
    my @r;
    if (DATA->{jis0208}->{$code_point}) {
      push @r, map {
        [0x1B, 0x24, 0x42, $_ / 94 + 0x21, $_ % 94 + 0x21, 0x1B, 0x28, 0x42],
        [0x1B, 0x24, 0x40, $_ / 94 + 0x21, $_ % 94 + 0x21, 0x1B, 0x28, 0x42]
      } @{DATA->{jis0208}->{$code_point}};
    }
    if (DATA->{jis0212}->{$code_point}) {
      push @r, map { [0x1B, 0x24, 0x28, 0x44, $_ / 94 + 0x21, $_ % 94 + 0x21, 0x1B, 0x28, 0x42] } @{DATA->{jis0212}->{$code_point}};
    }
    return @r ? \@r : undef;
  }
}

sub eucjp ($) {
  my $code_point = $_[0];
  if (0x0000 <= $code_point and $code_point <= 0x007F) {
    return [[$code_point]];
  } elsif ($code_point == 0x00A5) {
    return [[0x005C]];
  } elsif ($code_point == 0x203E) {
    return [[0x007E]];
  } elsif (0xFF61 <= $code_point and $code_point <= 0xFF9F) {
    return [[0x8E, $code_point - 0xFF61 + 0xA1]];
  } else {
    my @r;
    if (DATA->{jis0208}->{$code_point}) {
      push @r, map { [$_ / 94 + 0xA1, $_ % 94 + 0xA1] } @{DATA->{jis0208}->{$code_point}};
    }
    if (DATA->{jis0212}->{$code_point}) {
      push @r, map { [0x8F, $_ / 94 + 0xA1, $_ % 94 + 0xA1] } @{DATA->{jis0212}->{$code_point}};
    }
    return @r ? \@r : undef;
  }
}

sub shiftjis ($) {
  my $code_point = $_[0];
  if (0x0000 <= $code_point and $code_point <= 0x0080) {
    return [[$code_point]];
  } elsif ($code_point == 0x00A5) {
    return [[0x005C]];
  } elsif ($code_point == 0x203E) {
    return [[0x007E]];
  } elsif (0xFF61 <= $code_point and $code_point <= 0xFF9F) {
    return [[$code_point - 0xFF61 + 0xA1]];
  } elsif (DATA->{jis0208}->{$code_point}) {
    return [map { [do { my $l = $_ / 188; $l + ($l < 0x1F ? 0x81 : 0xC1) }, do { my $t = $_ % 188; $t + ($t < 0x3F ? 0x40 : 0x41) }] } @{DATA->{jis0208}->{$code_point}}];
  } else {
    return undef;
  }
}

sub euckr ($) {
  my $code_point = $_[0];
  if (0x0000 <= $code_point and $code_point <= 0x007F) {
    return [[$code_point]];
  } elsif (DATA->{'euc-kr'}->{$code_point}) {
    return [map {
      if ($_ < (26+26+126)*(0xC7-0x81)) {
        [$_ / (26+26+126) + 0x81, do {
          my $t = $_ % (26+26+126);
          $t + ($t < 26 ? 0x41 : $t < 26+26 ? 0x47 : 0x4D);
        }];
      } else {
        my $p = $_ - (26+26+126)*(0xC7-0x81);
        [$p / 94 + 0xC7, $p % 94 + 0xA1];
      }
    } @{DATA->{'euc-kr'}->{$code_point}}];
  } else {
    return undef;
  }
}

sub gbk ($) {
  my $code_point = $_[0];
  if (0x0000 <= $code_point and $code_point <= 0x007F) {
    return [[$code_point]];
  } elsif (DATA->{gbk}->{$code_point}) {
    return [map { [$_ / 190 + 0x81, do { my $t = $_ % 190; $t + ($t < 0x3F ? 0x40 : 0x41) }] } @{DATA->{gbk}->{$code_point}}];
  } else {
    return undef;
  }
}

sub gb18030 ($) {
  my $code_point = $_[0];
  if (0x0000 <= $code_point and $code_point <= 0x007F) {
    return [[$code_point]];
  } else {
    my $pointer = DATA->{gb18030}->{$code_point};
    if (defined $pointer) {
      return [map {
        my $lead = $_ / 190 + 0x81;
        my $trail = $_ % 190;
        my $offset = $trail < 0x3F ? 0x40 : 0x41;
        [$lead, $trail + $offset];
      } @$pointer];
    }

    my $offset;
    my $pointer_offset;
    for (@{DATA->{'gb18030-ranges'}}) {
      if ($_->[1] <= $code_point) {
        $offset = $_->[1];
        $pointer_offset = $_->[0];
      }
    }

    $pointer = $pointer_offset + $code_point - $offset;
    my $byte1 = ($pointer / 10 / 126 / 10);
    $pointer = $pointer - $byte1 * 10 * 126 * 10;
    my $byte2 = ($pointer / 10 / 126);
    $pointer = $pointer - $byte2 * 10 * 126;
    my $byte3 = ($pointer / 10);
    my $byte4 = $pointer - $byte3 * 10;
    [[$byte1 + 0x81, $byte2 + 0x30, $byte3 + 0x81, $byte4 + 0x30]];
  }
}

sub hzgb2312 ($) {
  my $code_point = $_[0];
  if ($code_point == 0x007E) {
    return [[0x7E, 0x7E]];
  } elsif (0x0000 <= $code_point and $code_point <= 0x007F) {
    return [[$code_point]];
  } elsif (DATA->{gb18030}->{$code_point}) {
    return [map {
      my $l = $_ / 190 + 1;
      my $t = $_ % 190 - 0x3F;
      ($l < 0x21 or $t < 0x21) ? () : [0x7E, 0x7B, $l, $t, 0x7E, 0x7D];
    } @{DATA->{gb18030}->{$code_point}}];
  } else {
    return undef;
  }
}

sub utf16be ($) {
  my $code_point = $_[0];
  if (0xD800 <= $code_point and $code_point <= 0xDFFF) {
    return undef;
  } elsif (0x0000 <= $code_point and $code_point <= 0xFFFF) {
    return [[$code_point >> 8, $code_point & 0xFF]];
  } else {
    my $l = ($code_point - 0x10000) / 0x400 + 0xD800;
    my $t = ($code_point - 0x10000) % 0x400 + 0xDC00;
    return [[$l >> 8, $l & 0xFF, $t >> 8, $t & 0xFF]];
  }
}

sub utf16le ($) {
  my $code_point = $_[0];
  if (0xD800 <= $code_point and $code_point <= 0xDFFF) {
    return undef;
  } elsif (0x0000 <= $code_point and $code_point <= 0xFFFF) {
    return [[$code_point & 0xFF, $code_point >> 8]];
  } else {
    my $l = ($code_point - 0x10000) / 0x400 + 0xD800;
    my $t = ($code_point - 0x10000) % 0x400 + 0xDC00;
    return [[$l & 0xFF, $l >> 8, $t & 0xFF, $t >> 8]];
  }
}

sub xud ($) {
  my $code_point = $_[0];
  if (0x0000 <= $code_point and $code_point <= 0x007F) {
    return [[$code_point]];
  } elsif (0xF780 <= $code_point and $code_point <= 0xF7FF) {
    return [[$code_point - 0xF780 + 0x80]];
  } else {
    return undef;
  }
}

my $SingleByteEncodings = {map { $_ => 1 } qw(
ibm866
iso-8859-2
iso-8859-3
iso-8859-4
iso-8859-5
iso-8859-6
iso-8859-7
iso-8859-8
iso-8859-10
iso-8859-13
iso-8859-14
iso-8859-15
iso-8859-16
koi8-r
koi8-u
macintosh
windows-874
windows-1250
windows-1251
windows-1252
windows-1253
windows-1254
windows-1255
windows-1256
windows-1257
windows-1258
x-mac-cyrillic
)}; # $SingleByteEncodings

our $EncodingNames = [qw(
utf-8
ibm866
iso-8859-2
iso-8859-3
iso-8859-4
iso-8859-5
iso-8859-6
iso-8859-7
iso-8859-8
iso-8859-8-i
iso-8859-10
iso-8859-13
iso-8859-14
iso-8859-15
iso-8859-16
koi8-r
koi8-u
macintosh
windows-874
windows-1250
windows-1251
windows-1252
windows-1253
windows-1254
windows-1255
windows-1256
windows-1257
windows-1258
x-mac-cyrillic
gb18030
hz-gb-2312
big5
euc-jp
iso-2022-jp
shift_jis
euc-kr
replacement
utf-16be
utf-16le
x-user-defined
)];

sub from_unicode ($$$) {
  my ($class, $code_point, $encoding) = @_;
  if ($SingleByteEncodings->{$encoding}) {
    return single_byte $encoding, $code_point;
  } elsif ($encoding eq 'iso-8859-8-i') {
    return single_byte 'iso-8859-8', $code_point;
  } elsif ($encoding eq 'utf-8') {
    return utf8 $code_point;
  } elsif ($encoding eq 'gb18030') {
    return gb18030 $code_point;
  } elsif ($encoding eq 'hz-gb-2312') {
    return hzgb2312 $code_point;
  } elsif ($encoding eq 'big5') {
    return big5 $code_point;
  } elsif ($encoding eq 'iso-2022-jp') {
    return iso2022jp $code_point;
  } elsif ($encoding eq 'shift_jis') {
    return shiftjis $code_point;
  } elsif ($encoding eq 'euc-jp') {
    return eucjp $code_point;
  } elsif ($encoding eq 'euc-kr') {
    return euckr $code_point;
  } elsif ($encoding eq 'utf-16be') {
    return utf16be $code_point;
  } elsif ($encoding eq 'utf-16le') {
    return utf16le $code_point;
  } elsif ($encoding eq 'x-user-defined') {
    return xud $code_point;
  } else {
    return undef;
  }
} # from_unicode

1;

=head1 LICENSE

Copyright 2013 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
