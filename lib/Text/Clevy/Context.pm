package Text::Clevy::Context;
use Any::Moose;
use Plack::Request;

my $smarty_compat_version = '2.6';

has _engine => (
    is  => 'ro',
    isa => 'Object',

    weak_ref => 1,
);

has env => (
    is  => 'ro',
    isa => 'HashRef',

    default => sub { \%ENV },
);

has request => (
    is  => 'ro',
    isa => 'Object',

    lazy    => 1,
    default => sub {
        my($self) = @_;
        return Plack::Request->new( $self->env );
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

sub ldelim {
    my($self) = @_;
    return $self->_engine->{tag_start};
}

sub rdelim {
    my($self) = @_;
    return $self->_engine->{tag_end};
}

sub server { shift()->env }

sub version { $smarty_compat_version }

sub now { time }

sub _build_hashref {
    return {};
}
no Any::Moose;
__PACKAGE__->meta->make_immutable();
