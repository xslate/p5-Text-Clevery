#!perl -w

use strict;
use Test::More;

use Text::Clevy;
use Text::Clevy::Parser;
use Time::Piece ();

my $now = time();

my $tc = Text::Clevy->new(verbose => 2);

my @set = (

    [<<'T', { a => [1 .. 5] }, <<'X'],
    {counter start=0 skip=2}
    {counter}
    {counter}
    {counter}
T
    0
    2
    4
    6
X

    [<<'T', { a => [1 .. 5] }, <<'X'],
{foreach from=$a item=it -}
    {$it} - {cycle values="foo,bar"} {cycle advance=false}
{/foreach -}
{cycle reset=true print=false advance=false}
{foreach from=$a item=it -}
    {$it} - {cycle values=["foo", "bar", "baz"]}{cycle print=false}
{/foreach -}
T
    1 - foo bar
    2 - bar foo
    3 - foo bar
    4 - bar foo
    5 - foo bar

    1 - foo
    2 - baz
    3 - bar
    4 - foo
    5 - baz
X
);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source, $vars) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

done_testing;
