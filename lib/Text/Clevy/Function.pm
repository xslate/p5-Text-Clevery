package Text::Clevy::Function;
use strict;
use warnings;

use Config::Tiny;

use Text::Xslate::Util qw(p literal_to_value);

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

    my $config = $EngineClass->get_env->config;

    while(my($section_name, $section_config) = each %{$c}) {
        my $storage = $section_name eq '_'
            ?  $config
            : ($config->{$section_name} ||= {});

        while(my($key, $literal) = each %{$section_config}) {
            $storage->{$key} = literal_to_value($literal);
        }
    }
    return;
}

1;
