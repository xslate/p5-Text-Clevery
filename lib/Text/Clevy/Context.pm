package Text::Clevy::Context;
use Any::Moose;
use Plack::Request;

my $smarty_compat_version = '2.6';

has psgi_env => (
    is  => 'ro',
    isa => 'HashRef',

    init_arg => 'env',
    default  => \&_build_hashref,
);

has request => (
    is  => 'ro',
    isa => 'Object',

    lazy    => 1,
    default => sub {
        my($self) = @_;
        return Plack::Request->new( $self->psgi_env );
    },

    handles => {
        cookies => 'cookies',
    },
);

has get => (
    is  => 'ro',
    isa => 'HashRef',

    lazy    => 1,
    default => sub {
        my($self) = @_;
        return $self->request->query_parameters->as_hashref();
    },
);

has post => (
    is  => 'ro',
    isa => 'HashRef',

    lazy    => 1,
    default => sub {
        my($self) = @_;
        return $self->request->body_parameters->as_hashref();
    },
);

has session => (
    is  => 'ro',
    isa => 'HashRef',

    lazy    => 1,
    default => \&_build_hashref,
);

has config => (
    is  => 'ro',
    isa => 'HashRef',

    lazy    => 1,
    default => \&_build_hashref,
);

has const => (
    is  => 'ro',
    isa => 'HashRef',

    lazy    => 1,
    default => \&_build_hashref,
);

has capture => (
    is  => 'ro',
    isa => 'HashRef',

    lazy    => 1,
    default => \&_build_hashref,
);

has section => (
    is  => 'ro',
    isa => 'HashRef',

    lazy    => 1,
    default => \&_build_hashref,
);

has foreach => (
    is  => 'ro',
    isa => 'HashRef',

    lazy    => 1,
    default => \&_build_hashref,
);

has template => (
    is  => 'ro',
    isa => 'Str',

    lazy    => 1,
    default => sub { Text::Xslate->get_current_template_name() },
);

has ldelim => (
    is      => 'ro',
    isa     => 'Str',
    default => '{',
);

has ldelim => (
    is      => 'ro',
    isa     => 'Str',
    default => '}',
);

sub env { \%ENV }

sub server { shift()->psgi_env }

sub version { $smarty_compat_version }

sub now { time }

sub _build_hashref {
    return {};
}
no Any::Moose;
__PACKAGE__->meta->make_immutable();
