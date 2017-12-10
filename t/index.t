use strict;
use warnings;
use Path::Tiny;
use lib path (__FILE__)->parent->parent->child ('t_deps/lib')->stringify;
use Tests;

test {
  my $c = shift;
  CLIENT->request (path => [], headers => {'accept-language' => 'en'})->then (sub {
    my $res = $_[0];
    test {
      is $res->code, 200;
      is $res->header ('Content-Type'), q{text/html; charset=utf-8};
      like $res->content, qr{Character sequence};
    } $c;
    done $c;
    undef $c;
  });
} n => 3;

RUN;

=head1 LICENSE

Copyright 2015-2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
