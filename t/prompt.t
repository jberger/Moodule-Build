use strict;
use warnings;
no warnings 'redefine';

use Test::More;

{
  package MyTestClass;
  use Moo;
  with 'Moodule::Build::Role::Prompter';
}

  # Test interactive prompting

  my $ans;
  local $ENV{PERL_MM_USE_DEFAULT};

  local $^W = 0;
  local *{MyTestClass::_readline} = sub { 'y' };

  ok my $mb = MyTestClass->new();

  eval{ $mb->prompt() };
  like $@, qr/called without a prompt/, 'prompt() requires a prompt';

  eval{ $mb->y_n() };
  like $@, qr/called without a prompt/, 'y_n() requires a prompt';

  eval{ $mb->y_n('Prompt?', 'invalid default') };
  like $@, qr/Invalid default/, "y_n() requires a default of 'y' or 'n'";


  $ENV{PERL_MM_USE_DEFAULT} = 1;

  eval{ $mb->y_n('Is this a question?') };
  print "\n"; # fake <enter> because the prompt prints before the checks
  like $@, qr/ERROR:/,
       'Do not allow default-less y_n() for unattended builds';

  eval{ $ans = $mb->prompt('Is this a question?') };
  print "\n"; # fake <enter> because the prompt prints before the checks
  like $@, qr/ERROR:/,
       'Do not allow default-less prompt() for unattended builds';


  # When running Test::Smoke under a cron job, STDIN will be closed which
  # will fool our _is_interactive() method causing various failures.
  {
    local *{MyTestClass::_is_interactive} = sub { 1 };

    $ENV{PERL_MM_USE_DEFAULT} = 0;

    $ans = $mb->prompt('Is this a question?');
    print "\n"; # fake <enter> after input
    is $ans, 'y', "prompt() doesn't require default for interactive builds";

    $ans = $mb->y_n('Say yes');
    print "\n"; # fake <enter> after input
    ok $ans, "y_n() doesn't require default for interactive build";


    # Test Defaults
    *{MyTestClass::_readline} = sub { '' };

    $ans = $mb->prompt("Is this a question");
    is $ans, '', "default for prompt() without a default is ''";

    $ans = $mb->prompt("Is this a question", 'y');
    is $ans, 'y', "  prompt() with a default";

    $ans = $mb->y_n("Is this a question", 'y');
    ok $ans, "  y_n() with a default";

    my @ans = $mb->prompt("Is this a question", undef);
    is_deeply([@ans], [undef], "  prompt() with undef() default");
  }

done_testing;

