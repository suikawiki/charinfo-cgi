use strict;
use warnings;
use Path::Class;

my $version = shift;

my $d = file (__FILE__)->dir->subdir ('set', $version eq 'latest' ? 'unicode' : 'unicode' . $version);
$d->mkpath;

my $Props = {};

while (<>) {
  if (/^([0-9A-F]+)(?:\.\.([0-9A-F]+))?\s*;\s*(\S+)/) {
    my $code = hex $1;
    my $code2 = defined $2 ? hex $2 : undef;
    my $prop = $3;
    push @{$Props->{$prop} ||= []}, [$code, $code2];
  }
}

for my $prop (keys %$Props) {
  my $file = $d->file ($prop . '.expr')->openw;
  print $file '[';
  print $file join '', map { defined $_->[1] ? sprintf '\\u{%04X}-\\u{%04X}', $_->[0], $_->[1] : sprintf '\\u{%04X}', $_->[0] } @{$Props->{$prop}};
  print $file ']';
}
