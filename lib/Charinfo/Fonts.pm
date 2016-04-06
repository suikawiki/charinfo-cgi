package Charinfo::Fonts;
use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::Functions::XS;

my $RootPath = path (__FILE__)->parent->parent->parent;
my $CSSFonts = json_bytes2perl $RootPath->child ('local/css-fonts.json')->slurp;

my $CSSKeywords = [
  (sort { $a cmp $b } keys %{$CSSFonts->{generic_font_families}}),
  (sort { $a cmp $b } keys %{$CSSFonts->{font_family_keywords}}),
  (sort { $a cmp $b } keys %{$CSSFonts->{system_fonts}}),
];

my $OtherFontNames = [
    "Times New Roman",
    "Arial",
    "Arial Unicode MS",
    "Helvetica",
    "Helvetica Neue",
    "Verdana",
    "Lucida Grande",
    "Courier New",
    "MS PMincho",
    "MS PGothic",
    "Microsoft Yahei",
    "微软雅黑",
    "Meiryo",
    "Osaka",
    "Fira Sans",
    "Droid Sans",
    "Comic Sans MS",
    "Hiragino Sans GB",
    "Hiragino Kaku Gothic ProN",
    ".SFNSDisplay-Regular",
    "Segoe UI",
    "Roboto",
    "Oxygen",
    "Ubuntu",
    "Cantarell",
    "PingFang SC",
    "Symbol",
    "Wingdings",
    "Wingdings 2",
    "Wingdings 3",
    "Webdings",
    "BlinkMacSystemFont",
];

my $WebFonts = [
  {name => 'OpenSansEmoji', file_name => 'OpenSansEmoji.otf',
   url => q<https://github.com/MorbZ/OpenSansEmoji>},
  {name => 'Mona', file_name => 'mona.ttf',
   url => q<https://osdn.jp/projects/sfnet_monafont/>},
  {name => '小夏', file_name => 'Konatu.ttf',
   url => q<http://www.masuseki.com/?u=be/konatu.htm>},
  {name => 'Noto Color Emoji', file_name => 'NotoColorEmoji.ttf',
   url => q<https://www.google.com/get/noto/#emoji-qaae-color>},
  {name => 'Noto Emoji', file_name => 'NotoEmoji-Regular.ttf',
   url => q<https://www.google.com/get/noto/#emoji-qaae>},
];
my $HasWebFont = {map { $_->{name} => 1 } @$WebFonts};

sub css_font_keywords ($) {
  return $CSSKeywords;
} # css_font_keywords

sub web_fonts ($) {
  return $WebFonts;
} # web_fonts

sub other_font_names ($) {
  return $OtherFontNames;
} # other_font_names

my $AAFonts = [];
for (@{$CSSFonts->{aa_2ch_font_family}}) {
  push @$AAFonts, {name => $_, has_web_font => $HasWebFont->{$_}};
}

sub aa_font_names ($) {
  return $AAFonts;
} # aa_font_names

1;

=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 LICENSE

Copyright 2011-2015 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
