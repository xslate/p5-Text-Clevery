package Text::Clevy::Modifier;
use strict;
use warnings;

use Time::Piece ();

use Text::Xslate::Util qw(p html_escape mark_raw);

require Text::Clevy;
our $EngineClass = 'Text::Clevy';

my @modifiers = map { $_ => __PACKAGE__->can($_) || _make_not_impl($_) } qw(
    capitalize
    cat
    count_characters
    count_paragraphs
    count_sentences
    count_words
    date_format
    default
    escape
    indent
    lower
    nl2br
    regex_replace
    replace
    spacify
    string_format
    strip
    strip_tags
    truncate
    upper
    wordwrap
);

sub get_table { @modifiers }

sub _make_not_impl {
    my($name) = @_;
    return sub { die "Modifier $name is not implemented.\n" };
}

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

#sub count_paragraphs
#sub count_sentences
#sub count_words

sub date_format {
    my($time, $format, $default) = @_;
    return $time
        ? Time::Piece->new($time)->strftime($format)
        : $default;
}

sub default {
    my($value, $default) = @_;
    return defined($value) && length($value)
        ? $value
        : $default;
}

#sub escape
#sub indent

sub lower {
    my($str) = @_;
    return lc($str);
}

sub nl2br {
    my($str) = @_;
    return mark_raw(
        join "<br />",
            map { html_escape($_)->as_string() }
                split /\n/, $str, -1
    );
}

#sub regex_replace
#sub replace
#sub spacify

sub string_format {
    my($str, $format) = @_;
    return sprintf $format, $str;
}

#sub strip
#sub strip_tags
#sub truncate

sub upper {
    my($str) = @_;
    return uc($str);
}

#sub wordwrap

1;
