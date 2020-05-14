package Ngindock::Docker;

use strict;
use warnings;

use Ngindock::Log;
use IPC::Run;

sub execute {
    my ($pkg, @cmd) = @_;

    Ngindock::Log->log(2, "execute: [" . join(' ', @cmd) . "]");
    my $output;
    my $ok = IPC::Run::run(\@cmd, '>', \$output);
    Ngindock::Log->log(2, " >> $_") for split /\n/, $output;
    die "bad exit status from [" . join(' ', @cmd) . "]\n" if !$ok;

    return $output;
}

sub run {
    my ($pkg, %opts) = @_;

    my @cmd = ("docker", "run", "-d");

    push @cmd, split / /, $opts{extra_args} if $opts{extra_args};
    push @cmd, "--name", $opts{name} if $opts{name};
    push @cmd, "-p", $opts{port} if $opts{port};

    push @cmd, $opts{image};

    $pkg->execute(@cmd);
}

sub stop {
    my ($pkg, $container) = @_;

    $pkg->execute("docker", "stop", $container);
}

sub rm {
    my ($pkg, $container) = @_;

    $pkg->execute("docker", "rm", $container);
}

sub rename {
    my ($pkg, $oldname, $newname) = @_;

    $pkg->execute("docker", "rename", $oldname, $newname);
}

sub has_container {
    my ($pkg, $name, %opts) = @_;

    my @cmd = (
        "docker", "ps", "-q", "--filter=name=^/$name\$",
        ($opts{only_running} ? () : ('-a')),
    );
    my $output = $pkg->execute(@cmd);;

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
