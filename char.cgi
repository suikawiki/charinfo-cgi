#!/usr/bin/perl
use strict;
BEGIN {
  my $file_name = __FILE__; $file_name =~ s{[^/]+$}{}; $file_name ||= '.';
  $file_name .= '/./config/perl/libs.txt';
  open my $file, '<', $file_name or die "$0: $file_name: $!";
  unshift @INC, split /:/, scalar <$file>;
}
use warnings;
use Path::Class;
use lib file (__FILE__)->dir->subdir ('lib')->stringify;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib')->stringify;
use Message::CGI::HTTP;
use CGI::Carp qw(fatalsToBrowser);
use Encode;

binmode STDOUT, ':encoding(utf-8)';

my $cgi = Message::CGI::HTTP->new;

my $string = decode 'utf8', $cgi->get_parameter ('s');

print "Content-Type: text/html; charset=utf-8\n\n";

require Charinfo::Main;
$Charinfo::Main::Output = sub { print @_ };
$Charinfo::Main::SELF_URL = 'char';

Charinfo::Main->main;

__END__

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Copyright 2011 Wakaba <w@suika.fam.cx>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
