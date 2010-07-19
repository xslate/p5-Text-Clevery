#!perl -w

use strict;
use Test::More;

use Text::Clevy;
use Text::Clevy::Parser;

my %vpath = (
    foo => <<'T',
Hello, {$lang} world!
T

    bar => <<'T',
----
{include file='foo' -}
----
T

);

my $tc = Text::Clevy->new(
    verbose => 2,
    cache   => 0,
    path    => [\%vpath, 't/template'],
);


my @set = (
    [<<'T', {lang => 'Clevy'}, <<'X'],
{include file="foo" -}
T
Hello, Clevy world!
X

    [<<'T', {lang => 'Clevy'}, <<'X'],
{include file="bar" -}
T
----
Hello, Clevy world!
----
X

    [<<'T', {lang => 'Clevy'}, <<'X'],
{include file="bar" lang="Smarty" -}
T
----
Hello, Smarty world!
----
X

    [<<'T', {}, <<'X'],
{include file="foo.tpl" -}
{include file="bar.tpl" -}
* {#myconf.name#}
T
+ foo
- bar
* foo
X
);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source, $vars) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

done_testing;
