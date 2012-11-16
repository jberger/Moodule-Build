use strict;
use warnings;

use Test::More;

use File::Temp ();
use Cwd qw/getcwd/;

my $log = '';
open my $log_handle, '>', \$log;
{
  package MyTestClass;
  use Moo;
  with 'Moodule::Build::Role::DistInfo';
  sub log_warn { shift; print $log_handle @_ }
}

my $old = getcwd;

subtest 'get module_name from dist_name' => sub {
  my $dir = File::Temp->newdir;
  chdir $dir or die "Cannot chdir to $dir\n";

  make_file( qw/lib Not So Simple.pm/, 'Testing' );

  my $mb = MyTestClass->new(
    dist_name => 'Not-So-Simple',
    dist_version => 1,
  );

  is( $mb->module_name, "Not::So::Simple",
    "module_name guessed from dist_name"
  );

  chdir $old;
};

subtest 'cannot determine module_name' => sub {
  my $mb = MyTestClass->new( dist_name => 'Foo-Bar' );
  $mb->module_name;
  ok $log, 'warn on undetermined module_name'; 
};

subtest 'get module_name from dist_version_from' => sub {
  my $dir = File::Temp->newdir;
  chdir $dir or die "Cannot chdir to $dir\n";

  make_file( qw/lib Simple Name.pm/, <<'END_PACKAGE' );
package Simple::Name;
our $VERSION = 1.23;
1;
END_PACKAGE

  my $mb = MyTestClass->new(
    dist_name => 'Random-Name',
    dist_version_from => 'lib/Simple/Name.pm',
  );

  is( $mb->module_name, "Simple::Name",
    "module_name guessed from dist_version_from"
  );

  chdir $old;
};

subtest 'get dist_name from module_name' => sub {
  my $mb = MyTestClass->new( module_name => 'My::Dist' );
  is $mb->dist_name, 'My-Dist', 'dist_name from module_name';
};

subtest 'Constructor without either name' => sub {
  my $builder = MyTestClass->new;
  my $message = eval{ $builder->dist_name } ? 'Did not fail' : $@;
  like $message, qr/Can't determine distribution name/, 'dies without either dist_name or module_name';
};

done_testing;

sub make_file {
  my $content = pop;
  my $filename = pop;

  my $old = getcwd;

  for my $dir (@_) {
    mkdir $dir or die "Cannot create new dir $dir\n";
    chdir $dir or die "Cannot chdir into $dir\n";
  }

  open my $fh, '>', $filename;
  print $fh "$content";

  chdir $old;

}

