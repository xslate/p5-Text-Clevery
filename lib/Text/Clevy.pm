package Text::Clevy;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.01';

use parent qw(Text::Xslate);
use Text::Clevy::Env;

sub options {
    my($self) = @_;

    my $opts = $self->SUPER::options;

    $opts->{env}    = undef;
    $opts->{syntax} = 'Text::Clevy::Parser';
    # vars
    # funcs
    return $opts;
}

sub new {
    my $self = shift()->SUPER::new(@_);

    if(defined($self->{env})) {
        $self->{_smarty_env}          = Text::Clevy::Env->new(psgi_env => $self->{env});
        $self->{function}{__smarty__} = sub { $self->{_smarty_env} };
    }
    else {
        $self->{function}{__smarty__} = sub {
            $self->_error('$smarty variable requires PSGI env');
        };
    }

    return $self;
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
