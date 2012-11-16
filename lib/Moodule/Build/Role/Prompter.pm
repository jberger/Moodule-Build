package Moodule::Build::Role::Prompter;

use Moo::Role;

sub _is_interactive {
  return -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;   # Pipe?
}

# NOTE this is a blocking operation if(-t STDIN)
sub _is_unattended {
  my $self = shift;
  return $ENV{PERL_MM_USE_DEFAULT} ||
    ( !$self->_is_interactive && eof STDIN );
}

sub _readline {
  my $self = shift;
  return undef if $self->_is_unattended;

  my $answer = <STDIN>;
  chomp $answer if defined $answer;
  return $answer;
}

sub prompt {
  my $self = shift;
  my $mess = shift
    or die "prompt() called without a prompt message";

  # use a list to distinguish a default of undef() from no default
  my @def;
  @def = (shift) if @_;
  # use dispdef for output
  my @dispdef = scalar(@def) ?
    ('[', (defined($def[0]) ? $def[0] . ' ' : ''), ']') :
    (' ', '');

  local $|=1;
  print "$mess ", @dispdef;

  if ( $self->_is_unattended && !@def ) {
    die <<EOF;
ERROR: This build seems to be unattended, but there is no default value
for this question.  Aborting.
EOF
  }

  my $ans = $self->_readline();

  if ( !defined($ans)        # Ctrl-D or unattended
       or !length($ans) ) {  # User hit return
    print "$dispdef[1]\n";
    $ans = scalar(@def) ? $def[0] : '';
  }

  return $ans;
}

sub y_n {
  my $self = shift;
  my ($mess, $def)  = @_;

  die "y_n() called without a prompt message" unless $mess;
  die "Invalid default value: y_n() default must be 'y' or 'n'"
    if $def && $def !~ /^[yn]/i;

  my $answer;
  while (1) { # XXX Infinite or a large number followed by an exception ?
    $answer = $self->prompt(@_);
    return 1 if $answer =~ /^y/i;
    return 0 if $answer =~ /^n/i;
    local $|=1;
    print "Please answer 'y' or 'n'.\n";
  }
}

1;

