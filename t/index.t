use strict;
use warnings;
use Path::Tiny;
use lib path (__FILE__)->parent->parent->child ('t_deps/lib')->stringify;
use Tests;

my $server = web_server;

test {
  my $c = shift;
  my $host = $c->received_data->{host};
  GET ($c, '/')->then (sub {
    my $res = $_[0];
    test {
      is $res->code, 200;
      is $res->header ('Content-Type'), q{text/html; charset=utf-8};
      like $res->content, qr{About charinfo};
    } $c;
    done $c;
    undef $c;
  });
} wait => $server, n => 3;

run_tests;
stop_servers;

=head1 LICENSE

Copyright 2015 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
