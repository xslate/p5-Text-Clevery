#!perl -w

use strict;
use Test::More;

use Text::Clevy;
use Text::Clevy::Parser;
use Time::Piece ();

my $now = time();

my $tc = Text::Clevy->new(verbose => 2);

my @set = (
    [<<'T', {lang => 'Clevy'}, <<'X'],
Hello, {$lang} world!
T
Hello, Clevy world!
X

    [<<'T', {h => { lang => 'Clevy' }}, <<'X'],
Hello, {$h.lang} world!
T
Hello, Clevy world!
X

    [<<'T', {h => { lang => 'Clevy' }, f => 'lang' }, <<'X'],
Hello, {$h.$f} world!
T
Hello, Clevy world!
X

    [<<'T', {a => ['Clevy'] }, <<'X'],
Hello, {$a[0]} world!
T
Hello, Clevy world!
X

    [<<'T', { x => 32 }, <<'X'],
    {$x + 10}
T
    42
X

    [<<'T', {now => Time::Piece->new($now)}, Time::Piece->new($now)->year, 'dot field'],
{ $now.year -}
T

    [<<'T', {now => Time::Piece->new($now)}, Time::Piece->new($now)->year, 'dot method'],
{ $now.year() -}
T

    [<<'T', {now => Time::Piece->new($now)}, Time::Piece->new($now)->year, 'arrow field'],
{ $now->year -}
T

    [<<'T', {now => Time::Piece->new($now)}, Time::Piece->new($now)->year, 'arrow method'],
{ $now->year() -}
T

    [<<'T', {lang => 'Clevy' }, <<'X'],
Hello, {ldelim}{$lang}{rdelim} world!
T
Hello, {Clevy} world!
X

    [<<'T', {lang => 'Clevy'}, <<'X'],
Hello, {* this is a comment *}{$lang}{* this is another comment *} world!
T
Hello, Clevy world!
X

    [<<'T', {lang => 'Clevy'}, <<'X'],
Hello, {$lang} world!{* comment
 comment
 comment *}
T
Hello, Clevy world!
X

    [<<'T', {lang => 'Clevy'}, <<'X'],
    ---
{if $lang}
    ok
{/if}
    ---
T
    ---

    ok

    ---
X

    [<<'T', {lang => 'Clevy'}, <<'X'],
    ---
{if $lang}
    ok
{else}
    unlikely
{/if}
    ---
T
    ---

    ok

    ---
X

    [<<'T', {}, <<'X'],
    ---
{if $lang}
    unlikely
{else}
    ok
{/if}
    ---
T
    ---

    ok

    ---
X

    [<<'T', {foobar => 1}, <<'X'],
    ---
{if $lang}
    unlikely
{elseif $foobar}
    ok
{else}
    unlikely
{/if}
    ---
T
    ---

    ok

    ---
X

    [<<'T', { a => [qw(foo bar baz)] }, <<'X'],
{foreach from=$a item=it -}
    [{$it}]
{/foreach -}
T
    [foo]
    [bar]
    [baz]
X

    [<<'T', { a => { b => [qw(foo bar baz)] }}, <<'X'],
{foreach from=`$a.b` item=it -}
    [{$it}]
{/foreach -}
T
    [foo]
    [bar]
    [baz]
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

    [<<'T', { value => 'foo' }, <<'X'],
{literal}[{$value}]{/literal}
T
[{$value}]
X


    [<<'T', { a => [] }, <<'X'],
{literal}
{foreach from=$a item=it -}
    [{$it}]
{/foreach -}
{/literal}
T

{foreach from=$a item=it -}
    [{$it}]
{/foreach -}

X

    [<<'T', { a => [] }, <<'X', 'parse'],
foo{foreach
    from=$a
    item=it
  }{/foreach}bar
T
foobar
X

    [<<'T', { a => [] }, <<'X', 'parse'],
foo{foreach
    from=$a
    item=it
  }{/foreach}bar
T
foobar
X
);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source, $vars) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

done_testing;
