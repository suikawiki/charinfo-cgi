package Charinfo::Keys;
use strict;
use warnings;
use Path::Tiny;
use JSON::Functions::XS;

my $RootPath = path (__FILE__)->parent->parent->parent;
my $KeysData = json_bytes2perl $RootPath->child ('local/keys.json')->slurp;

sub key_set_names () {
  return [keys %{$KeysData->{key_sets}}];
} # key_set_names

sub key_set ($$) {
  return $KeysData->{key_sets}->{$_[1]};
} # key_set

1;

=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
