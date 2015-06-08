package Charinfo::Locale;
use strict;
use warnings;

sub new_from_texts ($$) {
  return bless {all_texts => $_[1]}, $_[0];
} # new_from_texts

sub set_accept_langs ($$) {
  my ($self, $langs) = @_;
  for (@$langs, 'en') {
    if (defined $self->{all_texts}->{$_}) {
      $self->{lang} = $_;
      $self->{texts} = $self->{all_texts}->{$_};
      $self->{avail_langs} = [keys %{$self->{all_texts}}];
      return;
    }
  }
  die "No acceptable language in ->{texts}";
} # set_accept_langs_by_http

sub lang ($) {
  return $_[0]->{lang};
} # lang

sub avail_langs ($) {
  return $_[0]->{avail_langs};
} # avail_langs

sub text ($$) {
  my ($self, $msgid) = @_;
  my $text = $self->{texts}->{$msgid} || {format => '0', text => [$msgid]};
  return $text->{text}->[0];
} # text

1;
