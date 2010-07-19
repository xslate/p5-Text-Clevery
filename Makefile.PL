use strict;
use warnings;
use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::Repository;

all_from 'lib/Text/Clevy.pm';

requires 'Any::Moose'     => 0.13;
requires 'Text::Xslate'   => 0.1047;
requires 'Plack'          => 0.9938; # Plack::Request

requires 'Config::Tiny'   => 2.12;
requires 'Image::Size'    => 3.22;
requires 'HTML::Entities' => 1.35;
requires 'URI::Escape'    => 3.30;
requires 'Time::Piece'    => 1.12;

test_requires 'Test::More' => 0.88; # done_testing()

tests_recursive;
author_tests 'xt';

auto_set_repository() if -d '.git';

clean_files qw(
    Text-Clevy-* *.stackdump
    cover_db
    nytprof
    *.out
);

WriteAll(check_nmake => 0);
