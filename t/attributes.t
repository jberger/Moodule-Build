use strict;
use warnings;

use Test::More;

use Moodule::Build;

subtest 'Constructor with dist_name' => sub {
  my $builder = Moodule::Build->new( dist_name => 'My-Dist' );
  isa_ok $builder, 'Moodule::Build';
  is $builder->module_name, 'My::Dist', 'module_name from dist_name';
};

subtest 'Constructor with module_name' => sub {
  my $builder = Moodule::Build->new( module_name => 'My::Dist' );
  isa_ok $builder, 'Moodule::Build';
  is $builder->dist_name, 'My-Dist', 'dist_name from module_name';
};

subtest 'Constructor with both names' => sub {
  my $builder = Moodule::Build->new( module_name => 'A', dist_name => 'B' );
  isa_ok $builder, 'Moodule::Build';
  is $builder->module_name, 'A', 'set both names (module)';
  is $builder->dist_name, 'B', 'set both names (dist)';
};

subtest 'Constructor without either name' => sub {
  my $builder = eval { Moodule::Build->new };
  my $message = $builder ? 'Did not fail' : $@;
  is $message, "Need either module_name or dist_name\n", 'throw error on no build_name or dist_name';
};

done_testing();

