package CLI;
use strict;
use warnings;
use utf8;

use DDP { deparse => 1 };

use Smart::Options;
use Smart::Options::Declare;
use Time::Piece;
use Time::Seconds;
use Capture::Tiny qw/capture/;
use Path::Tiny;
use File::chdir;
use Carp qw/croak/;

use Class::Tiny qw/ template root_dir/;
use feature 'say';

sub run {
    my($self,@args) = @_;
    my $opt = Smart::Options->new->options(
        file => { describe => 'target file', alias => 'f'}
    );
    $opt->subcmd(
           new    => Smart::Options->new(),
           build  => Smart::Options->new(),
           open   => Smart::Options->new->default('target' => 'slide.md'),
           'build_open' => Smart::Options->new->default('target' => 'slide.md'),
           upload => Smart::Options->new(),
           memo => Smart::Options->new(),
           edit => Smart::Options->new(),
           zip => Smart::Options->new(),
     );

    my $result = $opt->parse(@args);
    my $command = $result->{command} // "open";

    my $option = $result->{cmd_option}->{f} || $result->{cmd_option}->{file} || 0;

    my $call= $self->can("cmd_$command");
    croak 'undefine subcommand' unless $call;
    $self->$call($option);
}

sub cmd_new {
    my ($self) = @_;
    my ($y,$m,$d) = _y_m_d();
    my $slide = path($self->root_dir)->child($y)->child($m)->child($d)->child('slide.md')->touchpath;
    path($self->template)->copy($slide);
}

sub cmd_build {
    my($self,$target) = @_;

    if ($target){
        $target = path($target);
        $self->_build($target->dirname,$target->basename);
    } else {
        $self->_build($self->_search_recently_day());
    }
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
    $self->cmd_build($target);
    if($target){
        $target =~ s/\.md$/\.html/;
    }
    $self->cmd_open(path($target));
}

sub cmd_open {
    my($self,$slide) = @_;
    
    my $target;

    if ($slide){
       $target = $slide;
    } else {
       $slide  = 'slide.html';
       $target = $self->_search_recently_day()->child($slide);
    }

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

sub cmd_memo {
    my ($self) = @_;
    my ($y,$m,$d) = _y_m_d();
    my $memo = path($self->root_dir)->child($y)->child($m)->child($d)->child('memo.txt')->touchpath;
    exec $ENV{EDITOR},($memo->realpath);
}

sub cmd_edit {
    my ($self) = @_;
    my $recent_day = $self->_search_recently_day();
    my @targets = $recent_day->children(qr/\.md$/);
    my $target = pop @targets;
    exec $ENV{EDITOR},($target->realpath);
}

sub cmd_zip {
    my ($self) = @_;
    my $recent_day = $self->_search_recently_day();
    my $t = localtime;
    my $zip = $recent_day->child('zip.txt')->touch->opena;

    $t-= ONE_WEEK;

    for(1..7){
       my($y,$m,$d)=($t->strftime('%Y'), $t->strftime('%m'), $t->strftime('%d'));
       my $memo = path($self->root_dir)->child($y)->child($m)->child($d)->child('memo.txt');

       unless ($memo->exists) {
           $t += ONE_DAY;
           next;
       }

       say $zip "$y-$m-$d----";
       say $zip $memo->slurp;
       say $zip "----------";
       $t += ONE_DAY;
    }
}


1;
