package Text::Clevy::Function;
use strict;
use warnings;

use Config::Tiny;

use Text::Xslate::Util qw(p literal_to_value);

require Text::Clevy;
our $EngineClass = 'Text::Clevy';

my @functions = (
    config_load => \&config_load,
);

sub get_table { @functions }

sub config_load {
    my(%args) = @_;

    my $c = Config::Tiny->read($args{file})
        || Carp::croak(Config::Tiny->errstr);

    my $config   = $EngineClass->get_env->config;

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
