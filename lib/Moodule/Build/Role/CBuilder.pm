package Moodule::Build::Role::CBuilder;

use Moo::Role;
use Moodule::Build::Utils 'split_like_shell';

requires qw/log_verbose up_to_date/;

with 'Moodule::Build::Role::RScanDir';

my $split_to_arrayref = sub { [ split_like_shell $_[0] ] };
my $to_arrayref       = sub { ref $_[0] ? $_[0] : [ $_[0] ] };

has 'extra_compiler_flags' => (
  is      => 'rw',
  default => sub { [] },
  coerce  => $split_to_arrayref,
);

has 'extra_linker_flags' => (
  is      => 'rw',
  default => sub { [] },
  coerce  => $split_to_arrayref,
);

has 'include_dirs' => (
  is      => 'rw',
  default => sub { [] },
  coerce  => $to_arrayref,
);

has 'c_source' => (
  is => 'rw',
  default => sub { [] },
  coerce => $to_arrayref,
);

has 'objects' => (
  is => 'rw',
  default => sub { [] },
);

has 'cbuilder' => (
  is => 'lazy',
);

sub _build_cbuilder {
  my $self = shift;
  my %spec;

  if ($self->can('config')) {
    $spec{config} = $self->config;
  }

  if ($self->can('quiet')) {
    $spec{quiet} = 1 if $self->quiet;
  }

  require ExtUtils::CBuilder;
  return ExtUtils::CBuilder->new( %spec );
}

has 'have_c_compiler' => (
  is => 'lazy',
);

sub _build_have_c_compiler {
  my $self = shift;

  $self->log_verbose("Checking if compiler tools configured... ");
  my $b = eval { $self->cbuilder };
  my $have = $b && eval { $b->have_compiler };
  $self->log_verbose($have ? "ok.\n" : "failed.\n");
  return $have;
}

after 'new' => sub {
  my $self = shift;

  #TODO if $self->does('Moodule::Build::Role::Builder')) {
  if ( $self->can('build_elements') ) {
    push @{ $self->build_elements }, 'support';
  }
};

sub compile_c {
  my ($self, $file, %args) = @_;

  if ( ! $self->have_c_compiler ) {
    die "Error: no compiler detected to compile '$file'.  Aborting\n";
  }

  my $b = $self->cbuilder;
  my $obj_file = $b->object_file($file);

  if ( $self->does( 'Moodule::Build::Role::CleanupHelper' ) ) {
    $self->add_to_cleanup($obj_file);
  }

  return $obj_file if $self->up_to_date($file, $obj_file);

  $b->compile(
    source               => $file,
    defines              => $args{defines},
    object_file          => $obj_file,
    include_dirs         => $self->include_dirs,
    extra_compiler_flags => $self->extra_compiler_flags,
  );

  return $obj_file;
}

sub process_support_files {
  my $self = shift;
  my $source = $self->c_source;

  my $files;
  push @{$p->include_dirs}, @$c_source;
  for my $path (@$c_source) {
    push @$files, @{ $self->rscan_dir($path, $self->file_qr('\.c(c|p|pp|xx|\+\+)?$')) };
  }

  foreach my $file (@$files) {
      push @{$p->objects}, $self->compile_c($file);
  }
}

1;


