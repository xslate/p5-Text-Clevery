package Text::Clevy;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.01';

use parent qw(Text::Xslate);
use Text::Xslate::Util qw(p literal_to_value);
use Text::Clevy::Env;
use Config::Tiny;

my %builtin = (
    # functions
    config_load => \&_f_config_load,

    # modifiers
    cat              => \&_m_cat,
    capitalize       => \&_m_capitalize,
    count_characters => \&_m_count_characters,
);

sub options {
    my($self) = @_;

    my $opts = $self->SUPER::options;

    $opts->{env}    = {};
    $opts->{syntax} = 'Text::Clevy::Parser';
    # vars
    # funcs
    return $opts;
}

sub new {
    my $self = shift()->SUPER::new(@_);

    $self->{_smarty_env}          = Text::Clevy::Env->new(psgi_env => $self->{env});
    $self->{function}{__smarty__} = sub { $self->{_smarty_env} };

    while(my($name, $body) = each %builtin) {
        $self->{function}{$name} = sub { unshift @_, $self; goto &{$body} };
    }

    return $self;
}

sub _f_config_load {
    my($self, %args) = @_;

    my $c = Config::Tiny->read($args{file})
        || Carp::croak(Config::Tiny->errstr);

    my $config   = $self->{_smarty_env}->config;

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

sub _m_capitalize {
    my($self, $str, $number_as_word) = @_;
    my $word = $number_as_word
        ? qr/\b ([[:alpha:]]\w*) \b/xms
        : qr/\b ([[:alpha:]]+)   \b/xms;

    $str =~ s/$word/ ucfirst($1) /xmseg;
    return $str;
}

sub _m_cat {
    my($self, @args) = @_;
    return join q{}, @args;
}

sub _m_count_characters {
    my($self, $str, $count_whitespaces) = @_;
    if(!$count_whitespaces) {
        $str =~ s/\s+//g;
    }
    return length($str);
}


1;
__END__

=head1 NAME

Text::Clevy - Smarty compatible template engine on Xslate

=head1 VERSION

This document describes Text::Clevy version 0.01.

=head1 SYNOPSIS

    use Text::Clevy;

    my $tc = Text::Clevy->new();

    print $tc->render_str('Hello, {$lang} world!', {
        lang => 'Smarty',
    });

=head1 DESCRIPTION

Text::Clevy provides blah blah blah.

=head1 INTERFACE

=head2 Class methods

=over 4

=item *

=back

=head2 Instance methods

=over 4

=item *

=back


=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Text::Xslate>

L<http://smarty.php.net/>

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Goro Fuji (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic> for details.

=cut
