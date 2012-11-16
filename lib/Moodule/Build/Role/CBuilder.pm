package Moodule::Build::Role::CBuilder;

use Moo::Role;

my $to_arrayref = sub { 
  ref $_[0] eq 'ARRAY' ? $_[0] : [ $_[0] ]; 
};

has 'extra_compiler_flags' => (
  is => 'rw',
  default => sub { [] },
  coerce => $to_arrayref,
);

has 'extra_linker_flags' => (
  is => 'rw',
  default => sub { [] },
  coerce => $to_arrayref,
);

1;


