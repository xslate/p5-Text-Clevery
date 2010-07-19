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
{config_load file="t/conf/test.conf"}
<h2 style="color:{$smarty.config.titleColor}">{#pageTitle#}</h1>
T

<h2 style="color:black">This is mine</h1>
X

    [<<'T', {foobar => 1}, <<'X'],
{config_load file="t/conf/test.conf"}
<h2 style="color:{ $smarty.config.titleColor }">{ #pageTitle# }</h1>
T

<h2 style="color:black">This is mine</h1>
X

    [<<'T', {foobar => 1}, <<'X'],
{config_load file="t/conf/test.conf" section=foo}
<h2 style="color:{ $smarty.config.foo.titleColor }">{ #foo.pageTitle# }</h1>
T

<h2 style="color:black">This is mine</h1>
X


    [<<'T', {foobar => 1}, <<'X'],
{$smarty.ldelim}foo{$smarty.rdelim}
T
{foo}
X

    [<<'T', { }, <<'X'],
{$smarty.template}
T
&lt;string&gt;
X

    [<<'T', { }, <<'X'],
{if $smarty.version >= 2.6 }version ok{else}unlikely{/if}
T
version ok
X

);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};

    is eval { $tc->render_string($source, $vars, env => \%env) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

$tc = Text::Clevy->new(
    tag_start => '<!--{',
    tag_end   => '}-->',
);

is $tc->render_string(<<'T'), <<'X';
Hello, <!--{ "Clevy" }--> world!
T
Hello, Clevy world!
X

is $tc->render_string(<<'T'), <<'X';
Hello, <!--{ $clevy.ldelim }-->Clevy<!--{ $clevy.rdelim }--> world!
T
Hello, &lt;!--{Clevy}--&gt; world!
X

done_testing;
