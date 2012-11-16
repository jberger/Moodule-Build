package Moodule::Build::Base;

use Moo;
use Carp;

use Moodule::Build::HashStore qw/HashStore/;

with 'Moodule::Build::Role::Logger';
with 'Moodule::Build::Role::DistInfo';
with 'Moodule::Build::Role::Prompter';
with 'Moodule::Build::Role::ExternalCommandHelper';
with 'Moodule::Build::Role::CBuilder'; # can this be optional?

1;

