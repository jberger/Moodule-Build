package Moodule::Build::Utils;

use strict;
use warnings;

use Exporter 'import';

use Text::ParseWords ();

our @EXPORT_OK = ( qw/
  split_like_shell
  localize_file_path
  localize_dir_path
/ );

sub split_like_shell {
  my ($string) = @_;

  return () unless defined($string);
  return @$string if ref($string) eq 'ARRAY';
  $string =~ s/^\s+|\s+$//g;
  return () unless length($string);

  return Text::ParseWords::shellwords($string);
}

sub localize_file_path {
  my ($path) = @_;
  return File::Spec->catfile( split m{/}, $path );
}

sub localize_dir_path {
  my ($path) = @_;
  return File::Spec->catdir( split m{/}, $path );
}

