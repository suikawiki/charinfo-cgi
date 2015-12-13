package Charinfo::Number;
use strict;
use warnings;
use JSON::Functions::XS qw(json_bytes2perl);
use Path::Class;

my $values_file = file (__FILE__)->dir->parent->parent->file ('local/number-values.json');
my $values_data = json_bytes2perl scalar $values_file->slurp;

sub char_to_cjk_numeral ($$) {
  return $values_data->{$_[1]}->{cjk_numeral}; # or undef
} # char_to_cjk_numeral

1;


=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 LICENSE

Copyright 2015 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
