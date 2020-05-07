package Ngindock::Log;

use strict;
use warnings;

my $LOG_LEVEL = 0;

sub level {
    my ($pkg, $level) = @_;

    $LOG_LEVEL = $level if defined $level;
    return $LOG_LEVEL;
}

sub log {
    my ($self, $level, $msg) = @_;

    return if $level > $LOG_LEVEL;

    my @lines = split /\n/, $msg;

    for my $l (@lines) {
        print STDERR "[" . localtime . "] " . $l . "\n";
    }
}

sub register {
    $SIG{__DIE__} = sub {
        my ($error) = @_;
        Ngindock::Log->log(0, $error);
        exit 1;
    };
    $SIG{__WARN__} = sub {
        my ($error) = @_;
        Ngindock::Log->log(0, $error);
    };
}

1;
