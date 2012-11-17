package Moodule::Build::Base;

use Moo;
use Carp;

use Moodule::Build::HashStore qw/HashStore/;

sub depends_on { 1 } #TODO remove when depends_on is available

with 'Moodule::Build::Role::Logger';
with 'Moodule::Build::Role::DistInfo';
with 'Moodule::Build::Role::CleanupHelper';
with 'Moodule::Build::Role::Prompter';
with 'Moodule::Build::Role::ExternalCommandHelper';
with 'Moodule::Build::Role::CBuilder'; # can this be optional?
with 'Moodule::Build::Role::ActiveState';

1;

