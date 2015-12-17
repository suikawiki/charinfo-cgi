package Charinfo::Fonts;
use strict;
use warnings;
use Path::Tiny;
use JSON::Functions::XS;

my $RootPath = path (__FILE__)->parent->parent->parent;
my $CSSFonts = json_bytes2perl $RootPath->child ('local/css-fonts.json')->slurp;

my $CSSKeywords = [
  (keys %{$CSSFonts->{generic_font_families}}),
  (keys %{$CSSFonts->{font_family_keywords}}),
  (keys %{$CSSFonts->{system_fonts}}),
];

my $OtherFontNames = [
    "Times New Roman",
    "Arial",
    "Arial Unicode MS",
    "Helvetica",
    "Verdana",
    "Lucida Grande",
    "Courier New",
    "Comic Sans MS",
    "MS PMincho",
    "MS PGothic",
    "Meiryo",
    "Osaka",
    "Hiragino Kaku Gothic ProN",
    "Symbol",
    "Wingdings",
    "Wingdings 2",
    "Wingdings 3",
    "Webdings",
];

my $WebFonts = [
  {name => 'OpenSansEmoji', file_name => 'OpenSansEmoji.otf',
   url => q<https://github.com/MorbZ/OpenSansEmoji>},
];

sub css_font_keywords ($) {
  return $CSSKeywords;
} # css_font_keywords

sub web_fonts ($) {
  return $WebFonts;
} # web_fonts

sub other_font_names ($) {
  return $OtherFontNames;
} # other_font_names

1;

=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 LICENSE

Copyright 2011-2015 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
