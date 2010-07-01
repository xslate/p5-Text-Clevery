package Text::Clevy::Function;
use strict;
use warnings;

use Any::Moose '::Util::TypeConstraints';
use Config::Tiny ();

use Text::Xslate::Util qw(
    p any_in literal_to_value
    mark_raw html_escape
);

*_find_type = any_moose('::Util::TypeConstraints')
    ->can('find_or_create_isa_type_constraint');

require Text::Clevy;
our $EngineClass = 'Text::Clevy';

# {capture}, {foreach}, {literal}, {section}, {strip}
# are defined as block statements
my @functions = map { $_ => __PACKAGE__->can($_) || _make_not_impl($_) } qw(
    config_load
    include
    include_php
    insert

    assign
    counter
    cycle
    debug
    eval
    fetch
    html_checkboxes
    html_image
    html_options
    html_radios
    html_select_date
    html_select_time
    html_table
    mailto
    math
    popup
    pupup_init
    textformat
);

use constant { true => 1, false => 0 };

sub get_table { @functions }

sub _make_not_impl {
    my($name) = @_;
    return sub { die "Function $name is not implemented.\n" };
}

sub _required {
    my($name, $level) = @_;
    my $function = (caller($level ? $level + 1 : 1))[3];
    Carp::croak("Required: '$name' attribute for $function");
}

sub _bad_param {
    my($type, $name, $value) = @_;
    Carp::croak("InvalidValue for '$name': " . _find_type($type)->get_message($value));
}


sub config_load {
    my(%args) = @_;

    my $c = Config::Tiny->read($args{file})
        || Carp::croak(Config::Tiny->errstr);

    my $config = $EngineClass->get_current_context->config;

    while(my($section_name, $section_config) = each %{$c}) {
        my $storage = $section_name eq '_'
            ?  $config
            : ($config->{$section_name} ||= {});

        while(my($key, $literal) = each %{$section_config}) {
            $storage->{$key} = literal_to_value($literal);
        }
    }
    return '';
}

# for HTML components
sub _tag {
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

sub _join_html {
    my $sep = shift;
    return mark_raw join $sep, map { html_escape($_) } @_;
}

sub _parse_args {
    my $args = shift;
    if(@_ % 5) {
        Carp::croak("Oops: " . p(@_));
    }
    while(my($name, $var_ref, $type, $required, $default) = splice @_, 0, 5) {
        if(exists $args->{$name}) {
            my $value = delete $args->{$name};
            _find_type->($type)->check($value)
                or _bad_param($type, $name, $value);
            ${$var_ref} = $value;
        }
        elsif($required){
            _required($name, 1);
        }
        else {
#            ${$var_ref} = ref($default) eq 'CODE'
#                ? $default->()
#                : $default;
            ${$var_ref} = $default;
        }
    }
    return if keys(%{$args}) == 0;
    return map { $_ => $args->{$_} } sort keys %{$args};
}

sub _split_assoc_array {
    my($assoc) = @_;
    my @keys;
    my @values;
    if(ref $assoc eq 'HashRef') {
        foreach my $key(sort keys %{$assoc}) {
            push @keys,   $key;
            push @values, $assoc->{$key};
        }
    }
    else {
        foreach my $pair(@{$assoc}) {
            push @keys, $pair->[0];
            push @values, $pair->[1];
        }
    }
    return(\@keys, \@values);
}

sub html_checkboxes {
    my @extra = _parse_args(
        {@_},
        # name => var_ref, type, required, default
        name      => \my $name,      'Str',          false, 'checkbox',
        values    => \my $values,    'ArrayRef' ,    undef, undef,
        output    => \my $output,    'ArrayRef',     undef, undef,
        selected  => \my $selected,  'Str|ArrayRef', false, [],
        options   => \my $options,   'ArrayRef|HashRef', undef, undef,
        separator => \my $separator, 'Str',          false, q{},
        labels    => \my $labels,    'Bool',         false, true,
    );

    if(defined $options) {
        ($values, $output) = _split_assoc_array($options);
    }
    else {
        $values or _required('values');
        $output or _required('output');
    }

    if(ref $selected ne 'ARRAY') {
        $selected = [$selected];
    }

    $separator = mark_raw($separator);

    my @result;
    for(my $i = 0; $i < @{$values}; $i++) {
        my $value = $values->[$i];

        my $input = _join_html('', _tag(
                input => undef,
                type  => 'checkbox',
                name  => $name,
                value => $value,
                any_in($value, @{$selected}) ? (checked => 'checked') : (),
                @extra,
            ), html_escape($output->[$i])),
        ;

        $input = _tag(label => $input) if $labels;

        push @result, _join_html('', $input, $separator);
    }
    return _join_html("\n", @result);
}

sub html_image {
    my @extra = _parse_args(
        {@_},
        # name => var_ref, type, required, default
        file    => \my $file,    'Str', true,  undef,
        height  => \my $height,  'Str', false, undef,
        width   => \my $width,   'Str', false, undef,
        basedir => \my $basedir, 'Str', false, q{},
        alt     => \my $alt,     'Str', false, q{},
        href    => \my $href,    'Str', false, undef,
        path_prefix
                => \my $path_prefix, 'Str', false, '',
    );


    if(!(defined $height and defined $width)) {
        my $image_path;
        if($file =~ m{\A /}xms) {
            $image_path = $file;
        }
        else {
            $image_path = $basedir . $file;
        }
        # TODO: calculate $height and $width from $image_path
    }

    my $img = _tag(
        img    => undef,
        src    => $path_prefix . $file,
        alt    => $alt,
        width  => $width,
        height => $height,
        @extra,
    );
    if(defined $href) {
        $img = _tag(a => $img, href => $href);
    }
    return $img;
}

sub html_options {
    my @extra = _parse_args(
        values   => \my $values,   'ArrayRef',     undef, undef,
        output   => \my $output,   'ArrayRef',     undef, undef,
        selected => \my $selected, 'Str|ArrayRef', false, [],
        options  => \my $options,  'ArrayRef',     undef, undef,
        name     => \my $name,     'Str',          false, undef,
    );

    if(defined $options) {
        ($values, $output) = _split_assoc_array($options);
    }
    else {
        $values or _required('values');
        $output or _required('output');
    }

    if(ref $selected ne 'ARRAY') {
        $selected = [$selected];
    }

    my @result;
    for(my $i = 0; $i < @{$values}; $i++) {
        my $value = $values->[$i];

        push @result, _tag(
            option => $output->[$i],
            value  => $value,
            (any_in($value, @{$selected}) ? (checked => 'checked') : ()),
        );

    }

    return _tag(
        select => _join_html("\n", @result, ''),
        name   => $name,
        @extra,
    );
}

no Any::Moose '::Util::TypeConstraints';
1;
