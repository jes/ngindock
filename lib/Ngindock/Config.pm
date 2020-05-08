package Ngindock::Config;

use strict;
use warnings;

use YAML;

my @CONFIG_FIELDS = qw(
    nginx_conf nginx_upstream ports container_port health_url health_sleep docker_opts image_name container_name grace_period
);
my @REQUIRED_FIELDS = qw(
    nginx_conf nginx_upstream ports container_port image_name container_name
);

sub new {
    my ($pkg, $file) = @_;

    my $self = bless {}, $pkg;
    my $cfg = YAML::LoadFile($file);

    $self->{$_} = delete $cfg->{$_} for @CONFIG_FIELDS;
    Ngindock::Log->log(0, "$file contains unrecognised field(s): " . join(',', keys %$cfg) . "\n") if keys %$cfg;

    my @missing_fields = grep { !exists $self->{$_} } @REQUIRED_FIELDS;
    die "$file: missing required field(s): " . join(',', @missing_fields) . "\n" if @missing_fields;

    die "$file: ports: need at least 2 port numbers" if @{ $self->{ports} } < 2;

    return $self;
}

1;
