package Charinfo::Encoding;
use strict;
use warnings;
no warnings 'utf8';
use integer;
use Path::Tiny;
use JSON::Functions::XS qw(json_bytes2perl);

BEGIN {
  my $data = json_bytes2perl path (__FILE__)->parent->parent->parent->child
      ('local/indexes.json')->slurp;
  for my $index (keys %$data) {
    next unless $index eq 'jis0208' or $index eq 'jis0212';
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

1;

=head1 LICENSE

Copyright 2013 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
