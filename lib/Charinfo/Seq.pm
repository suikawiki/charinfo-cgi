package Charinfo::Seq;
use strict;
use warnings;
use Path::Tiny;
use JSON::Functions::XS;

my $RootPath = path (__FILE__)->parent->parent->parent;
my $SeqData = json_bytes2perl $RootPath->child ('local/seqs.json')->slurp;

my $Seqs = [sort { $a cmp $b } map { join '', map { chr hex $_ } split / /, $_ } keys %$SeqData];

my $CharToSeqs = {};
for my $seq (@$Seqs) {
  for (split //, $seq) {
    push @{$CharToSeqs->{ord $_} ||= []}, $seq;
  }
}

sub seqs ($) {
  return $Seqs;
} # seqs

sub seqs_by_char ($$) {
  return $CharToSeqs->{$_[1]} || [];
} # seqs_by_char

1;

=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 LICENSE

Copyright 2011-2015 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
