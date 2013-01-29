package Moodule::Build::Role::Event;
use Moo::Role;

requires 'log_debug';

has 'events' => (
  is => 'rw',
  default => sub { {} },
);

sub on_event {
  my $self = shift;
  my ($event, $method) = @_;
  push @{$self->events->{$event}}, $method;
}

sub emit_event {
  my $self = shift;
  my ($event) = @_;
  $self->log_debug( "Emitting: $event\n" );

  my $methods = $self->events->{$event};
  return undef unless defined $methods;

  my $count = 0;
  foreach my $method_name (@$methods) {
    my $method = $self->can($method_name) 
      or die "Cannot find registered method $method_name (event: $event)";
    $self->log_debug( "Triggering method: $method_name\n" );
    $self->$method();
    $count++;
  }

  return $count;
}

1;

