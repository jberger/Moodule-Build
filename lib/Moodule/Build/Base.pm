package Moodule::Build::Base;

use Moo;
use Carp;

use Moodule::Build::HashStore qw/HashStore/;

with 'Moodule::Build::Role::Logger';
with 'Moodule::Build::Role::Prompter';
with 'Moodule::Build::Role::ExternalCommandHelper';

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

