package Charinfo::Map;
use strict;
use warnings;
use Path::Class;
use JSON::Functions::XS qw(file2perl);

my $Maps;
BEGIN {
  my $maps = file2perl file (__FILE__)->dir->parent->parent->file ('local', 'maps.json');
  $Maps = $maps->{maps};
}

sub get_list ($) {
  return [keys %$Maps];
} # get_list

sub get_maps_by_char ($$) {
  my $c = sprintf '%04X', $_[1];
  my @map;
  for (@{__PACKAGE__->get_list}) {
    my $def = __PACKAGE__->get_def_by_name ($_);
    if ($def->{char_to_char}->{$c} or
        $def->{char_to_seq}->{$c} or
        $def->{char_to_empty}->{$c}) {
      push @map, $_;
    }
  }
  return \@map;
} # get_maps_by_char

sub get_def_by_name ($$) {
  my (undef, $name) = @_;
  return $Maps->{$name}; # or undef
}

sub get_diff ($$$) {
  my (undef, $name1, $name2) = @_;
  my $def1 = __PACKAGE__->get_def_by_name ($name1) or return undef;
  my $def2 = __PACKAGE__->get_def_by_name ($name2) or return undef;
  my $map1 = {};
  my $map2 = {};
  for my $key (qw(char_to_char char_to_empty char_to_seq
                  seq_to_char seq_to_empty seq_to_seq)) {
    $map1->{$_} = $def1->{$key}->{$_} for keys %{$def1->{$key} or {}};
    $map2->{$_} = $def2->{$key}->{$_} for keys %{$def2->{$key} or {}};
  }

  my $only1 = {};
  my $only2 = {};
  my $changed = {};
  my $common = {};
  for (keys %$map1) {
    if (defined $map1->{$_} and defined $map2->{$_}) {
      if ($map1->{$_} eq $map2->{$_}) {
        $common->{$_} = $map1->{$_};
      } else {
        $changed->{$_} = [$map1->{$_}, $map2->{$_}];
      }
    } else {
      $only1->{$_} = $map1->{$_};
    }
  }
  for (keys %$map2) {
    if (not defined $map1->{$_}) {
      $only2->{$_} = $map2->{$_};
    }
  }
  return {only_in_1 => $only1, only_in_2 => $only2,
          same => $common, different => $changed};
} # get_diff

1;

=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
