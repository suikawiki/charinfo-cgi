package Charinfo::App;
use strict;
use warnings;
use Path::Tiny;

my $rev_path = path (__FILE__)->parent->parent->parent->child ('rev');

our $Commit = $rev_path->is_file ? $rev_path->slurp : `git rev-parse HEAD`;
$Commit =~ s/[^0-9A-Za-z]+//g;

1;

=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 LICENSE

Copyright 2011-2015 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
