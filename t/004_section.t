#!perl -w

use strict;
use Test::More skip_all => 'not yet implemented';

use Text::Clevy;
use Text::Clevy::Parser;

my $tc = Text::Clevy->new(verbose => 2);

my @set = (
#TODO
);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source, $vars) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

done_testing;
