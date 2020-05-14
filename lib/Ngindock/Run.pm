package Ngindock::Run;

use strict;
use warnings;

use Ngindock::Log;
use IPC::Run qw(run);

sub execute {
    my ($pkg, @cmd) = @_;

    Ngindock::Log->log(2, "execute: [" . join(' ', @cmd) . "]");
    my $output;
    my $ok = run(\@cmd, '>', \$output, '2>&1');
    if (!$ok) {
        Ngindock::Log->log(0, ">> $_") for split /\n/, $output;
        die "bad exit status from [" . join(' ', @cmd) . "]\n" if !$ok;
    }

    Ngindock::Log->log(2, ">> $_") for split /\n/, $output;

    return $output;
}

1;
