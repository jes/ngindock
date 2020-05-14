package Ngindock::Nginx;

use strict;
use warnings;

use Ngindock::Log;
use Ngindock::Run;

sub new {
    my ($pkg, %opts) = @_;

    my $self = bless \%opts, $pkg;

    if ($self->{file} !~ /^\// && !exists $self->{nginx_opts}) {
        warn "warning: nginx_conf '$self->{file}' is a relative path (perhaps specify nginx_opts: '-p .'?)\n";
    }

    $self->load;

    return $self;
}

sub load {
    my ($self) = @_;

    open(my $fh, '<', $self->{file})
        or die "can't read $self->{file}: $!\n";
    $self->{config_text} = join('', <$fh>);
    close $fh;
}

sub save {
    my ($self) = @_;

    # TODO: should we take a backup of the original?

    open(my $fh, '>', "$self->{file}.tmp")
        or die "can't write $self->{file}.tmp: $!\n";
    print $fh $self->{config_text};
    close $fh;

    rename("$self->{file}.tmp", $self->{file});
}

# read the nginx config and pass every detected upstream server to the callback, like:
#   $cb->($line, $line_nocomment, $upstream, $server)
# The callback must return a value to replace the line with (returning $line will leave
# it unchanged).
# For example, config like:
#   upstream app {
#       server 127.0.0.1:3000; # my server
#   }
# would result in a call like:
#   $cb->(
#       '    server 127.0.0.1:3000; # my server',
#       '    server 127.0.0.1:3000; ',
#       'app',
#       '127.0.0.1:3000'
#   );
sub parse_upstreams {
    my ($self, $cb) = @_;

    my @lines = split /\n/, $self->{config_text};

    my $in_upstream;

    for my $i (0 .. $#lines) {
        my $line = $lines[$i];
        my $line_nocomment = $line;
        $line_nocomment =~ s/#.*//;

        if ($line_nocomment =~ /^\s*upstream\s*(\w+)\s*{/) {
            $in_upstream = $1;
        }
        if ($line_nocomment =~ /^\s*}/) {
            $in_upstream = undef;
        }

        if ($in_upstream && $line_nocomment =~ /^\s*server\s*([\w\.\:]+)\s*;/g) {
            $lines[$i] = $cb->($line, $line_nocomment, $in_upstream, $1);
        }
    }

    $self->{config_text} = join("\n", @lines) . "\n";
}

sub upstreams {
    my ($self, $upstream) = @_;

    my @upstreams;

    $self->parse_upstreams(sub {
        my ($line, $line_nocomment, $line_upstream, $server) = @_;

        Ngindock::Log->log(2, "$self->{file}: upstream '$upstream': server $server");

        if ($line_upstream eq $upstream) {
            if ($server =~ /127.0.0.1:(\d+)/) {
                push @upstreams, $1;
            } else {
                Ngindock::Log->log(0, "$self->{file}: ignoring unrecognised server: $line");
            }
        }

        return $line;
    });

    die "can't find upstream $upstream in $self->{file}\n" if !@upstreams;

    return @upstreams;
}

sub rewrite_upstream {
    my ($self, $upstream, $oldport, $newport) = @_;

    my $ok;
    $self->parse_upstreams(sub {
        my ($line, $line_nocomment, $line_upstream, $server) = @_;

        if ($line_upstream eq $upstream) {
            if ($server eq "127.0.0.1:$oldport") {
                $line =~ s/127.0.0.1:$oldport/127.0.0.1:$newport/;
                $ok = 1;
            }
        }

        return $line;
    });

    die "can't find upstream $upstream in $self->{file}\n" if !$ok;

    $self->save;
}

sub reload {
    my ($self) = @_;

    my @extra_opts = split / /, ($self->{nginx_opts}||'');

    Ngindock::Run->execute("nginx", @extra_opts, "-c", $self->{file}, "-s", "reload");
}

1;
