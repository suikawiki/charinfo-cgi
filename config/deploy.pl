use strict;
use warnings;
use Cinnamon::DSL;
use Cinnamon::Task::Git;
use Cinnamon::Task::Daemontools;

set git_repository => 'git://github.com/wakaba/charinfo-cgi';
set deploy_dir => '/home/wakaba/server/charinfo';

role L1 => 'iyokan', {
  server_instance_name => 'L1',
};

task update => sub {
  my ($host, @args) = @_;
  call 'git:update', $host, @args;
};

task setup => sub {
  my ($host, @args) = @_;
  call 'app:setup', $host, @args;
};

task install => sub {
  my ($host, @args) = @_;
  call 'app:install', $host, @args;
};

task restart => sub {
  my ($host, @args) = @_;
  call 'web:restart', $host, @args;
};

task app => {
  setup => sub {
    my ($host, @args) = @_;
    my $dir = get 'deploy_dir';
    my $name = get 'server_instance_name';
    remote {
      run qq{cd \Q$dir\E && make deps server-config SERVER_ENV=$name};
    } $host;
  },
  install => sub {
    my ($host, @args) = @_;
    my $dir = get 'deploy_dir';
    my $name = get 'server_instance_name';
    remote {
      sudo qq{cd \Q$dir\E && make install-server-config SERVER_ENV=$name};
    } $host;
  },
}; # app

task web => {
  (define_daemontools_tasks 'web'),
};

1;
