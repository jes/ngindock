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

    # remove comment lines
    $self->{config_text} =~ s/.*#.*\n//g;
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

sub upstreams {
    my ($self, $upstream) = @_;

    if ($self->{config_text} !~ /upstream\s*$upstream\s*{\s*([^}]*)\s*}/) {
        die "can't find upstream $upstream in $self->{file}\n"
    }
    my $upstream_text = $1;

    my @parts = split /;/, $upstream_text;

    my @upstreams;
    for my $p (@parts) {
        next if $p !~ /\S/;
        $p =~ s/^\s*//; $p =~ s/\s*$//; $p =~ s/\s+/ /;

        Ngindock::Log->log(2, "$self->{file}: upstream '$upstream': $p");

        if ($p =~ /server\s*127.0.0.1:(\d+)/) {
            push @upstreams, $1;
        } else {
            Ngindock::Log->log(0, "$self->{file}: ignoring unrecognised upstream: $p");
        }
    }

    return @upstreams;
}

# TODO: this function sucks and is fragile, rewrite it:
#  1.) we should preserve comments that existed in the input
#  2.) we should accept extra spaces after "server"
#  3.) if substring isn't found with index() we rewrite random nonsense
sub rewrite_upstream {
    my ($self, $upstream, $oldport, $newport) = @_;

    if ($self->{config_text} !~ /upstream\s*$upstream\s*{/) {
        die "can't find upstream $upstream in $self->{file}\n"
    }
    # $` is the text up to the regex match, aka $PREMATCH
    my $ptr = length($`);

    # TODO: what if not found?
    $ptr += index(substr($self->{config_text}, $ptr), "server 127.0.0.1:$oldport");

    substr($self->{config_text}, $ptr, length("server 127.0.0.1:$oldport"), "server 127.0.0.1:$newport");

    $self->save;
}

sub reload {
    my ($self) = @_;

    my @extra_opts = split / /, ($self->{nginx_opts}||'');

    Ngindock::Run->execute("nginx", @extra_opts, "-c", $self->{file}, "-s", "reload");
}

1;
