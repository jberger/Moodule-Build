package Moodule::Build::Utils;

use strict;
use warnings;

use Exporter 'import';

use Text::ParseWords ();

our @EXPORT_OK = ( qw/
  split_like_shell
/ );

sub split_like_shell {
  my ($string) = @_;

  return () unless defined($string);
  return @$string if ref($string) eq 'ARRAY';
  $string =~ s/^\s+|\s+$//g;
  return () unless length($string);

  return Text::ParseWords::shellwords($string);
}

