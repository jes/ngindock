package Ngindock;

use strict;
use warnings;

use Ngindock::Config;
use Ngindock::Log;
use Ngindock::Nginx;
use Ngindock::Docker;
use LWP::UserAgent;

sub new {
    my ($pkg, %opts) = @_;

    my $self = bless \%opts, $pkg;

    die "no cfg passed to Ngindock->new" if !$self->{cfg};

    $self->{nginx} = Ngindock::Nginx->new($self->{cfg}{nginx_conf});

    return $self;
}

sub run {
    my ($self) = @_;

    Ngindock::Log->log(2, "ngindock starts");

    # grab current port number out of nginx.conf
    my $cur_port = $self->current_port;

    # select next port number from list
    my $new_port = $self->next_port($cur_port);
    die "new port $new_port same as old port" if $new_port == $cur_port;
    Ngindock::Log->log(1, "plan to move from port $cur_port to $new_port");

    # start the new docker container
    Ngindock::Log->log(1, "start container listening on $new_port...");
    $self->start_new_container($new_port);

    # wait for new container to become ready
    Ngindock::Log->log(1, "wait for container health check...");
    $self->wait_healthy($new_port);

    if (!$self->{dry_run}) {
        # update nginx config to direct traffic to new container
        Ngindock::Log->log(1, "update nginx to direct traffic to port $new_port...");
        $self->{nginx}->rewrite_upstream($self->{cfg}{nginx_upstream}, $cur_port, $new_port);
        $self->{nginx}->reload($self->{cfg}{nginx_opts});

        # wait for existing sessions to stop going to old container?
        if ($self->{cfg}{grace_period}) {
            Ngindock::Log->log(1, "sleep for grace_period of $self->{cfg}{grace_period} secs...");
            sleep $self->{cfg}{grace_period};
        }

        # stop & remove the old docker container
        Ngindock::Log->log(1, "remove old container if it exists...");
        Ngindock::Docker->kill($self->{cfg}{container_name});

        # rename new container
        Ngindock::Log->log(1, "rename " . $self->new_container_name . " to $self->{cfg}{container_name}...");
        Ngindock::Docker->rename($self->new_container_name, $self->{cfg}{container_name});
    } else {
        Ngindock::Log->log(0, "--dry-run: your new container " . $self->new_container_name . " is at http://localhost:$new_port");
    }

    Ngindock::Log->log(2, "ngindock finishes");
}

sub index_in_array {
    my ($self, $val, @array) = @_;

    for my $i (0 .. $#array) {
        return $i if $array[$i] eq $val;
    }

    return undef;
}

sub current_port {
    my ($self) = @_;

    my @upstreams = $self->{nginx}->upstreams($self->{cfg}{nginx_upstream});
    Ngindock::Log->log(2, "found upstream port number(s): [" . join(',',@upstreams) . "]");
    die "expected 1 upstream, found " . (scalar @upstreams) . "\n" unless @upstreams == 1;
    my $cur_port = $upstreams[0];
    Ngindock::Log->log(2, "current nginx port number: $cur_port");

    return $cur_port;
}

sub next_port {
    my ($self, $cur_port) = @_;

    my $cur_port_idx = $self->index_in_array($cur_port, @{ $self->{cfg}{ports} });
    die "current port number $cur_port not allowed (expected one of " . join(',', @{ $self->{cfg}{ports} }) . "\n" if !defined $cur_port_idx;
    my $new_port_idx = ($cur_port_idx+1) % @{ $self->{cfg}{ports} };
    my $new_port = $self->{cfg}{ports}[$new_port_idx];
    Ngindock::Log->log(2, "new nginx port number: $new_port");

    return $new_port;
}

sub wait_healthy {
    my ($self, $port) = @_;

    if ($self->{cfg}{health_url}) {
        my $url = "http://localhost:$port$self->{cfg}{health_url}";
        my $ua = LWP::UserAgent->new(
            agent => 'ngindock',
        );

        while (1) {
            my $code = $ua->get($url)->code;
            Ngindock::Log->log(2, "GET $url: $code");
            last if $code == 200;
            sleep 1;
        }
    }

    if ($self->{cfg}{health_sleep}) {
        Ngindock::Log->log(2, "health_sleep for $self->{cfg}{health_sleep} seconds...");
        sleep $self->{cfg}{health_sleep};
        Ngindock::Log->log(2, "done sleeping");
    }

    return;
}

sub new_container_name {
    my ($self) = @_;

    return "$self->{cfg}{container_name}_ngindock_new";
}

sub start_new_container {
    my ($self, $port) = @_;

    Ngindock::Docker->kill($self->new_container_name);
    Ngindock::Docker->run(
        extra_args => $self->{cfg}{docker_opts},
        name => $self->new_container_name,
        image => $self->{cfg}{image_name},
        port => "$port:$self->{cfg}{container_port}",
    );
    Ngindock::Log->log(1, "started container " . $self->new_container_name);
}

1;
