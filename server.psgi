#!/usr/bin/perl
use strict;
use warnings;
no warnings 'utf8';
use Path::Class;
use URL::PercentEncode qw(percent_encode_c);
use Wanage::HTTP;
use Warabe::App;
use Charinfo::Locale;
use Charinfo::Set;

my $css_f = file (__FILE__)->dir->file ('css.css');
my $fonts_d = file (__FILE__)->dir->subdir ('fonts');

my $texts = do scalar file (__FILE__)->dir->file ('local/texts.pl')
    or die "$@ / $!";

$Wanage::HTTP::UseXForwardedScheme = 1;
$Wanage::HTTP::UseXForwardedHost = 1;

sub {
  my $http = Wanage::HTTP->new_from_psgi_env ($_[0]);

  return $http->send_response (onready => sub {
    my $app = Warabe::App->new_from_http ($http);
    my $locale = Charinfo::Locale->new_from_texts ($texts);
    if ($app->http->url->{scheme} eq 'http' and
        $app->http->url->{host} =~ /suikawiki\.org/) {
      my $url = $app->http->url->clone;
      $url->{scheme} = 'https';
      return $app->execute (sub {
        return $app->send_redirect ($url->stringify, status => 301);
      });
    } elsif ($app->http->url->{host} =~ /suikawiki\.org/ and
             not $app->http->url->{host} =~ /\A(?:[a-z]{2}\.|)chars\.suikawiki\.org\z/) {
      return $app->execute (sub {
        return $app->send_redirect ('https://chars.suikawiki.org/', status => 301);
      });
    } elsif ($app->http->url->{host} =~ /^([a-z]{2})\./) {
      $locale->set_accept_langs ([$1]);
      return $app->execute (sub {
        return $app->send_redirect ('https://chars.suikawiki.org/', status => 301);
      }) unless $1 eq $locale->lang;
    } else {
      $app->http->set_response_header
          ('Strict-Transport-Security' => 'max-age=10886400; includeSubDomains; preload');
      $locale->set_accept_langs ($app->http->accept_langs);
    }
    $app->execute (sub {
      my $s;
      my $path = $app->path_segments;
      require Charinfo::Main;
      require Charinfo::Name;
      if ($path->[0] eq '' and not defined $path->[1]) {
        # /
        $s = $app->text_param ('s') // '';
        if ($s eq '') {
          $http->set_response_header
              ('Content-Type' => 'text/html; charset=utf-8');
          local $Charinfo::Main::Output = sub {
            $http->send_response_body_as_text (join '', @_);
          }; # Output
          Charinfo::Main->top ($locale);
          $http->close_response_body;
          return;
        } else {
          $app->throw_redirect ('/string?s=' . percent_encode_c $s,
                                status => 301);
          return;
        }
      } elsif ($path->[0] eq 'string' and not defined $path->[1]) {
        # /string
        $s = $app->text_param ('s') // '';
        my $escape = $app->bare_param ('escape') // '';
        if ($escape eq 'u') {
          $s =~ s/\\U([0-9A-Fa-f]{8})/chr hex $1/ge;
          $s =~ s/\\u([0-9A-Fa-f]{4})/chr hex $1/ge;
        }
      } elsif ($path->[0] eq 'char' and
               defined $path->[1] and $path->[1] =~ /\A[0-9A-F]{4,8}\z/ and
               not defined $path->[2]) {
        # /char/{hex}
        $s = chr hex $path->[1] if 0x7FFF_FFFF >= hex $path->[1];
      } elsif ($path->[0] eq 'char' and
               defined $path->[1] and
               not defined $path->[2]) {
        # /char/{name}
        my $code = Charinfo::Name->char_name_to_code ($path->[1]);
        if (defined $code) {
          $s = chr $code;
        } else {
          $s = Charinfo::Name->char_name_to_seq ($path->[1]); # or undef
        }
      } elsif ($path->[0] eq 'set') {
        if (not defined $path->[1]) {
          # /set
          $s = $app->text_param ('expr') // '';
          if (length $s) {
            $http->set_response_header
                ('Content-Type' => 'text/html; charset=utf-8');
            local $Charinfo::Main::Output = sub {
              $http->send_response_body_as_text (join '', @_);
            }; # Output
            Charinfo::Main->set ($app, $s);
            $http->close_response_body;
            return;
          } else {
            $http->set_response_header
                ('Content-Type' => 'text/html; charset=utf-8');
            local $Charinfo::Main::Output = sub {
              $http->send_response_body_as_text (join '', @_);
            }; # Output
            Charinfo::Main->set_list;
            $http->close_response_body;
            return;
          }
        } elsif ($path->[1] eq 'compare' and not defined $path->[2]) {
          # /set/compare
          $http->set_response_header
              ('Content-Type' => 'text/html; charset=utf-8');
          local $Charinfo::Main::Output = sub {
            $http->send_response_body_as_text (join '', @_);
          }; # Output
          my $exprs = $app->text_param_list ('expr');
          if (@$exprs) {
            Charinfo::Main->set_compare_multiple ($exprs);
          } else {
            $s = $app->text_param ('expr1') // '';
            my $s2 = $app->text_param ('expr2') // '';
            Charinfo::Main->set_compare ($s, $s2);
          }
          $http->close_response_body;
          return;
        } elsif ($path->[1] =~ /\A\$[0-9A-Za-z_.:-]+\z/ and
                 not defined $path->[2]) {
          # /set/{set_id}
          $http->set_response_header
              ('Content-Type' => 'text/html; charset=utf-8');
          local $Charinfo::Main::Output = sub {
            $http->send_response_body_as_text (join '', @_);
          }; # Output
          Charinfo::Main->set ($app, $path->[1]);
          $http->close_response_body;
          return;
        } elsif (@$path == 2 and
                 $path->[1] =~ /\A(?:[0-9A-Fa-f]+\?*|\?+)\z/) {
          # /set/{range}
          my $start = $path->[1];
          $start =~ s/\?/0/g;
          my $end = $path->[1];
          $end =~ s/\?/F/g;
          $http->set_response_header
              ('Content-Type' => 'text/html; charset=utf-8');
          local $Charinfo::Main::Output = sub {
            $http->send_response_body_as_text (join '', @_);
          }; # Output
          Charinfo::Main->set ($app, sprintf q{[\u{%s}-\u{%s}]}, $start, $end);
          $http->close_response_body;
          return;
        } elsif (@$path == 2 and $path->[1] eq 'perlrevars') {
          # /set/perlrevars
          my $result = '';
          for (@{$app->text_param_list ('item')}) {
            if (s/\A(\$|)([A-Za-z_][A-Za-z_0-9]+)=//) {
              my $type = $1;
              my $name = $2;
              my $set = eval { Charinfo::Set->evaluate_expression ($_) };
              unless (defined $set) {
                return $app->throw_error
                    (400, reason_phrase => "Bad expression |$_|");
              }
              if ($type eq '$') {
                my $value = Charinfo::Set->serialize_set_for_perl ($set);
                $result .= "\$$name = qr{$value};\n";
              } else {
                my $value = Charinfo::Set->serialize_set_for_perl_p ($set);
                $result .= "sub $name () { q{$value} }\n";
              }
            } else {
              return $app->throw_error
                  (400, reason_phrase => "Bad item |$_|");
            }
          }
          $http->set_response_header
              ('Content-Type' => 'text/perl; charset=utf-8');
          $http->send_response_body_as_text ($result);
          $http->close_response_body;
          return;
        }

      } elsif ($path->[0] eq 'map') {
        if (not defined $path->[1]) {
          # /map
          $http->set_response_header
              ('Content-Type' => 'text/html; charset=utf-8');
          local $Charinfo::Main::Output = sub {
            $http->send_response_body_as_text (join '', @_);
          }; # Output
          Charinfo::Main->map_list;
          $http->close_response_body;
          return;
        } elsif ($path->[1] eq 'compare' and not defined $path->[2]) {
          # /map/compare
          my $map1 = $app->text_param ('expr1') // '';
          my $map2 = $app->text_param ('expr2') // '';
          $http->set_response_header
              ('Content-Type' => 'text/html; charset=utf-8');
          local $Charinfo::Main::Output = sub {
            $http->send_response_body_as_text (join '', @_);
          }; # Output
          Charinfo::Main->map_compare ($app, $map1, $map2);
          $http->close_response_body;
          return;
        } elsif (defined $path->[1] and not defined $path->[2]) {
          # /map/{name}
          $http->set_response_header
              ('Content-Type' => 'text/html; charset=utf-8');
          local $Charinfo::Main::Output = sub {
            $http->send_response_body_as_text (join '', @_);
          }; # Output
          Charinfo::Main->map_page ($app, $path->[1]);
          $http->close_response_body;
        }

      } elsif (@$path == 1 and $path->[0] eq 'seq') {
        # /seq
        $http->set_response_header
            ('Content-Type' => 'text/html; charset=utf-8');
        local $Charinfo::Main::Output = sub {
          $http->send_response_body_as_text (join '', @_);
        }; # Output
        Charinfo::Main->seq_list ($app);
        $http->close_response_body;
        return;

      } elsif ($path->[0] eq 'css' and not defined $path->[1]) {
        # /css
        $http->set_response_header
            ('Content-Type' => 'text/css; charset=utf-8');
        $http->set_response_last_modified ([stat $css_f]->[9]);
        $http->send_response_body_as_ref (\(scalar $css_f->slurp));
        $http->close_response_body;
        return;
      } elsif (@$path == 2 and $path->[0] eq 'fonts' and
               $path->[1] =~ m{\A[A-Za-z0-9-]+\.[ot]tf\z}) {
        # /fonts/{name}
        my $font_f = $fonts_d->file ($path->[1]);
        if (-f $font_f) {
          $http->set_response_header
              ('Content-Type' => 'application/octet-stream');
          $http->set_response_last_modified ([stat $font_f]->[9]);
          $http->send_response_body_as_ref (\(scalar $font_f->slurp));
          $http->close_response_body;
          return;
        }
      }
      $app->throw_error (404) unless defined $s;
      
      local $Charinfo::Main::Output = sub {
        $http->send_response_body_as_text (join '', @_);
      }; # Output
      $http->set_response_header
          ('Content-Type' => 'text/html; charset=utf-8');
      
      Charinfo::Main->main ($s, $app);

      $http->close_response_body;
    });
  });
};

__END__

=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 LICENSE

Copyright 2012-2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
