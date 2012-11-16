package Moodule::Build::Role::ExternalCommandHelper;

use Moo::Role;

use Cwd ();
use File::Basename ();
use File::Spec 0.82 ();
use Module::Build::Config;

requires 'log_warn';

# Tells us whether the construct open($fh, '-|', @command) is
# supported.  It would probably be better to dynamically sense this.
has 'have_forkpipe' => (
  is => 'ro',
  default => sub { 1 },
);

has 'perl' => (
  is => 'ro',
  builder => 1,
);

sub _build_perl {
  my $self = shift;
  # The following warning could be unnecessary if the user is running
  # an embedded perl, but there aren't too many of those around, and
  # embedded perls aren't usually used to install modules, and the
  # installation process sometimes needs to run external scripts
  # (e.g. to run tests).
  $self->find_perl_interpreter
    or $self->log_warn("Warning: Can't locate your perl binary");
}

sub _quote_args {
  # Returns a string that can become [part of] a command line with
  # proper quoting so that the subprocess sees this same list of args.
  my ($self, @args) = @_;

  my @quoted;

  for (@args) {
    if ( /^[^\s*?!\$<>;\\|'"\[\]\{\}]+$/ ) {
      # Looks pretty safe
      push @quoted, $_;
    } else {
      # XXX this will obviously have to improve - is there already a
      # core module lying around that does proper quoting?
      s/('+)/'"$1"'/g;
      push @quoted, qq('$_');
    }
  }

  return join " ", @quoted;
}

sub _backticks {
  my ($self, @cmd) = @_;
  if ($self->have_forkpipe) {
    local *FH;
    my $pid = open *FH, "-|";
    if ($pid) {
      return wantarray ? <FH> : join '', <FH>;
    } else {
      die "Can't execute @cmd: $!\n" unless defined $pid;
      exec { $cmd[0] } @cmd;
    }
  } else {
    my $cmd = $self->_quote_args(@cmd);
    return `$cmd`;
  }
}

# Determine whether a given binary is the same as the perl
# (configuration) that started this process.
sub _perl_is_same {
  my ($self, $perl) = @_;

  my @cmd = ($perl);

  # When run from the perl core, @INC will include the directories
  # where perl is yet to be installed. We need to reference the
  # absolute path within the source distribution where it can find
  # it's Config.pm This also prevents us from picking up a Config.pm
  # from a different configuration that happens to be already
  # installed in @INC.
  if ($ENV{PERL_CORE}) {
    push @cmd, '-I' . File::Spec->catdir(File::Basename::dirname($perl), 'lib');
  }

  push @cmd, qw(-MConfig=myconfig -e print -e myconfig);
  return $self->_backticks(@cmd) eq Config->myconfig;
}

# cache _discover_perl_interpreter() results
{
  my $known_perl;
  sub find_perl_interpreter {
    my $self = shift;

    return $known_perl if defined($known_perl);
    return $known_perl = $self->_discover_perl_interpreter;
  }
}

# Returns the absolute path of the perl interpreter used to invoke
# this process. The path is derived from $^X or $Config{perlpath}. On
# some platforms $^X contains the complete absolute path of the
# interpreter, on other it may contain a relative path, or simply
# 'perl'. This can also vary depending on whether a path was supplied
# when perl was invoked. Additionally, the value in $^X may omit the
# executable extension on platforms that use one. It's a fatal error
# if the interpreter can't be found because it can result in undefined
# behavior by routines that depend on it (generating errors or
# invoking the wrong perl.)
sub _discover_perl_interpreter {
  my $proto = shift;
  my $c     = ref($proto) && $proto->can('config') ? $proto->config : 'Module::Build::Config';

  my $perl  = $^X;
  my $perl_basename = File::Basename::basename($perl);

  my @potential_perls;

  # Try 1, Check $^X for absolute path
  push( @potential_perls, $perl )
      if File::Spec->file_name_is_absolute($perl);

  # Try 2, Check $^X for a valid relative path
  my $abs_perl = File::Spec->rel2abs($perl);
  push( @potential_perls, $abs_perl );

  # Try 3, Last ditch effort: These two option use hackery to try to locate
  # a suitable perl. The hack varies depending on whether we are running
  # from an installed perl or an uninstalled perl in the perl source dist.
  if ($ENV{PERL_CORE}) {

    # Try 3.A, If we are in a perl source tree, running an uninstalled
    # perl, we can keep moving up the directory tree until we find our
    # binary. We wouldn't do this under any other circumstances.

    # CBuilder is also in the core, so it should be available here
    require ExtUtils::CBuilder;
    my $perl_src = Cwd::realpath( ExtUtils::CBuilder->perl_src );
    if ( defined($perl_src) && length($perl_src) ) {
      my $uninstperl =
        File::Spec->rel2abs(File::Spec->catfile( $perl_src, $perl_basename ));
      push( @potential_perls, $uninstperl );
    }

  } else {

    # Try 3.B, First look in $Config{perlpath}, then search the user's
    # PATH. We do not want to do either if we are running from an
    # uninstalled perl in a perl source tree.

    push( @potential_perls, $c->get('perlpath') );

    push( @potential_perls,
          map File::Spec->catfile($_, $perl_basename), File::Spec->path() );
  }

  # Now that we've enumerated the potential perls, it's time to test
  # them to see if any of them match our configuration, returning the
  # absolute path of the first successful match.
  my $exe = $c->get('exe_ext');
  foreach my $thisperl ( @potential_perls ) {

    if (defined $exe) {
      $thisperl .= $exe unless $thisperl =~ m/$exe$/i;
    }

    if ( -f $thisperl && $proto->_perl_is_same($thisperl) ) {
      return $thisperl;
    }
  }

  # We've tried all alternatives, and didn't find a perl that matches
  # our configuration. Throw an exception, and list alternatives we tried.
  my @paths = map File::Basename::dirname($_), @potential_perls;
  die "Can't locate the perl binary used to run this script " .
      "in (@paths)\n";
}

# Adapted from IPC::Cmd::can_run()
sub find_command {
  my ($self, $command) = @_;

  if( File::Spec->file_name_is_absolute($command) ) {
    return $self->_maybe_command($command);

  } else {
    for my $dir ( File::Spec->path ) {
      my $abs = File::Spec->catfile($dir, $command);
      return $abs if $abs = $self->_maybe_command($abs);
    }
  }
}

# Copied from ExtUtils::MM_Unix::maybe_command
sub _maybe_command {
  my($self,$file) = @_;
  return $file if -x $file && ! -d $file;
  return;
}

1;

