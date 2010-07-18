use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Text/Clevy.pm';

requires 'Any::Moose'     => 0.13;
requires 'Text::Xslate'   => 0.1047;
requires 'Config::Tiny'   => 2.12;
requires 'Plack'          => 0.9938;
requires 'Image::Size'    => 3.221;

test_requires 'Test::More' => 0.88; # done_testing()

tests_recursive;
author_tests 'xt';

#auto_set_repository() if -d '.git';

clean_files qw(
    Text-Clevy-* *.stackdump
    cover_db
    nytprof
    *.out
);

WriteAll(check_nmake => 0);
