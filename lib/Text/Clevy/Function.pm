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
sub _attrs {
    my $s = '';
    while(my($name, $value) = splice @_, 0, 2) {
        if(defined $value) {
            $s .= sprintf q{%s="%s" }, html_escape($name), html_escape($value);
        }
    }
    chop $s;
    return $s;
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


sub html_checkboxes {
    my @extra = _parse_args(
        {@_},
        # name => var_ref, type, required, default
        name      => \my $name,      'Str',          false, 'checkbox',
        values    => \my $values,    'ArrayRef' ,    false, undef,
        output    => \my $output,    'ArrayRef',     false, undef,
        selected  => \my $selected,  'Str|ArrayRef', false, [],
        options   => \my $options,   'HashRef',      false, undef,
        separator => \my $separator, 'Str',          false, q{},
        labels    => \my $labels,    'Bool',         false, true,
    );

    if(not defined $options) {
        $values or _required('values');
        $output or _required('output');
    }

    if(ref $selected ne 'ARRAY') {
        $selected = [$selected];
    }

    my @result;
    for(my $i = 0; $i < @{$values}; $i++) {
        my $id = $values->[$i];

        my $input = sprintf q{<input %s />%s},
            _attrs(
                type  => 'checkbox',
                name  => $name,
                value => $id,
                any_in($id, @{$selected}) ? (checked => 'checked') : (),
                @extra,
            ),
            html_escape($output->[$i]),
        ;

        $input = qq{<label>$input</label>} if $labels;

        push @result, $input . $separator;
    }
    return mark_raw(join "\n", @result);
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

    my $img = sprintf(q{<img %s />},
        _attrs(
            src    => $path_prefix . $file,
            alt    => $alt,
            width  => $width,
            height => $height,
            @extra,
        ));
    if(defined $href) {
        $img = sprintf q{<a href="%s">%s</a>}, html_escape($href), $img;
    }
    return mark_raw($img);
}

no Any::Moose '::Util::TypeConstraints';
1;
