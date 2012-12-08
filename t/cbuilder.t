use strict;
use warnings;

use Test::More;

my $output;
{
  package MyTestClass;
  use Moo;
  with 'Moodule::Build::Role::CBuilder';
  sub log_verbose { $output .= $_[1] }
  sub up_to_date { 0 }
}

my $mb = MyTestClass->new(
  extra_compiler_flags => '-I/foo -I/bar',
  extra_linker_flags => '-L/foo -L/bar',
);
is_deeply $mb->extra_compiler_flags, ['-I/foo', '-I/bar'], "Should split shell string into list";
is_deeply $mb->extra_linker_flags,   ['-L/foo', '-L/bar'], "Should split shell string into list";

my $have = $mb->have_c_compiler;
like $output, qr/ok|failed/, 'got some feedback from have_c_compiler';

my $agrees = $output =~ /ok/ ? !!$have : !$have;
ok $agrees, 'message corresponds to have_c_compiler';

done_testing;

