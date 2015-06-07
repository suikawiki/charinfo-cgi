package Tests;
use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/modules/*/lib');
use Test::More;
use Test::X1;
use AnyEvent;
use Promise;
use Promised::Plackup;
use Web::UserAgent::Functions qw(http_get);

our @EXPORT;
push @EXPORT, grep { not /^\$/ } @Test::More::EXPORT;
push @EXPORT, @Test::X1::EXPORT;

sub import ($;@) {
  my $from_class = shift;
  my ($to_class, $file, $line) = caller;
  no strict 'refs';
  for (@_ ? @_ : @{$from_class . '::EXPORT'}) {
    my $code = $from_class->can ($_)
        or die qq{"$_" is not exported by the $from_class module at $file line $line};
    *{$to_class . '::' . $_} = $code;
  }
} # import

my $HTTPServer;

my $root_path = path (__FILE__)->parent->parent->parent->absolute;

push @EXPORT, qw(web_server);
sub web_server (;$) {
  my $web_host = $_[0];
  my $cv = AE::cv;
  $HTTPServer = Promised::Plackup->new;
  $HTTPServer->plackup ($root_path->child ('plackup'));
  $HTTPServer->set_option ('--host' => $web_host) if defined $web_host;
  $HTTPServer->set_option ('--app' => $root_path->child ('server.psgi'));
  $HTTPServer->set_option ('--server' => 'Twiggy::Prefork');
  $HTTPServer->start->then (sub {
    $cv->send ({host => $HTTPServer->get_host});
  });
  return $cv;
} # web_server

push @EXPORT, qw(stop_servers);
sub stop_servers () {
  my $cv = AE::cv;
  $cv->begin;
  for ($HTTPServer) {
    next unless defined $_;
    $cv->begin;
    $_->stop->then (sub { $cv->end });
  }
  $cv->end;
  $cv->recv;
} # stop_servers

push @EXPORT, qw(GET);
sub GET ($$;%) {
  my ($c, $path, %args) = @_;
  my $host = $c->received_data->{host};
  return Promise->new (sub {
    my ($ok, $ng) = @_;
    http_get
        url => qq<http://$host$path>,
        basic_auth => $args{basic_auth},
        header_fields => $args{header_fields},
        params => $args{params},
        timeout => 30,
        anyevent => 1,
        max_redirect => 0,
        cb => sub {
          $ok->($_[1]);
        };
  });
} # GET

1;

=head1 LICENSE

Copyright 2015 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
