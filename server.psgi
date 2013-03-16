#!/usr/bin/perl
use strict;
use warnings;
no warnings 'utf8';
use Wanage::HTTP;
use Warabe::App;
use Charinfo::Main;

$Charinfo::Main::SELF_URL = '/';

sub {
  my $http = Wanage::HTTP->new_from_psgi_env ($_[0]);

  return $http->send_response (onready => sub {
    my $app = Warabe::App->new_from_http ($http);

    my $s;
    my $path = $app->path_segments;
    if ($path->[0] eq '' and not defined $path->[1]) {
      # /
      $s = $app->text_param ('s') // '';
    } elsif ($path->[0] eq 'char' and
             defined $path->[1] and $path->[1] =~ /\A[0-9A-F]+\z/ and
             not defined $path->[2]) {
      # /char/{hex}
      $s = chr hex $path->[1] if 0x7FFF_FFFF >= hex $path->[1];
    }
    $app->throw_error (404) unless defined $s;

    local $Charinfo::Main::Output = sub {
      $http->send_response_body_as_text (join '', @_);
    }; # Output
    $http->set_response_header ('Content-Type' => 'text/html; charset=utf-8');
    
    Charinfo::Main->main ($s);

    $http->close_response_body;
  });
};

__END__

=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 LICENSE

Copyright 2012-2013 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
