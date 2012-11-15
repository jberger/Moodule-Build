package Moodule::Build::Base;

use Moo;
use Carp;

use Moodule::Build::HashStore;

sub HashStore {
  my $name = shift or croak "Must specify the name of the HashStore";
  my ($default) = @_;
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
    default => $default 
      ? sub { Moodule::Build::HashStore->new( data => $default ) } 
      : sub { Moodule::Build::HashStore->new },
  );
}

has 'dist_name' => (
  is => 'ro',
  writer => '_set_dist_name',
  trigger => 1,
);

sub _trigger_dist_name {
  my ($self, $name) = @_;
  $name =~ s/-/::/g;
  unless (defined $self->module_name) {
    $self->_set_module_name($name);
  }
}

has 'module_name' => (
  is => 'ro',
  writer => '_set_module_name',
  trigger => 1,
);

sub _trigger_module_name {
  my ($self, $name) = @_;
  $name =~ s/::/-/g;
  unless (defined $self->dist_name) {
    $self->_set_dist_name($name);
  }
}

sub BUILD {
  my $self = shift;
  die "Need either module_name or dist_name\n" unless defined $self->dist_name;
}

1;

