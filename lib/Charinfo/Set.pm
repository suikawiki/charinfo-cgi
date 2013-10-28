package Charinfo::Set;
use strict;
use warnings;

sub set_merge ($$) {
  my ($s1, $s2) = @_;
  my $result = [];
  my @range = sort { $a->[0] <=> $b->[0] } @$s1, @$s2;
  while (1) {
    if (@range <= 1) {
      push @$result, @range;
      last;
    }
    my $start = $range[0]->[0];
    my $end = (shift @range)->[1];
    while (2) {
      last if $end + 1 < $range[0]->[0];
      $end = $range[0]->[1] if $end < $range[0]->[1];
      shift @range;
      last unless @range;
    }
    push @$result, [$start, $end];
  }
  return $result;
} # set_merge

sub set_minus ($$) {
  my ($s1, $s2) = @_;
  my $result = [[-1, -1, 0]];
  my @def = sort { $a->[0] <=> $b->[0] || $a->[2] <=> $b->[2] }
      (map { [@$_, 0] } @$s1), (map { [@$_, 1] } @$s2);
  my $minus_end = -1;
  while (@def) {
    my $range = shift @def;
    if ($range->[2]) { # minus
      if ($result->[-1]->[0] <= $range->[0] and
          $range->[0] <= $result->[-1]->[1]) {
        if ($range->[0] <= $result->[-1]->[0]) {
          $result->[-1]->[0] = $range->[1] + 1;
          pop @$result unless $result->[-1]->[0] <= $result->[-1]->[1];
        } else { # $result->[-1]->[0] < $range->[0]
          if ($range->[0] <= $result->[-1]->[1]) {
            if ($range->[1] < $result->[-1]->[1]) {
              my $new_range = [$range->[1] + 1, $result->[-1]->[1]];
              if ($new_range->[0] <= $new_range->[1]) {
                unshift @def, $new_range;
                @def = sort { $a->[0] <=> $b->[0] || $a->[2] <=> $b->[2] } @def;
              }
            }
            $result->[-1]->[1] = $range->[0] - 1;
            pop @$result unless $result->[-1]->[0] <= $result->[-1]->[1];
          }
        }
      }
      $minus_end = $range->[1];
    } else {
      if ($range->[0] == $minus_end) {
        push @$result, [$minus_end + 1, $range->[1]]
            if $minus_end + 1 < $range->[1];
      } elsif ($range->[0] < $minus_end and $minus_end < $range->[1]) {
        push @$result, [$range->[0], $minus_end - 1],
            if $range->[0] < $minus_end - 1;
      } elsif ($range->[1] <= $minus_end) {
        #
      } else { # $minus_end < $range->[0]
        push @$result, $range;
      }
    }
  } # @def
  shift @$result; # [-1, -1, 0]
  return [map { [$_->[0], $_->[1]] } @$result];
} # set_minus

sub get_set ($) {
  return undef;
} # get_set

sub evaluate_expression ($$) {
  my $input = $_[1];
  my $current = [];

  my $op = '|';
  if ($input =~ s/^\s*-//) {
    $current = [[0x0000, 0x10FFFF]];
    $op = '-';
  }
  while (length $input) {
    if ($input =~ s/^\s*\[([^\[\]]*)\]//) {
      my $chars = $1;
      my $set = [];
      push @$set, [ord '-', ord '-'] if $chars =~ s/\A-//;
      push @$set, [ord '-', ord '-'] if $chars =~ s/-\z//;
      die "Bad range\n" if $chars =~ /\A-/ or $chars =~ /-\z/;
      my $in_range;
      while (length $chars) {
        my $code;
        if ($chars =~ s/^\\u([0-9A-Fa-f]{4})//) {
          $code = hex $1;
        } elsif ($chars =~ s/^\\u\{([0-9A-Fa-f]+)\}//) {
          $code = hex $1;
        } elsif ($chars =~ s/^\\U([0-9A-Fa-f]{8})//) {
          $code = hex $1;
        } elsif ($chars =~ s/^\\\\//) {
          $code = 0x5C;
        } elsif ($chars =~ s/^\\//) {
          die "Broken escape\n";
        } elsif ($chars =~ s/^-//) {
          die "Broken range\n" if $in_range;
          $in_range = 1;
          next;
        } elsif ($chars =~ s/^\^//) {
          die "Bad ^\n";
        } elsif ($chars =~ s/^\s+//) {
          next;
        } elsif ($chars =~ s/^(.)//s) {
          $code = ord $1;
        } else {
          die "Somewhat broken\n";
        }
        if ($in_range) {
          die "Broken range\n" if $set->[-1]->[0] > $code;
          $set->[-1]->[1] = $code;
          $in_range = 0;
        } else {
          push @$set, [$code, $code];
        }
      }
      if ($op eq '|') {
        $current = set_merge $set, $current;
      } elsif ($op eq '-') {
        $set = set_merge $set, [];
        $current = set_minus $current, $set;
      } else {
        die "Unknown operation |$op|\n";
      }
      undef $op;
    } elsif ($input =~ s/^\s*\$([0-9A-Za-z_.:-]+)//) {
      my $set = get_set $1 or die "Unknown set |\$$1|";
      if ($op eq '|') {
        $current = set_merge $set, $current;
      } elsif ($op eq '-') {
        $current = set_minus $current, $set;
      } else {
        die "Unknown operation |$op|\n";
      }
      undef $op;
    } elsif ($input =~ s/^\s*([|-])//) {
      die "Bad operator\n" if defined $op;
      $op = $1;
    } elsif ($input =~ s/^\s*$//) {
      #
    } else {
      die "Bad input -> |$input|\n";
    }
  }
  die "Set expected\n" if defined $op;

  return $current;
} # evaluate_expression

1;

=head1 LICENSE

Copyright 2013 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
