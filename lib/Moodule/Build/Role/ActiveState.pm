package Moodule::Build::Role::ActiveState;

use Moo::Role;

has '_is_ActivePerl' => ( is => 'lazy' );
sub _build_is_ActivePerl { eval { require ActivePerl::DocTools; } || 0 }

has '_is_ActivePPM'  => ( is => 'lazy' );
sub _build_is_ActivePPM { eval { require ActivePerl::PPM; } || 0 }

1;

