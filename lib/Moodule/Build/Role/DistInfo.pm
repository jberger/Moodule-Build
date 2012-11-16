package Moodule::Build::Role::DistInfo;

use Moo::Role;

use Module::Build::ModuleInfo;

requires 'log_warn';

has 'dist_name' => (
  is => 'lazy',
  predicate => '_has_dist_name',
);

sub _build_dist_name {
  my $self = shift;

  die "Can't determine distribution name, must supply either 'dist_name' or 'module_name' parameter"
    unless $self->_has_module_name;

  (my $dist_name = $self->module_name) =~ s/::/-/g;

  return $dist_name;
}

has 'module_name' => (
  is => 'lazy',
  predicate => '_has_module_name',
);

sub _build_module_name {
  my $self = shift;

  if ( $self->_has_dist_version_from && -e $self->dist_version_from ) {
    my $mi = Module::Build::ModuleInfo->new_from_file($self->dist_version_from);
    return $mi->name;
  }
  elsif ($self->_has_dist_name) {
    my $mod_path = my $mod_name = $self->dist_name;
    $mod_name =~ s{-}{::}g;
    $mod_path =~ s{-}{/}g;
    $mod_path .= ".pm";
    if ( -e $mod_path || -e "lib/$mod_path" ) {
      return $mod_name;
    }
  }

  $self->log_warn( <<'END_WARN' );
No 'module_name' was provided and it could not be inferred
from other properties.  This will prevent a packlist from
being written for this file.  Please set either 'module_name'
or 'dist_version_from' in Build.PL.
END_WARN
}

has 'dist_version_from' => (
  is => 'lazy',
  predicate => '_has_dist_version_from',
);

sub _build_dist_version_from {
  my $self = shift;
  if ($self->_has_module_name) {
    return join( '/', 'lib', split(/::/, $self->module_name) ) . '.pm';
  }
  return undef;
}

1;

