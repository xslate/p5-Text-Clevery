#!perl -w

use strict;
use Test::More;

use Text::Clevery;
use Text::Clevery::Parser;
use Carp ();

my $tc = Text::Clevery->new(
    warn_handler => \&Carp::croak,
    cache        => 0,
);


my @set = (
    [<<'T',  qr/html_checkboxes/],
{html_checkboxes}
T
    [<<'T',  qr/html_checkboxes/],
{html_checkboxes values="foo"}
T
);

for my $d(@set) {
    my($source, $expected, $msg) = @{$d};
    note $source;
    eval { $tc->render_string($source) };
    like $@, $expected, $msg;
}

done_testing;
