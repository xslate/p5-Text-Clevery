#!perl -w
use strict;
use Test::More;

use Text::Clevery;

my $clv = Text::Clevery->new(
    tag_start => '<@',
    tag_end   => '@>',
);

is $clv->render_string('Hello, <@ $lang @> world!', { lang => 'Clevery' }),
    'Hello, Clevery world!';

done_testing;

