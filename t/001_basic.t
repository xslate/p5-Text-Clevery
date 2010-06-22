#!perl -w

use strict;
use Test::More;

use Text::Clevy;

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

);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source, $vars) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

done_testing;
