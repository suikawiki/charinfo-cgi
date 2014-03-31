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

sub get_def_by_name ($$) {
  my (undef, $name) = @_;
  return $Maps->{$name}; # or undef
}

1;

=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
