package CLI;
use strict;
use warnings;
use utf8;

use Data::Dumper;

use Smart::Options;
use Smart::Options::Declare;
use Time::Piece;
use Capture::Tiny qw/capture/;
use Path::Tiny;
use Carp qw/croak/;

use Class::Tiny;
use feature 'say';

sub run {
    my($self,@args) = @_;
    my $opt = Smart::Options->new;
    $opt->subcmd(
           build  => Smart::Options->new(),
           open   => Smart::Options->new->default('target' => 'slide.md'),
           upload => Smart::Options->new(),
     );

    my $result  = $opt->parse(@args);
    my $command = $result->{command} // "open";
    print Dumper $result;

    my $call= $self->can("cmd_$command");
    croak 'undefine subcommand' unless $call;
    $self->$call();
}


sub cmd_build {
    my($self,$target) = @_;

    _build(_search_recently());
}

sub cmd_open {
    say 'hoge';
}

sub cmd_upload {
    say "[AUTO]hg addremove";
    my ($stdout,$stderr,$exit) = capture {
        system("hg addremove");
        system("hg add");
    };

    if ($stderr) {
        croak "didn't add";
    }

    say "[AUTO]hg commit -m auto-Update generated slides by script";

    ($stdout,$stderr,$exit) = capture {
        system('hg commit -m "auto-Update generated slides by script"');
    };

    if ($stderr) {
        say $stderr;
        croak "didn't commit";
    }

    say "[AUTO]hg push";

    ($stdout,$stderr,$exit) = capture {
        system('hg push');
    };

    if ( $stderr ) {
        say $stderr;
        croak "didn't commit";
    } else {
        say $stdout;
    }
}


sub _search_recently {
    my($self) = @_;
    my $t = localtime;
}

1;
