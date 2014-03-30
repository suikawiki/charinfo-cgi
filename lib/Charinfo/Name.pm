package Charinfo::Name;
use strict;
use warnings;
use Path::Class;
use JSON::Functions::XS qw(file2perl);

my $CodeToNames;
my $NameToCode;
my $AliasTypes;
my $NameRanges;
my $NameToSeq;
my $SeqToNames;
BEGIN {
  my $data = file2perl file (__FILE__)->dir->parent->parent->subdir ('local')->file ('names.json');
  $AliasTypes = [sort { $a cmp $b } keys %{$data->{name_alias_types}}];
  for my $key (keys %{$data->{code_to_name}}) {
    my $c = hex $key;
    $CodeToNames->{$c} = $data->{code_to_name}->{$key};
    $NameToCode->{$data->{code_to_name}->{$key}->{name}} = $c
        if defined $data->{code_to_name}->{$key}->{name};
    $NameToCode->{$data->{code_to_name}->{$key}->{label}} = $c
        if defined $data->{code_to_name}->{$key}->{label};
    for (@$AliasTypes) {
      $NameToCode->{$_} = $c for keys %{$data->{code_to_name}->{$key}->{$_} or {}};
    }
  }
  $NameRanges ||= [];
  for my $key (keys %{$data->{range_to_prefix}}) {
    my @v = split / /, $key;
    push @$NameRanges,
        [hex $v[0], hex $v[1],
         $data->{range_to_prefix}->{$key}->{name},
         $data->{range_to_prefix}->{$key}->{label}];
  }
  for my $key (keys %{$data->{code_seq_to_name}}) {
    my $val = $data->{code_seq_to_name}->{$key};
    my $seq = join '', map { chr hex $_ } split / /, $key;
    $NameToSeq->{$val->{name}} = $seq;
    $SeqToNames->{$seq} = $val;
  }
}

sub alias_types ($) {
  return $AliasTypes;
}

sub char_name_to_code ($$) {
  my $name = $_[1];
  my $code = $NameToCode->{$name};
  return $code if defined $code;
  $name =~ s/\A<//;
  $name =~ s/>\z//;

  for (@$NameRanges) {
    if (defined $_->[2] and $name =~ /\A\Q$_->[2]\E([0-9A-F]{4,})\z/) {
      my $code = hex $1;
      if ($_->[0] <= $code and $code <= $_->[1]) {
        return $code;
      }
    } elsif (defined $_->[3] and $name =~ /\A\Q$_->[3]\E([0-9A-F]{4,})\z/) {
      my $code = hex $1;
      if ($_->[0] <= $code and $code <= $_->[1]) {
        return $code;
      }
    }
  }
  return undef;
} # char_name_to_code

sub char_code_to_names ($$) {
  my $code = $_[1];
  my $names = $CodeToNames->{$code};
  return $names if $names;
  return {} if $code > 0x10FFFF;

  for (@$NameRanges) {
    if ($_->[0] <= $code and $code <= $_->[1]) {
      my $v = {};
      $v->{name} = $_->[2] . sprintf '%04X', $code if defined $_->[2];
      $v->{label} = $_->[3] . sprintf '%04X', $code if defined $_->[3];
      return $v;
    }
  }
  return {label => sprintf '<reserved-%04X>', $code};
} # char_code_to_names

sub char_name_to_seq ($$) {
  return $NameToSeq->{$_[1]}; # or undef
} # char_name_to_seq

sub char_seq_to_names ($$) {
  return $SeqToNames->{$_[1]}; # or undef
} # char_seq_to_names

1;

=head1 LICENSE

Copyright 2013-2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
