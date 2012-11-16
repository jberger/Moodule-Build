package Moodule::Build::Role::CBuilder;

use Moo::Role;

use Moodule::Build::Utils 'split_like_shell';

my $to_arrayref = sub { [ split_like_shell $_[0] ] };

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


