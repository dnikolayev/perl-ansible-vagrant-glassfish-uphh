#!/usr/bin/perl
use strict;
use warnings;

BEGIN{push @INC, './lib';}
use Getopt::Long;
use GfDeploy::Conf;
use GfDeploy::Action;


my %action_list = (
    #work with settings
    'init'           => {'desc' => 'Initialize Database: --init [--config test.ini]', 
                        'func'  => sub { GfDeploy::Conf->init(@_)}},
    'list_settings'  => {'desc' => 'List Settings: --action list_settings', 
                        'func'  => sub { GfDeploy::Conf->list}},
    'add_setting'    => {'desc' => 'Add New Setting: --action add_setting --setting_name path --setting_value /tmp/123.txt', 
                        'func'  => sub { GfDeploy::Conf->add(@_)}},
    'update_setting' => {'desc' => 'Update Setting: --action update_setting --setting_name path --setting_value /tmp/123.txt', 
                        'func'  => sub { GfDeploy::Conf->update(@_)}},
    'delete_setting' => {'desc' => 'Remove Setting: --action delete_setting --setting_name url', 
                        'func'  => sub { GfDeploy::Conf->remove(@_)}},
    'dump_config'    => {'desc' => 'Dump Config: --action dump_config --config test.ini', 
                        'func'  => sub { GfDeploy::Conf->dump_config(@_)}}, 
    #work with apps
    'check_server_list' => {'desc' => 'Check Deployed Apps from GlassFish: --check_server_list', 
                            'func' => sub { GfDeploy::Action->check_server_list(@_)}},
    'deploy'            => {'desc' => 'Deploy app from file: --deploy --filepath /home/user/hello.war', 
                            'func' => sub { GfDeploy::Action->deploy(@_)}},
    'undeploy'          => {'desc' => 'Undeploy application: --undeploy --appname hello', 
                            'func' => sub { GfDeploy::Action->undeploy(@_)}},
);

sub possible_actions{
    print("Small Tool to deploy/undeploy Java(war) applications. \nPossible Actions:\n");
    foreach my $key (keys %action_list){
      my $value = $action_list{$key}->{'desc'};
      print "$key:  $value\n";
    }
}

sub action_handler {
        my ($opt_name, $opt_value, $action) = @_;
        unless (exists $action_list{$opt_value}) {
            print("action param is not provided\n");
            &possible_actions();
            exit();
        }
}

my %arg = (
    "filepath"      => '',
    "action"        => '',
    "setting_name"  => '',
    "setting_value" => '',
    "config"        => '',
    "appname"       => '',
    "filepath"      => '',
);

GetOptions('filepath=s'          => \$arg{'filepath'},
            'action=s'           => \$arg{'action'},
            'setting_name=s'     => \$arg{'setting_name'},
            'setting_value=s'    => \$arg{'setting_value'},
            'config=s'           => \$arg{'config'},
            'appname=s'          => \$arg{'appname'},
            'filepath=s'         => \$arg{'filepath'}
            );

unless (exists $action_list{$arg{'action'}}) {
    print("action param is not provided\n");
    &possible_actions();
    exit();
}

&{$action_list{$arg{'action'}}->{'func'}}(\%arg);

