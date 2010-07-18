package Text::Clevy::Function;
use strict;
use warnings;

use Any::Moose '::Util::TypeConstraints';
use Config::Tiny ();
use File::Spec;

use Text::Xslate::Util qw(
    p any_in literal_to_value
    mark_raw html_escape
);

use Text::Clevy::Util qw(
    join_html make_tag
    true false
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
    if(ref $assoc eq 'HASH') {
        foreach my $key(sort keys %{$assoc}) {
            push @keys,   $key;
            push @values, $assoc->{$key};
        }
    }
    else {
        foreach my $pair(@{$assoc}) {
            push @keys,   $pair->[0];
            push @values, $pair->[1];
        }
    }
    return(\@keys, \@values);
}

sub html_checkboxes {
    my @extra = _parse_args(
        {@_},
        # name => var_ref, type, required, default
        name      => \my $name,      'Defined',          false, 'checkbox',
        values    => \my $values,    'ArrayRef' ,        undef, undef,
        output    => \my $output,    'ArrayRef',         undef, undef,
        selected  => \my $selected,  'Defined|ArrayRef', false, [],
        options   => \my $options,   'ArrayRef|HashRef', undef, undef,
        separator => \my $separator, 'Defined',          false, q{},
        labels    => \my $labels,    'Bool',             false, true,
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

        my $input = join_html('', make_tag(
                input => undef,
                type  => 'checkbox',
                name  => $name,
                value => $value,
                any_in($value, @{$selected}) ? (checked => 'checked') : (),
                @extra,
            ), html_escape($output->[$i])),
        ;

        $input = make_tag(label => $input) if $labels;

        push @result, join_html('', $input, $separator);
    }
    return join_html("\n", @result);
}

sub html_image {
    my @extra = _parse_args(
        {@_},
        # name => var_ref, type, required, default
        file    => \my $file,    'Defined', true,  undef,
        height  => \my $height,  'Defined', false, undef,
        width   => \my $width,   'Defined', false, undef,
        basedir => \my $basedir, 'Defined', false, q{},
        alt     => \my $alt,     'Defined', false, q{},
        href    => \my $href,    'Defined', false, undef,
        path_prefix
                => \my $path_prefix, 'Defined', false, '',
    );


    if(!(defined $height and defined $width)) {
        eval {
            require Image::Size;
            if($file =~ m{\A /}xms) {
                my $env = $EngineClass->get_current_context->env;
                $basedir = $env->{DOCUMENT_ROOT} || '.';
            }
            my $image_path = File::Spec->catfile($basedir, $file);
            # it returns (undef, undef, $status_message) on fails
            ($width, $height) = Image::Size::imgsize($image_path);
        };
    }

    my $img = make_tag(
        img    => undef,
        src    => $path_prefix . $file,
        alt    => $alt,
        width  => $width,
        height => $height,
        @extra,
    );
    if(defined $href) {
        $img = make_tag(a => $img, href => $href);
    }
    return $img;
}

sub _build_options {
    my($values, $labels, $selected) = @_;
    my @result;
    for(my $i = 0; $i < @{$values}; $i++) {
        my $value = $values->[$i];
        my $label = $labels->[$i];

        if(!(ref($label) eq 'ARRAY' or ref($label) eq 'HASH')) {
            push @result, make_tag(
                option => $label,
                # label => $label,
                value  => $value,
                (any_in($value, @{$selected}) ? (selected => 'selected') : ()),
            );
        }
        else {
            my($v, $l) = _split_assoc_array($label);
            my @group = _build_options($v, $l, $selected);
            push @result, make_tag(
                optgroup => join_html("\n", "", @group, ""),
                label    => $value,
            );

        }
    }
    return @result;
}

sub html_options {
    my @extra = _parse_args(
        {@_},
        values   => \my $values,   'ArrayRef',         undef, undef,
        output   => \my $output,   'ArrayRef',         undef, undef,
        selected => \my $selected, 'Defined|ArrayRef', false, [],
        options  => \my $options,  'ArrayRef|HashRef', undef, undef,
        name     => \my $name,     'Defined',          false, undef,
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

    my @result = _build_options($values, $output, $selected);

    if(defined $name) {
        return make_tag(
            select => join_html("\n", '', @result, ''),
            name   => $name,
            @extra,
        );
    }
    else {
        return join_html("\n", @result);
    }
}

no Any::Moose '::Util::TypeConstraints';
1;
