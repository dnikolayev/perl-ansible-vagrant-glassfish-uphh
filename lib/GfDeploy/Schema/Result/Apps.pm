package GfDeploy::Schema::Result::Apps;
use strict;
use warnings;
use base qw/DBIx::Class::TimeStamp DBIx::Class::Core/;

__PACKAGE__->table('apps');

__PACKAGE__->add_columns(

    appname => {
        data_type => 'text',
    },

    filepath => {
        data_type => 'text',
    },

    deployed => {
        data_type => 'text',
    },

    url_works => {
        data_type => 'text',
    },

    t_updated => { data_type => 'datetime',
    	set_on_create => 1, set_on_update => 1 
    },
 );

 __PACKAGE__->set_primary_key('appname');

1;