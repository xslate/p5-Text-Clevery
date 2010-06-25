package Text::Clevy::Function;
use strict;
use warnings;

use Config::Tiny;

use Text::Xslate::Util qw(
    p any_in literal_to_value
    mark_raw html_escape
);

require Text::Clevy;
our $EngineClass = 'Text::Clevy';

# {capture}, {foreach}, {literal}, {section}, {strip}
# are defined as block statements
my @functions = map { $_ => __PACKAGE__->can($_) || _not_impl($_) } qw(
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

sub _not_impl {
    my($name) = @_;
    return sub { die "Function $name is not implemented.\n" };
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


sub html_checkboxes {
    my(%args) = @_;

    my $name      = $args{name};
    my $values    = $args{values};
    my $output    = $args{output};
    my $selected  = $args{selected};
    my $options   = $args{options};
    my $separator = $args{separator};
    my $assign    = $args{assign};
    my $labels    = $args{labels};

    defined($assign) and die "NotImplemented: 'assign' attribute for html_checkboxes";

    $name      = 'checkbox'
                     if not defined $name;
    $labels    = 1   if not defined $labels;
    $separator = q{} if not defined $separator;

    unless(defined $options) {
        $values or _required('values');
        $output or _required('output');
    }

    if(defined $selected) {
        $selected = [$selected] if ref($selected) ne 'ARRAY';
    }

    my $result = '';
    for(my $i = 0; $i < @{$values}; $i++) {
        $result .= q{<label>} if $labels;

        my $id = $values->[$i];

        my $checked = any_in($id, @{$selected})
            ? q{ checked="checked"}
            : q{}
        ;

        $result .= sprintf
             q{<input type="checkbox" name="%s" value="%s"%s />%s},
             html_escape($name),
             html_escape($id),
             $checked,
             html_escape($output->[$i]),
        ;

        $result .= q{</label>} if $labels;

        $result .= $separator . "\n";
    }
    return mark_raw($result);
}

sub _required {
    my($name) = @_;
    my $function = (caller(1))[3];
    die "Required: '$name' attribute for $function";
}
1;
