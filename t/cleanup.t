use strict;
use warnings;

use File::Temp ();
use Cwd qw/getcwd/;

use lib 't';
use MyTestHelper;

use Test::More;

my $old = getcwd;
my $dir = File::Temp->newdir;
chdir $dir or die "Cannot chdir to $dir\n";

open my $verbose_handle, '>', \my $verbose;
open my $info_handle,    '>', \my $info;

{
  package MyTestClass;
  use Moo;
  with 'Moodule::Build::Role::CleanupHelper';
  sub log_info    { print $info_handle    @_ }
  sub log_verbose { print $verbose_handle @_ }
  sub depends_on  { 1 }
}

subtest 'add via accessor' => sub {
  my $filename = 'testfile';
  my (undef, $file) = make_file( qw/File Test/, $filename, 'Testing', {test => 1} );

  my $mb = MyTestClass->new;
  $mb->add_to_cleanup($file);

  $verbose = $info = '';
  $mb->ACTION_clean;
  ok( $info, 'clean message' );
  like $verbose, qr/\Q$filename/, 'file deletion message';
  ok( ! -e $file, 'File removed' );
};

subtest 'add via constructor' => sub {
  my $filename = 'testfile';
  my (undef, $file) = make_file( qw/File Test/, $filename, 'Testing', {test => 1} );

  my $mb = MyTestClass->new(
    cleanup => { $file => 1 },
  );

  $verbose = $info = '';
  $mb->ACTION_clean;
  ok( $info, 'clean message' );
  like $verbose, qr/\Q$filename/, 'file deletion message';
  ok( ! -e $file, 'File removed' );
};

chdir $old;

done_testing;

