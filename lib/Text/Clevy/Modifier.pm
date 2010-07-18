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

# See smarty3/libs/plugins/modifier.escape.php
sub escape {
    my($str, $format, $encoding) = @_;
    $format   ||= 'html';
    $encoding ||= 'ISO-8859-1';

    if($format eq 'html') {
        return html_escape($str);
    }
    elsif($format eq 'htmlall') {
        require HTML::Entities;
        $str = HTML::Entities::encode($str);
    }
    elsif($format eq 'url' or $format eq 'urlpathinfo') {
        require URI::Escape;
        $str = utf8::is_utf8($str)
            ? URI::Escape::uri_escape_utf8($str)
            : URI::Escape::uri_escape($str);
        if($format eq 'urlpathinfo') {
            $str =~ s{%2F}{/}g;
        }
    }
    elsif($format eq 'quotes') {
        # escapes single quotes and back slashes
        $str =~ s{ ( [\\'] ) }{\\$1}xmsg;
    }
    elsif($format eq 'hex') {
        use bytes;
        $str =~ s{ (.) }{ '%' . unpack('H*', $1) }xmsge;
    }
    elsif($format eq 'hexentity') {
        $str =~ s{ (.) }{ '&#x' . unpack('H*', $1) . ';' }xmsge;
    }
    elsif($format eq 'decentity') {
        $str =~ s{ (.) }{ '&#' . ord($1) . ';' }xmsge;
    }
    elsif($format eq 'javascript') {
        my %map = (
            q{\\}  => q{\\\\},
            q{'}   => q{\\'},
            q{"}   => q{\\"},
            qq{\r} => q{\r},
            qq{\n} => q{\n},
            q{</}  => q{<\/},
        );
        my $pat = join '|', map { quotemeta } keys %map;
        $str =~ s/($pat)/$map{$1}/xmsge;
    }
    elsif($format eq 'mail') {
        $str =~ s/\@/ [AT] /g;
        $str =~ s/\./ [DOT] /g;
    }
    elsif($format eq 'nonstd') {
        use bytes;
        $str =~ s/([^\x00-\x7d])/'&#' . ord($1) . ';'/xmsge;
        $str = mark_raw($str);
    }
    else {
        warnings::warnif(misc => "Unknown escape format '$format' used");
    }
    return mark_raw($str);
}

sub indent {
    my($str, $count, $padding) = @_;
    $count   = 4   if not defined $count;
    $padding = ' ' if not defined $padding;

    $padding x= $count;
    $str =~ s/^/$padding/xmsg;
    return $str;
}

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
