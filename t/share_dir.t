use strict;
use warnings;

use lib 't';
use MyTestHelper;
use File::Temp ();
use Cwd 'getcwd';

my $old = getcwd;
my $dir = File::Temp->newdir;
chdir $dir or die "Cannot chdir into $dir";

use Test::More;

{
  package MyTestClass;
  use Moo;

  has 'dist_name' => ( is => 'rw', default => sub { 'Simple-Share' } );

  with 'Moodule::Build::Role::RScanDir';
  with 'Moodule::Build::Role::ShareDir';

}

my $module = 'Simple::Share';

# Test without a 'share' dir

my $mb = MyTestClass->new;
is( $mb->share_dir, undef,
  "default share_dir undef if no 'share' dir exists"
);

#ok( ! exists $mb->{properties}{requires}{'File::ShareDir'},
#  "File::ShareDir not added to 'requires'"
#);

# Add 'share' dir and an 'other' dir and content
make_file( qw/share foo.txt/, <<'---', {test => 1} );
This is foo.txt
---
make_file( qw/ share subdir share anotherbar.txt /, <<'---', {test => 1} );
This is anotherbar.txt in a subdir - test for a bug in M::B 0.38 when full path contains 'share/.../*share/...' subdir
---
make_file( qw/ share subdir whatever anotherfoo.txt /, <<'---', {test => 1} );
This is anotherfoo.txt in a subdir - this shoud work on M::B 0.38
---
make_file( qw/ other share bar.txt /, <<'---', {test => 1} );
This is bar.txt
---

# Check default when share_dir is not given
$mb = MyTestClass->new;
is( $mb->share_dir, undef,
  "Default share_dir is undef even if 'share' exists"
);

#ok( ! exists $mb->{properties}{requires}{'File::ShareDir'},
#  "File::ShareDir not added to 'requires'"
#);

# share_dir set to scalar
$mb = MyTestClass->new( share_dir => 'share' );
is_deeply( $mb->share_dir, { dist => [ 'share' ] },
  "Scalar share_dir set as dist-type share"
);

# share_dir set to arrayref
$mb = MyTestClass->new( share_dir => [ 'share' ] );
is_deeply( $mb->share_dir, { dist => [ 'share' ] },
  "Scalar share_dir set as dist-type share"
);

# share_dir set to hashref w scalar
$mb = MyTestClass->new( share_dir => { dist => 'share' } );
is_deeply( $mb->share_dir, { dist => [ 'share' ] },
  "Hashref share_dir w/ scalar dist set as dist-type share"
);

# share_dir set to hashref w array
$mb = MyTestClass->new( share_dir => { dist => [ 'share' ] } );
is_deeply( $mb->share_dir, { dist => [ 'share' ] },
  "Hashref share_dir w/ arrayref dist set as dist-type share"
);

# Generate a module sharedir (scalar)
$mb = MyTestClass->new(
  share_dir => {
    dist => 'share',
    module => { $module =>  'other/share'  },
  },
);
is_deeply( $mb->share_dir,
  { dist => [ 'share' ],
    module => { $module => ['other/share']  },
  },
  "Hashref share_dir w/ both dist and module shares (scalar-form)"
);

# Generate a module sharedir (array)
$mb = MyTestClass->new(
  share_dir => {
    dist => [ 'share' ],
    module => { $module =>  ['other/share']  },
  },
);
is_deeply( $mb->share_dir,
  { dist => [ 'share' ],
    module => { $module => ['other/share']  },
  },
  "Hashref share_dir w/ both dist and module shares (array-form)"
);

#--------------------------------------------------------------------------#
# test constructing to/from mapping
#--------------------------------------------------------------------------#

is_deeply( $mb->_find_share_dir_files,
  {
    "share/foo.txt" => "dist/Simple-Share/foo.txt",
    "share/subdir/share/anotherbar.txt" => "dist/Simple-Share/subdir/share/anotherbar.txt",
    "share/subdir/whatever/anotherfoo.txt" => "dist/Simple-Share/subdir/whatever/anotherfoo.txt",
    "other/share/bar.txt" => "module/Simple-Share/bar.txt",
  },
  "share_dir filemap for copying to lib complete"
);

done_testing;
chdir $old;

__END__

#--------------------------------------------------------------------------#
# test moving files to blib
#--------------------------------------------------------------------------#

$mb->dispatch('build');

ok( -d 'blib', "Build ran and blib exists" );
ok( -d 'blib/lib/auto/share', "blib/lib/auto/share exists" );

my $share_list = Module::Build->rscan_dir('blib/lib/auto/share', sub {-f});

SKIP:
{

skip 'filename case not necessarily preserved', 1 if $^O eq 'VMS';

is_deeply(
  [ sort @$share_list ], [
    'blib/lib/auto/share/dist/Simple-Share/foo.txt',
    'blib/lib/auto/share/dist/Simple-Share/subdir/share/anotherbar.txt',
    'blib/lib/auto/share/dist/Simple-Share/subdir/whatever/anotherfoo.txt',
    'blib/lib/auto/share/module/Simple-Share/bar.txt',
  ],
  "share_dir files copied to blib"
);

}

#--------------------------------------------------------------------------#
# test installing
#--------------------------------------------------------------------------#

my $temp_install = 'temp_install';
mkdir $temp_install;
ok( -d $temp_install, "temp install dir created" );

$mb->install_base($temp_install);
stdout_of( sub { $mb->dispatch('install') } );

$share_list = Module::Build->rscan_dir(
  "$temp_install/lib/perl5/auto/share", sub {-f}
);

SKIP:
{

skip 'filename case not necessarily preserved', 1 if $^O eq 'VMS';

is_deeply(
  [ sort @$share_list ], [
    "$temp_install/lib/perl5/auto/share/dist/Simple-Share/foo.txt",
    "$temp_install/lib/perl5/auto/share/dist/Simple-Share/subdir/share/anotherbar.txt",
    "$temp_install/lib/perl5/auto/share/dist/Simple-Share/subdir/whatever/anotherfoo.txt",
    "$temp_install/lib/perl5/auto/share/module/Simple-Share/bar.txt",
  ],
  "share_dir files correctly installed"
);

}

#--------------------------------------------------------------------------#
# test with File::ShareDir
#--------------------------------------------------------------------------#

SKIP: {
  eval { require File::ShareDir; File::ShareDir->VERSION(1.00) };
  skip "needs File::ShareDir 1.00", 2 if $@;

  unshift @INC, File::Spec->catdir($temp_install, qw/lib perl5/);
  require Simple::Share;

  eval {File::ShareDir::dist_file('Simple-Share','foo.txt') };
  is( $@, q{}, "Found shared dist file" );

  eval {File::ShareDir::module_file('Simple::Share','bar.txt') };
  is( $@, q{}, "Found shared module file" );
}
