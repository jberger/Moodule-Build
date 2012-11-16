use strict;
use warnings;

use Test::More;

use Moodule::Build::Base;
use Moodule::Build::HashStore qw/HashStore/;

{
  package MyTestClass;
  use Moo;
  has main::HashStore( 'attr' );
}

subtest 'No default, no initial data' => sub {
  my $obj = MyTestClass->new;
  isa_ok $obj->_attr, 'Moodule::Build::HashStore';
  can_ok $obj, 'attr';

  is_deeply $obj->attr, {}, 'defaults to unpopulated hashref';
  is $obj->attr('unknown'), undef, 'unknown keys return undef as expected';

  is $obj->attr( key => 'value' ), 'value', 'new value is returned on setter';
  is $obj->attr( 'key' ), 'value', 'getter works';
  is_deeply $obj->attr, { key => 'value' }, 'all data is returned on no args to accessor';
};

subtest 'No default, with initial data (hash)' => sub {
  my $obj = MyTestClass->new(attr => {key => 'value'});
  isa_ok $obj->_attr, 'Moodule::Build::HashStore';
  can_ok $obj, 'attr';

  is $obj->attr( 'key' ), 'value', 'getter works';
  is_deeply $obj->attr, { key => 'value' }, 'all data is returned on no args to accessor';
};

subtest 'No default, with initial data (obj)' => sub {
  my $hash = Moodule::Build::HashStore->new( data => {key => 'value'} );
  my $obj = MyTestClass->new(attr => $hash);
  isa_ok $obj->_attr, 'Moodule::Build::HashStore';
  can_ok $obj, 'attr';

  is $obj->attr( 'key' ), 'value', 'getter works';
  is_deeply $obj->attr, { key => 'value' }, 'all data is returned on no args to accessor';
};

{
  package MyTestClassDefault;
  use Moo;
  has main::HashStore( 'attr' => { key => 'value' } );
}

subtest 'With default, no initial data' => sub {
  my $obj = MyTestClassDefault->new;
  isa_ok $obj->_attr, 'Moodule::Build::HashStore';
  can_ok $obj, 'attr';

  is $obj->attr( 'key' ), 'value', 'getter works';
  is_deeply $obj->attr, { key => 'value' }, 'all data is returned on no args to accessor';
};

subtest 'No default, with initial data (hash)' => sub {
  my $obj = MyTestClassDefault->new(attr => {key => 'othervalue'});
  isa_ok $obj->_attr, 'Moodule::Build::HashStore';
  can_ok $obj, 'attr';

  is $obj->attr( 'key' ), 'othervalue', 'getter works';
  is_deeply $obj->attr, { key => 'othervalue' }, 'all data is returned on no args to accessor';
};

subtest 'Error message' => sub {
  my $store = eval { MyTestClass->new( attr => 'not a hash ref' ) };
  my $message = $store ? 'Did not die' : $@;
  like $message, qr/must be a hash reference/, 'dies when data is initialized without a hashref';
};

done_testing;

