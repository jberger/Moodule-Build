package Moodule::Build::HashStore;

use Moo;
use Carp;
use Exporter 'import';

our @EXPORT_OK = qw/HashStore/;

has 'data' => (
  is => 'ro',
  isa => sub { die 'must be a hash reference' unless ref $_[0] eq 'HASH' },
  default => sub { {} },
);

sub accessor {
  my $self = shift;
  my $data = $self->data;

  return $data unless @_;

  my ($key, $value) = @_;
  if ($value) {
    $data->{$key} = $value;
  }
  return $data->{$key};
}

sub HashStore {
  my $name = shift or croak "Must specify the name of the HashStore";
  my $default = @_ ? shift : {};
  if ($default && ref $default ne 'HASH') {
    croak "HashStore default must be a hash reference";
  }

  return (
    "_$name",
    is => 'rw',
    init_arg => $name,
    handles => { $name => 'accessor' },
    coerce => sub {
      return $_[0] if eval{ $_[0]->isa('Moodule::Build::HashStore') };
      return Moodule::Build::HashStore->new( data => $_[0] );
    },
    default => sub { Moodule::Build::HashStore->new( data => $default ) },
  );
}

1;

