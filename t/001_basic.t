#!perl -w

use strict;
use Test::More;

use Text::Clevy;
use Text::Clevy::Parser;
use Time::Piece qw(localtime);

my $now = time();

my $tc = Text::Clevy->new(verbose => 2);

my @set = (
    [<<'T', {lang => 'Clevy'}, <<'X'],
Hello, {$lang} world!
T
Hello, Clevy world!
X

    [<<'T', {lang => 'Clevy'}, <<'X'],
Hello, {* this is a comment *}{$lang}{* this is another comment *} world!
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

    [<<'T', {value => "next x-men film, x3, delayed."}, <<'X'],
<em>{$value|capitalize}</em>
<em>{$value|capitalize:false}</em>
<em>{$value|capitalize:true}</em>
T
<em>Next X-Men Film, x3, Delayed.</em>
<em>Next X-Men Film, x3, Delayed.</em>
<em>Next X-Men Film, X3, Delayed.</em>
X

    [<<'T', {value => "foo"}, <<'X'],
<em>{$value|cat:"bar"}</em>
T
<em>foobar</em>
X

    [<<'T', {value => "Cold Wave Linked to Temperatures."}, <<'X'],
    {$value|count_characters}
    {$value|count_characters:true}
T
    29
    33
X

    [<<'T', {now => $now}, sprintf <<'X', localtime($now)->year],
    {$now|date_format:"[%Y]"}
T
    [%s]
X

    [<<'T', {a => undef, b => "", c => "0"}, <<'X'],
    {$a|default: "aaa"}
    {$b|default: "bbb"}
    {$c|default: "ccc"}
T
    aaa
    bbb
    0
X

    [<<'T', {a => "foo", b => "FOO" }, <<'X'],
    {$a|lower}
    {$b|lower}
T
    foo
    foo
X

    [<<'T', {value => "foo\n" . "bar\n"}, <<'X'],
{$value|nl2br}
T
foo<br />bar<br />
X

    [<<'T', {value => 3.14}, <<'X'],
    {$value|string_format: '[%d]'}
T
    [3]
X

    [<<'T', {a => "foo", b => "FOO" }, <<'X'],
    {$a|upper}
    {$b|upper}
T
    FOO
    FOO
X

    [<<'T', {a => "foo"}, <<'X'],
{if $a -}
    [{$a|upper}]
{/if -}
T
    [FOO]
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

);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source, $vars) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

done_testing;
