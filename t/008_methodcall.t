#!perl -w

use strict;
use Test::More;

use Text::Clevery;
use Text::Clevery::Parser;

my $tc = Text::Clevery->new(verbose => 2);

{
    package Foo;
    sub new { bless [], shift }

    sub push {
        my $self = shift;
        push @{$self}, @_;
        return $self;
    }
    sub join {
        my($self, $sep) = @_;
        return join $sep, @{$self};
    }
}

my @set = (
    [<<'T', { x => Foo->new }, <<'X'],
Hello, { $x->push('foo')->push('bar')->join('.') } world!
T
Hello, foo.bar world!
X

    [<<'T', { x => Foo->new }, <<'X'],
Hello, { $x.push('foo').push('bar').join('.') } world!
T
Hello, foo.bar world!
X
);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source, $vars) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}


done_testing;
