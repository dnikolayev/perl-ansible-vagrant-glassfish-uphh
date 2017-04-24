package GfDeploy::Schema::Result::Settings;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('settings');

__PACKAGE__->add_columns(

     name => {
         data_type => 'text',
     },

     value => {
         data_type => 'text',
     },
 );

 __PACKAGE__->set_primary_key('name');

 1;