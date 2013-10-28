use strict;
use warnings;
use Path::Class;

my $temp_d = file (__FILE__)->dir->parent->subdir ('local');
my $names_list_f = $temp_d->file ('NamesList.txt');
my $name_aliases_f = $temp_d->file ('NameAliases.txt');

my $code_to_name = {};
my $name_to_code = {};

for ($names_list_f->slurp) {
  if (/^([0-9A-F]{4,})\t([^<].+)/) {
    $code_to_name->{hex $1} = [$2];
    $name_to_code->{$2} = hex $1;
  }
}

for ($name_aliases_f->slurp) {
  if (/^([0-9A-F]{4,});([^;]+)/) {
    $name_to_code->{$2} = hex $1;
    push @{$code_to_name->{hex $1} ||= [undef]}, $2;
  }
}

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

print Dumper [$code_to_name, $name_to_code];

