use strict;
use warnings;
no warnings 'once';
use JSON::Functions::XS qw(json_bytes2perl);
use Path::Tiny;
use Data::Dumper;

my $json_path = path (__FILE__)->parent->parent->child ('texts/texts.json');
my $json = json_bytes2perl $json_path->slurp;

my $Data = {};

for my $text_id (keys %{$json->{texts}}) {
  my $text = $json->{texts}->{$text_id};
  my $msgid = $text->{msgid} // next;
  for my $lang (qw(en ja)) { # XXX
    my $lang_text = $text->{langs}->{$lang} || $text->{langs}->{en};
    $Data->{$lang}->{$msgid}->{forms} = $lang_text->{forms};
    $Data->{$lang}->{$msgid}->{text} = [$lang_text->{body_0},
                                        $lang_text->{body_1},
                                        $lang_text->{body_2},
                                        $lang_text->{body_3},
                                        $lang_text->{body_4},
                                        $lang_text->{body_5}];
  }
}

$Data::Dumper::Sortkeys = 1;
my $data = Dumper $Data;
$data =~ s/\$VAR1 =//;

print qq{use utf8; +$data;};

## License: Public Domain.
