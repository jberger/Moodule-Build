package Moodule::Build::Role::Logger;

use Moo::Role;

has 'quiet'   => ( is => 'rw' );
has 'verbose' => ( is => 'rw' );
has 'debug'   => ( is => 'rw' );

sub log_info {
  my $self = shift;
  print @_ if ref($self) && ( $self->verbose || ! $self->quiet );
}
sub log_verbose {
  my $self = shift;
  print @_ if ref($self) && $self->verbose;
}
sub log_debug {
  my $self = shift;
  print @_ if ref($self) && $self->debug;
}

sub log_warn {
  # Try to make our call stack invisible
  shift;
  if (@_ and $_[-1] !~ /\n$/) {
    my (undef, $file, $line) = caller();
    warn @_, " at $file line $line.\n";
  } else {
    warn @_;
  }
}

1;

