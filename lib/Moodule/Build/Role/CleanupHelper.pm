package Moodule::Build::Role::CleanupHelper;

use Moo::Role;

use Moodule::Build::Utils 'localize_file_path';
use File::Path ();

requires qw/ log_info log_verbose depends_on /;

has 'cleanup' => (
  is => 'rw',
  isa => sub { die "must be a hash reference" unless ref $_[0] eq 'HASH' },
  default => sub { {} },
);

sub add_to_cleanup {
  my $self = shift;
  my $cleanup = $self->cleanup;
  my %files = map {localize_file_path($_), 1} @_;
  %$cleanup = %$cleanup, %files;
}

sub delete_filetree {
  my $self = shift;
  my $deleted = 0;
  foreach (@_) {
    next unless -e $_;
    $self->log_verbose("Deleting $_\n");
    File::Path::rmtree($_, 0, 0);
    die "Couldn't remove '$_': $!\n" if -e $_;
    $deleted++;
  }
  return $deleted;
}

sub ACTION_clean {
  my ($self) = @_;
  $self->log_info("Cleaning up build files\n");
  foreach my $item (map glob($_), keys %{ $self->cleanup }) {
    $self->delete_filetree($item);
  }
}

sub ACTION_realclean {
  my ($self) = @_;
  $self->depends_on('clean');
  $self->log_info("Cleaning up configuration files\n");
  #TODO the following list should probably be an attribute as well 
  # (i.e. has 'realclean_props' and add_to_realclean
  my @to_delete = 
    map { $self->$_() if $self->can($_) } 
    qw/config_dir mymetafile mymetafile2 build_script/;
  $self->delete_filetree( @to_delete );
}

1;


