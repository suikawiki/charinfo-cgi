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
use Web::URL;
use Web::Transport::BasicClient;
use Sarze;

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


{
  use Socket;
  sub _can_listen ($) {
    my $port = $_[0] or return 0;
    my $proto = getprotobyname ('tcp');
    socket (my $server, PF_INET, SOCK_STREAM, $proto) or die "socket: $!";
    setsockopt ($server, SOL_SOCKET, SO_REUSEADDR, pack ("l", 1))
        or die "setsockopt: $!";
    bind ($server, sockaddr_in($port, INADDR_ANY)) or return 0;
    listen ($server, SOMAXCONN) or return 0;
    close ($server);
    return 1;
  } # _can_listen

  sub find_port () {
    my $used = {};
    for (1..10000) {
      my $port = int rand (5000 - 1024); # ephemeral ports
      next if $used->{$port};
      return $port if _can_listen $port;
      $used->{$port}++;
    }
    die "Listenable port not found";
  } # find_port
}

my $RootPath = path (__FILE__)->parent->parent->parent->absolute;
my $Client;

push @EXPORT, 'RUN';
sub RUN () {
  my $url = Web::URL->parse_string ("http://0.0.0.0:" . find_port);
  $Client = Web::Transport::BasicClient->new_from_url ($url);
  my $server;
  Sarze->start
      (max_worker_count => 1,
       hostports => [[$url->host->to_ascii, $url->port]],
       psgi_file_name => $RootPath->child ('server.psgi'))->then (sub {
    warn sprintf "Server: <%s>\n", $url->stringify;
    $server = $_[0];
  })->to_cv->recv;
  run_tests;
  $Client->close->then (sub {
    undef $Client;
    return $server->stop;
  })->to_cv->recv;
} # RUN

push @EXPORT, qw(CLIENT);
sub CLIENT () { $Client }

1;

=head1 LICENSE

Copyright 2015-2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
