package Text::Clevy;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.0001_02';

sub smarty_compatible_version { '2.6' }

use parent qw(Text::Xslate);

use Carp ();

use Text::Xslate::Util qw(p);
use Text::Clevy::Context;
use Text::Clevy::Function;
use Text::Clevy::Modifier;

my %builtin = (
    '@clevy_context'              => \&get_current_context,
    '@clevy_set_foreach_property' => \&_set_foreach_property,
    '@clevy_array_is_not_empty'   => \&_array_is_not_empty,
    '@clevy_not_implemented'      => \&_not_implemented,
    Text::Clevy::Function->methods(),
    Text::Clevy::Modifier->methods(),
);

sub default_functions { \%builtin }

sub options {
    my($self) = @_;

    my $opts = $self->SUPER::options;

    $opts->{syntax} = 'Text::Clevy::Parser';

    # set delimiters here to make access easier
    $opts->{tag_start} = '{';
    $opts->{tag_end}   = '}';
    return $opts;
}

sub render_string {
    my($self, $str, $vars, @args) = @_;

    local $self->{clevy_context_args} = \@args;
    local $self->{clevy_context};
    return $self->SUPER::render_string($str, $vars);
}

sub render {
    my($self, $str, $vars, @args) = @_;

    local $self->{clevy_context_args} = \@args;
    local $self->{clevy_context};
    return $self->SUPER::render($str, $vars);
}

sub get_current_context {
    my $self = __PACKAGE__->current_engine()
        or Carp::confess("Cannot get clevy context outside render()");
    return $self->{clevy_context} ||= Text::Clevy::Context->new(
            @{$self->{clevy_context_args}},
            _engine => $self,
        );
}

sub _set_foreach_property {
    my($name, $index, $body) = @_;

    my $context = get_current_context();

    my $size = scalar @{$body};
    $context->foreach->{$name} = {
        index => $index,
        iteration => $index + 1,
        first     => $index == 0,
        last      => $index == ($size - 1),
        show      => undef, # ???
        total     => $size,
    };
    return;
}

sub _array_is_not_empty {
    my($arrayref) = @_;
    return defined($arrayref) && @{$arrayref} != 0;
}

sub _not_implemented {
    my($name) = @_;
    die "NotImplemented: $name\n";
}

1;
__END__

=head1 NAME

Text::Clevy - Smarty compatible template engine on Xslate

=head1 VERSION

This document describes Text::Clevy version 0.0001_02.

=head1 SYNOPSIS

    use Text::Clevy;

    my $tc = Text::Clevy->new();

    my %vars = (
        lang => 'Smarty',
    );

    # pass a PSGI request as 'env'
    my $psgi_env = {};
    print $tc->render_string('Hello, {$lang} world!',
        \%vars, env => $psgi_env);

    # or pass a request object as 'request'
    my $request = Plack::Request->new($psgi_env);
    print $tc->render_string('Hello, {$lang} world',
        \%vars, request => $request);

=head1 DESCRIPTION

Text::Clevy is a Smarty compatible template engine implemented
on Xslate.

This software is under development.

=head1 INTERFACE

This is a subclass of Text::Xslate. See L<Text::Xslate> for details

=head1 COMPATIBILITY

=head2 Unsupported features

There are unsupported features, listed as follows.

=over

=item *

C<< {include_php} >>

=item *

C<< {insert} >>

=item *

C<< {php} >>

=item *

C<< {section} >>

=item *

C<< {strip} >>

=item *

C<< {assign} >>

=item *

C<< {debug} >>

=item *

C<< {eval} >>

=item *

C<< {fetch} >>

=item *

C<< {mailto} >>

=item *

C<< {math} >>

=item *

C<< {popup} >>

=item *

C<< {popup_init} >>

=item *

C<< {textformat} >>

=back

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Text::Xslate>

L<http://www.smarty.net/>

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Goro Fuji (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic> for details.

=cut
