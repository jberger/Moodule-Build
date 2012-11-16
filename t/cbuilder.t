use strict;
use warnings;

use Test::More;

{
  package MyTestClass;
  use Moo;
  with 'Moodule::Build::Role::CBuilder';
}

my $mb = MyTestClass->new(
  extra_compiler_flags => '-I/foo -I/bar',
  extra_linker_flags => '-L/foo -L/bar',
);
is_deeply $mb->extra_compiler_flags, ['-I/foo', '-I/bar'], "Should split shell string into list";
is_deeply $mb->extra_linker_flags,   ['-L/foo', '-L/bar'], "Should split shell string into list";

done_testing;

