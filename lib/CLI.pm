package CLI;
use strict;
use warnings;
use utf8;

use DDP { deparse => 1 };

use Smart::Options;
use Smart::Options::Declare;
use Time::Piece;
use Capture::Tiny qw/capture/;
use Path::Tiny;
use File::chdir;
use Carp qw/croak/;

use Class::Tiny qw/ template root_dir/;
use feature 'say';

sub run {
    my($self,@args) = @_;
    my $opt = Smart::Options->new;
    $opt->subcmd(
           new    => Smart::Options->new(),
           build  => Smart::Options->new(),
           open   => Smart::Options->new->default('target' => 'slide.md'),
           'build_open' => Smart::Options->new->default('target' => 'slide.md'),
           upload => Smart::Options->new(),
     );

    my $command = $result->{command} // "open";

    my $call= $self->can("cmd_$command");
    croak 'undefine subcommand' unless $call;
    $self->$call();
}

sub cmd_new {
    my ($self) = @_;
    my ($y,$m,$d) = _y_m_d();
    my $slide = path($self->root_dir)->child($y)->child($m)->child($d)->child('slide.md')->touchpath;
    path($self->template)->copy($slide);
}

sub cmd_build {
    my($self,$target) = @_;

    $self->_build($self->_search_recently_day());
}

sub _build {
    my ($self,$dir,$target) = @_;

    $target //= 'slide.md';

    say "[AUTO] BUILD at $dir/$target";

    local $CWD = $dir;

    my ($stdout,$stderr,$exit) = capture {
        system("slideshow build ${target} -t s6cr");
    };

    croak "Perl can't build...." if $stderr;
}

sub cmd_build_open {
    my($self,$target) = @_;
}

sub cmd_open {
    my($self) = @_;
    my $target = $self->_search_recently_day()->child('slide.html');

    if($target->realpath){
        system 'open', ($target->realpath);
    } else {
        croak 'dont found slide.html';
    }
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

sub _search_recently_day {
    my($self) = @_;
    my ($y,$m,$d) = _y_m_d();
    my $root_dir = path($self->root_dir)->child($y)->child($m);

    my $date = shift @{ [sort { $b->stat->mtime <=> $a->stat->mtime } $root_dir->children]};
    return $date;
}

1;
