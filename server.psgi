#!/usr/bin/perl
use strict;
BEGIN {
  my $file_name = __FILE__; $file_name =~ s{[^/]+$}{}; $file_name ||= '.';
  $file_name .= '/./config/perl/libs.txt';
  open my $file, '<', $file_name or die "$0: $file_name: $!";
  unshift @INC, split /:/, scalar <$file>;
}
use warnings;
use Wanage::HTTP;
use Warabe::App;
use Charinfo::Main;

$Charinfo::Main::SELF_URL = '/info';

sub {
  my $http = Wanage::HTTP->new_from_psgi_env ($_[0]);

  return $http->send_response (onready => sub {
    my $app = Warabe::App->new_from_http ($http);

    local $Charinfo::Main::Output = sub {
      $http->send_response_body_as_text (join '', @_);
    }; # Output
    $http->set_response_header ('Content-Type' => 'text/html; charset=utf-8');
    
    Charinfo::Main->main ($app->text_param ('s') // '');
  });
};

__END__

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Copyright 2012 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
