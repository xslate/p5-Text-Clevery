#!perl -w

use strict;
use Test::More;

use Text::Clevy;
use Text::Clevy::Parser;

my $tc = Text::Clevy->new();

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

    [<<'T', {foobar => 1}, <<'X'],
{config_load file="t/conf/test.ini"}
<h2 style="color:{$smarty.config.titleColor}">{#pageTitle#}</h1>
T

<h2 style="color:black">This is mine</h1>
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
);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source, $vars) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

done_testing;
