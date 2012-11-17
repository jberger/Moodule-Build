package MyTestHelper;

use strict;
use warnings;

use Cwd 'getcwd';
use File::Spec ();

use Exporter 'import';

our @EXPORT = ( qw/
  make_file
/ );

sub make_file {
  my $opts = ref $_[-1] ? pop : {};
  my $content = pop;
  my $filename = pop;
  my @path = @_;

  my $old = getcwd;

  for my $dir (@path) {
    unless (-d $dir) {
      mkdir $dir or die "Cannot create new dir $dir\n";
    }
    chdir $dir or die "Cannot chdir into $dir\n";
  }

  open my $fh, '>', $filename;
  print $fh "$content";

  chdir $old;

  my $filepath = File::Spec->catfile(@path, $filename);
  my $unix_filepath = join '/', @path, $filename;

  if ($opts->{test}) {
    require Test::More;
    Test::More::ok( -e $filepath, "File $filepath created" );
  }

  return wantarray ? ($filepath, $unix_filepath) : $filepath;

}

1;


