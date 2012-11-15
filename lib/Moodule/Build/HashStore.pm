package Moodule::Build::HashStore;

use Moo;

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

1;

