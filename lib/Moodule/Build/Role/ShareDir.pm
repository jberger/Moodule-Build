package Moodule::Build::Role::ShareDir;

use Moo::Role;

requires qw/rscan_dir blib copy_if_modified dist_name/;

use File::Spec;

my $coerce = sub {
  my $share_dir = shift;

  # Always coerce to proper hash form
  if    ( ! defined $share_dir ) {
    return;
  }
  elsif ( ! ref $share_dir ) {
    # scalar -- treat as a single 'dist' directory
    return { dist => [ $share_dir ] };
  }
  elsif ( ref $share_dir eq 'ARRAY' ) {
    # array -- treat as a list of 'dist' directories
    return { dist => $share_dir };
  }
  elsif ( ref $share_dir ne 'HASH' ) {
    return $share_dir; # dies on isa check
  }

  # hash -- check structure
  # check dist key
  if ( defined $share_dir->{dist} ) {
    if ( ! ref $share_dir->{dist} ) {
      # scalar, so upgrade to arrayref
      $share_dir->{dist} = [ $share_dir->{dist} ];
    }
  }

  # check module key
  if ( defined $share_dir->{module} ) {
    my $mod_hash = $share_dir->{module};
    if ( ref $mod_hash eq 'HASH' ) {
      for my $k ( keys %$mod_hash ) {
        next if ref $mod_hash->{$k};
        $mod_hash->{$k} = [ $mod_hash->{$k} ];
      }
    }
  }

  return $share_dir;
};

my $isa = sub {
  my $share_dir = shift;
  return if ! defined $share_dir;

  die "'share_dir' must be hashref, arrayref or string"
    unless ref $share_dir eq 'HASH';

  if ( 
    defined $share_dir->{dist}
    && ref $share_dir->{dist} ne 'ARRAY'
  ) {
    die "'dist' key in 'share_dir' must be scalar or arrayref";
  }

  return unless defined ( my $mod_hash = $share_dir->{module} );

  die "'module' key in 'share_dir' must be hashref"
    unless ref $mod_hash eq 'HASH';

  die "modules in 'module' key of 'share_dir' must be scalar or arrayref"
    if grep { ref ne 'ARRAY' } values %$mod_hash;
};

has 'share_dir' => (
  is => 'rw',
  coerce => $coerce,
  isa => $isa,
);

sub process_share_dir_files {
  my $self = shift;
  my $files = $self->_find_share_dir_files;
  return unless $files;

  # root for all File::ShareDir paths
  my $share_prefix = File::Spec->catdir($self->blib, qw/lib auto share/);

  # copy all share files to blib
  while (my ($file, $dest) = each %$files) {
    $self->copy_if_modified(
      from => $file, to => File::Spec->catfile( $share_prefix, $dest )
    );
  }
}

sub _find_share_dir_files {
  my $self = shift;
  my $share_dir = $self->share_dir;
  return unless $share_dir;

  my @file_map;
  if ( $share_dir->{dist} ) {
    my $prefix = "dist/".$self->dist_name;
    push @file_map, $self->_share_dir_map( $prefix, $share_dir->{dist} );
  }

  if ( $share_dir->{module} ) {
    for my $mod ( keys %{ $share_dir->{module} } ) {
      (my $altmod = $mod) =~ s{::}{-}g;
      my $prefix = "module/$altmod";
      push @file_map, $self->_share_dir_map($prefix, $share_dir->{module}{$mod});
    }
  }

  return { @file_map };
}

sub _share_dir_map {
  my ($self, $prefix, $list) = @_;
  my %files;
  for my $dir ( @$list ) {
    for my $f ( @{ $self->rscan_dir( $dir, sub {-f} )} ) {
      $f =~ s{\A.*?\Q$dir\E/}{};
      $files{"$dir/$f"} = "$prefix/$f";
    }
  }
  return %files;
}

1;

