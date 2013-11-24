package Charinfo::Name;
use strict;
use warnings;
use Path::Class;

my $CodeToNames;
my $NameToCode;
BEGIN {
  my $data_f = file (__FILE__)->dir->parent->parent->subdir ('data')->file ('names.pl');
  my $data = do $data_f or die $@;
  $CodeToNames = $data->[0];
  $NameToCode = $data->[1];
}

my @L = ("G", "GG", "N", "D", "DD", "R", "M", "B", "BB", "S", "SS", "", "J", "JJ", "C", "K", "T", "P", "H");
my %L = map { $L[$_] => $_ } 0..$#L;
my @V = ("A", "AE", "YA", "YAE", "EO", "E", "YEO", "YE", "O", "WA", "WAE", "OE", "YO", "U", "WEO", "WE", "WI", "YU", "EU", "YI", "I");
my %V = map { $V[$_] => $_ } 0..$#V;
my @T = ("", "G", "GG", "GS", "N", "NJ", "NH", "D", "L", "LG", "LM", "LB", "LS", "LT", "LP", "LH", "M", "B", "BS", "S", "SS", "NG", "J", "C", "K", "T", "P", "H");
my %T = map { $T[$_] => $_ } 0..$#T;

sub hangul_name_to_code ($$) {
  my $name = $_[1];
  return undef unless $name =~ /\AHANGUL SYLLABLE ([^AEIOUWY]*)([AEIOUWY]+)([^AEIOUWY]*)\z/;
  my ($l, $v, $t) = ($L{$1}, $V{$2}, $T{$3});
  return undef unless defined $l and defined $v and defined $t;
  return 0xAC00 + $l * (@V * @T) + $v * @T + $t;
} # hangul_name_to_code

sub hangul_code_to_name ($$) {
  my $code = $_[1];
  return undef unless 0xAC00 <= $code and $code <= 0xD7A3;
  $code -= 0xAC00;
  my $l = int ($code / (@V * @T));
  my $v = int (($code % (@V * @T)) / @T);
  my $t = $code % @T;
  return 'HANGUL SYLLABLE ' . $L[$l].$V[$v].$T[$t];
} # hangul_code_to_name

sub char_name_to_code ($$) {
  my $name = $_[1];
  my $code = $NameToCode->{$name};
  return $code if defined $code;
  if ($name =~ /\ACJK UNIFIED IDEOGRAPH-([0-9A-F]{4,5})\z/) {
    my $code = hex $1;
    if ((0x3400 <= $code and $code <= 0x4DB5) or # Ext A
        (0x4E00 <= $code and $code <= 0x9FCC) or
        (0x20000 <= $code and $code <= 0x2A6D6) or # Ext B
        (0x2A700 <= $code and $code <= 0x2B734) or # Ext C
        (0x2F800 <= $code and $code <= 0x2B81D)) { # Ext D
      return $code;
    }
  } elsif ($name =~ /^HANGUL SYLLABLE /) {
    return $_[0]->hangul_name_to_code ($name);
  } elsif ($name =~ /\Aprivate-use-(E[0-9A-F]{3}|F[0-8][0-9A-F]{2}|(?:F|10)(?!FFF[EF])[0-9A-F]{4})\z/) {
    return hex $1;
  } elsif ($name =~ /\Asurrogate-(D[8-F][0-9A-F]{2})\z/) {
    return hex $1;
  } elsif ($name =~ /\Anoncharacter-(FD[DE][0-9A-F]|[1-9A-F]?FFF[EF]|10FFF[EF])\z/) {
    return hex $1;
  } elsif ($name =~ /\Acontrol-(00[0189][0-9A-F]|007F)\z/) {
    return hex $1;
  }
  return undef;
} # char_name_to_code

sub char_code_to_names ($$) {
  my $code = $_[1];
  my $names = $CodeToNames->{$code};
  return $names if $names and defined $names->[0];
  my $name;
  if ((0x3400 <= $code and $code <= 0x4DB5) or # Ext A
      (0x4E00 <= $code and $code <= 0x9FCC) or
      (0x20000 <= $code and $code <= 0x2A6D6) or # Ext B
      (0x2A700 <= $code and $code <= 0x2B734) or # Ext C
      (0x2F800 <= $code and $code <= 0x2B81D)) { # Ext D
    $name = sprintf 'CJK UNIFIED IDEOGRAPH-%04X', $code;
  } elsif (0xAC00 <= $code and $code <= 0xD7A3) {
    $name = $_[0]->hangul_code_to_name ($code);
  } elsif ((0xFDD0 <= $code and $code <= 0xFDEF) or
           ((($code % 0x10000) == 0xFFFE or ($code % 0x10000 == 0xFFFF)) and
            $code <= 0x10FFFF)) {
    $name = sprintf 'noncharacter-%04X', $code;
  } elsif ((0xE000 <= $code and $code <= 0xF8FF) or
           (0xF0000 <= $code and $code <= 0xFFFFD) or
           (0x100000 <= $code and $code <= 0x10FFFD)) {
    $name = sprintf 'private-use-%04X', $code;
  } elsif (0xD800 <= $code and $code <= 0xDFFF) {
    $name = sprintf 'surrogate-%04X', $code;
  } elsif ((0x0000 <= $code and $code <= 0x001F) or
           $code == 0x007F or
           (0x0080 <= $code and $code <= 0x009F)) {
    $name = sprintf 'control-%04X', $code;
  }
  return [grep { defined $_ } ($name, @{$names or []})];
} # char_code_to_names

1;

=head1 LICENSE

Copyright 2013 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
