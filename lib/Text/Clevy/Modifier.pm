package Text::Clevy::Modifier;
use strict;
use warnings;

use Text::Xslate::Util qw(p);

require Text::Clevy;
our $EngineClass = 'Text::Clevy';

my @modifiers = (
    capitalize       => \&capitalize,
    cat              => \&cat,
    count_characters => \&count_characters,
);

sub get_table { @modifiers }

sub capitalize {
    my($str, $number_as_word) = @_;
    my $word = $number_as_word
        ? qr/\b ([[:alpha:]]\w*) \b/xms
        : qr/\b ([[:alpha:]]+)   \b/xms;

    $str =~ s/$word/ ucfirst($1) /xmseg;
    return $str;
}

sub cat {
    my(@args) = @_;
    return join q{}, @args;
}

sub count_characters {
    my($str, $count_whitespaces) = @_;
    if(!$count_whitespaces) {
        $str =~ s/\s+//g;
    }
    return length($str);
}

1;
