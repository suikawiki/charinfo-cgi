use strict;
use warnings;
use Data::Dumper;
use Path::Class;

my $version = shift;

my $d = file (__FILE__)->dir->subdir ('set', $version eq 'latest' ? 'unicode' : 'unicode' . $version);
$d->mkpath;

my $Chars = {};

my $prev_code = -1;
while (<>) {
  if (/^([0-9A-F]+);([^;]+);([^;]+)/) {
    my $code = hex $1;
    my $name = $2;
    my $gc = $3;
    $Chars->{$gc} ||= [];
    if (@{$Chars->{$gc}} and
        ($Chars->{$gc}->[-1]->[1] == $code - 1 or $name =~ /, Last/)) {
      $Chars->{$gc}->[-1]->[1] = $code;
    } else {
      if ($prev_code + 1 != $code) {
        push @{$Chars->{Cn}}, [$prev_code + 1, $code - 1];
      }
      push @{$Chars->{$gc}}, [$code, $code];
    }
    $prev_code = $code;
  }
}
if ($prev_code != 0x10FFFF) {
  push @{$Chars->{Cn}}, [$prev_code + 1, 0x10FFFF];
}

for my $gc (keys %$Chars) {
  my $file = $d->file ($gc . '.expr')->openw;
  print $file '[' . (join '', map { sprintf '\\u{%04X}-\\u{%04X}', $_->[0], $_->[1] } @{$Chars->{$gc}}) . ']';
}
