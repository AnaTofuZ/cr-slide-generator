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
           'build_open' => Smart::Options->new->default('target' => 'slide.md'),
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

sub cmd_build_open {
    my($self,$target) = @_;
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


    croak "didn't add" if $stderr;

    say "[AUTO]hg commit -m auto-Update generated slides by script";

    ($stdout,$stderr,$exit) = capture { system('hg commit -m "auto-Update generated slides by script"');};

    if ($stderr) { say $stderr; croak "didn't commit";}

    say "[AUTO]hg push";

    ($stdout,$stderr,$exit) = capture { system('hg push'); };

    if ( $stderr ) {
        say $stderr;
        croak "didn't commit";
    } else {
        say $stdout;
    }
}

sub _y_m_d {
    my $t = localtime;
    # ex... 2018/02/14
    ($t->strftime('%Y'), $t->strftime('%m'), $t->strftime('%d'));
}

sub _search_recently {
    my($self,$root_directory_name) = @_;
    my ($y,$m,$d) = _y_m_d();
    my $root_dir = path($root_directory_name.'/'.$y.'/'.$m);

    my $date = shift @{ [sort { $b->stat->mtime <=> $a->stat->mtime } $root_dir->children]};

    return $date;
}

1;
