package Ngindock::Docker;

use strict;
use warnings;

use Ngindock::Log;
use Ngindock::Run;

sub run {
    my ($pkg, %opts) = @_;

    my @cmd = ("docker", "run", "-d");

    push @cmd, split / /, $opts{extra_args} if $opts{extra_args};
    push @cmd, "--name", $opts{name} if $opts{name};
    push @cmd, "-p", $opts{port} if $opts{port};

    push @cmd, $opts{image};

    Ngindock::Run->execute(@cmd);
}

sub stop {
    my ($pkg, $container) = @_;

    Ngindock::Run->execute("docker", "stop", $container);
}

sub rm {
    my ($pkg, $container) = @_;

    Ngindock::Run->execute("docker", "rm", $container);
}

sub rename {
    my ($pkg, $oldname, $newname) = @_;

    Ngindock::Run->execute("docker", "rename", $oldname, $newname);
}

sub has_container {
    my ($pkg, $name, %opts) = @_;

    my @cmd = (
        "docker", "ps", "-q", "--filter=name=^/$name\$",
        ($opts{only_running} ? () : ('-a')),
    );
    my $output = Ngindock::Run->execute(@cmd);;

    return $output ? 1 : 0;
}

sub kill {
    my ($pkg, $name) = @_;

    if ($pkg->has_container($name, only_running => 1)) {
        Ngindock::Log->log(1, "stopping container $name");
        $pkg->stop($name);
    }

    if ($pkg->has_container($name)) {
        Ngindock::Log->log(1, "removing container $name");
        $pkg->rm($name);
    }
}

1;
