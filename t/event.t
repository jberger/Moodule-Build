use strict;
use warnings;

use Test::More;

my $method_output = 0;

{
  package MyTestClass;
  use Moo;
  with 'Moodule::Build::Role::Event';

  sub log_debug { }
  sub method1 { $method_output = 1 }
}

my $obj = MyTestClass->new;
ok ! defined $obj->emit_event('myevent'), 'emit returns undef on undefined event';

$obj->on_event( myevent => 'method1' );
ok $obj->emit_event('myevent') == 1, 'emit returns number of events';
ok $method_output == 1, 'event methods run';

done_testing;

