package Moodule::Build::Role::RScanDir;

use Moo::Role;

use File::Find ();

sub rscan_dir {
  my ($self, $dir, $pattern) = @_;
  my @result;
  local $_; # find() can overwrite $_, so protect ourselves
  my $subr = !$pattern ? sub {push @result, $File::Find::name} :
             !ref($pattern) || (ref $pattern eq 'Regexp') ? sub {push @result, $File::Find::name if /$pattern/} :
             ref($pattern) eq 'CODE' ? sub {push @result, $File::Find::name if $pattern->()} :
             die "Unknown pattern type";

  File::Find::find({wanted => $subr, no_chdir => 1}, $dir);
  return \@result;
}

1;

