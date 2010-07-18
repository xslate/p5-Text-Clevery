package Text::Clevy::Util;
use strict;
use warnings;

use parent qw(Exporter);

our @EXPORT_OK = qw(
    join_html
    make_tag
    true
    false
);

use Text::Xslate::Util qw(
    p
    mark_raw html_escape
);


sub true()  { 1 }
sub false() { 0 }

sub make_tag {
    my $name    = shift;
    my $content = shift;
    my $attrs = '';
    while(my($name, $value) = splice @_, 0, 2) {
        if(defined $value) {
            $attrs .= sprintf q{ %s="%s"}, html_escape($name), html_escape($value);
        }
    }
    if(defined $content) {
        return mark_raw(sprintf q{<%1$s%2$s>%3$s</%1$s>}, $name, $attrs, html_escape($content));
    }
    else {
        return mark_raw(sprintf q{<%1$s%2$s />}, $name, $attrs);
    }
}

sub join_html {
    my $sep = shift;
    return mark_raw join $sep, map { html_escape($_) } @_;
}

1;
