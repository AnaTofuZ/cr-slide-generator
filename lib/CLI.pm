package CLI;
use strict;
use warnings;
use utf8;

use Data::Dumper;

use Smart::Options;
use Smart::Options::Declare;
use Carp qw/croak/;

use Class::Tiny;

sub run {
    my($self,@args) = @_;
    my $opt = Smart::Options->new;
    $opt->subcmd(
           build => Smart::Options->new(),
           open  => Smart::Options->new->default('target' => 'slide.md')
     );

    my $result = $opt->parse(@args);
    my $command = $result->{command} // "open";
    print Dumper $result;

    my $call= $self->can("cmd_$command");
    croak 'undefine subcommand' unless $call;
    $self->$call();
}


sub cmd_build {
}

sub cmd_upload {
}

1;
