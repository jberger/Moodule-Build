use strict;
use warnings;

use Test::More;

use Moodule::Build::HashStore;

subtest 'Without initial data' => sub {
  my $store = Moodule::Build::HashStore->new;
  isa_ok $store, 'Moodule::Build::HashStore';
  is_deeply $store->accessor, {}, 'defaults to unpopulated hashref';
  is $store->accessor('unknown'), undef, 'unknown keys return undef as expected';

  is $store->accessor( key => 'value' ), 'value', 'new value is returned on setter';
  is $store->accessor( 'key' ), 'value', 'getter works';
  is_deeply $store->accessor, { key => 'value' }, 'all data is returned on no args to accessor';
};

subtest 'With initial data' => sub {
  my $store = Moodule::Build::HashStore->new(data => {key => 'value'});
  isa_ok $store, 'Moodule::Build::HashStore';

  is $store->accessor( 'key' ), 'value', 'getter works';
  is_deeply $store->accessor, { key => 'value' }, 'all data is returned on no args to accessor';
};

subtest 'Error message' => sub {
  my $store = eval { Moodule::Build::HashStore->new( data => 'not a hash ref' ) };
  my $message = $store ? 'Did not die' : $@;
  like $message, qr/must be a hash reference/, 'dies when data is initialized without a hashref';
};

done_testing;

