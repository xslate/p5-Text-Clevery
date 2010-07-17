#!perl -w

use strict;
use Test::More;

my $now;
BEGIN{
    $now = time();
    *CORE::GLOBAL::time = sub { $now }; # mock
}

use Text::Clevy;
use Text::Xslate::Util qw(html_escape);


my %env = (
    %ENV,
    CLEVY_TESTING => 'Smarty',
    QUERY_STRING  => 'foo=bar;bar=baz;lang=Xslate',
    SERVER_NAME   => 'my.host',
);
my $tc = Text::Clevy->new(verbose => 2);

my @set = (
    [<<'T', {}, sprintf(<<'X', html_escape($env{QUERY_STRING}))],
Hello, {$smarty.server.QUERY_STRING} world!
T
Hello, %s world!
X

    [<<'T', {}, <<'X'],
Hello, {$smarty.env.CLEVY_TESTING} world!
T
Hello, Smarty world!
X

    [<<'T', {}, <<'X'],
Hello, {$smarty.get.lang} world!
T
Hello, Xslate world!
X

    [<<'T', {}, <<'X'],
Hello, {$smarty.get.foo} world!
T
Hello, bar world!
X

    [<<'T', {}, <<'X'],
Hello, {$smarty.server.SERVER_NAME} world!
T
Hello, my.host world!
X

    [<<'T', {}, sprintf <<'X', $now],
Hello, {$smarty.now} world!
T
Hello, %s world!
X


    [<<'T', {foobar => 1}, <<'X'],
{config_load file="t/conf/test.ini"}
<h2 style="color:{$smarty.config.titleColor}">{#pageTitle#}</h1>
T

<h2 style="color:black">This is mine</h1>
X

);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};

    is eval { $tc->render_string($source, $vars, env => \%env) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

done_testing;
