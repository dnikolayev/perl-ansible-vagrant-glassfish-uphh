package GfDeploy::Conf;
use strict;
use warnings;
use GfDeploy::Schema;
use Config::Simple;

my $file = 'gfdeploy.db';
my $schema = GfDeploy::Schema->connect("dbi:SQLite:$file");
my $rs;
if (-e $file) {
    $rs = $schema->resultset('Settings');
}

sub init{  
    my ($pass,$args) = @_;
    my $config = '';
    if (exists $args->{'config'} and $args->{'config'}){
        $config = $args->{'config'};
    }
    if (-e $file) {
        print "File already exists, please remove $file to re-initialize";
        exit()
    }
    print("Creating DB file\n");
    $schema->deploy();
    print("Saving Default Settings\n");
    my $rs = $schema->resultset('Settings');
    if ($config and -e $config){

        my $cfg = Config::Simple->import_from($config);
        my $default = $cfg->param(-block=>'default');

        while (my ($key, $value) = each %$default){
            $rs->create({
                name => $key,
                value => $value,
            });
        }
    }
    else{
        $rs->create({
            name => 'path_to_glassfish',
            value => '/opt/glassfish/payara41/',
        });
        $rs->create({
            name => 'main_url',
            value => 'http://127.0.0.1:8080/',
        });
        $rs->create({
            name => 'apps_storage',
            value => '/vagrant/apps/',
        });
        $rs->create({
            name => 'deploy_servers',
            value => 'test',
        });
        $rs->create({
            name => 'local_apps_directory',
            value => './apps',
        });

    }
    print("Initialization Finished\n");
}

sub dump_config{
    my ($pass,$args) = @_;
    my $config = '';
    if (exists $args->{'config'} and $args->{'config'}){
        $config = $args->{'config'};
    }
    unless ($config){
        print("No config provided, exiting..");
        exit();
    }
    if (-e $config){
        print("File $config already exists, please remove it");
        exit();
    }

    my $cfg = new Config::Simple(syntax => 'ini');
    my $query_rs = $rs->search({});
    while (my $item = $rs->next) {
        $cfg->param($item->name, $item->value);
    }
    $cfg->save($config);
    print("Config $config dumped");
}

sub list{
    my $query_rs = $rs->search({});
    print("Here is the list of Settings:\n");
    while (my $item = $rs->next) {
        print("\t".$item->name." => ".$item->value."\n");
    }
}

sub remove{
    my ($pass,$args) = @_;
    my $name = $args->{'setting_name'};

    unless( $name ){
        print("Setting Name is not passed");
        exit();
    }

    my $item = $rs->find($name);

    unless ($item){
        print("Setting does not exist");
        exit();
    }
    
    $item->delete;
    print("Setting $name deleted\n");
}

sub update{
    my ($pass,$args) = @_;
    my $name = $args->{'setting_name'};
    my $value = $args->{'setting_value'};

    unless( $name and $value){
        print("Setting Name or Value is not passed");
        exit();
    }

    my $item = $rs->find($name);

    unless ($item){
        print("Setting does not exist");
        exit();
    }
    
    $item->value( $value );   
    $item->update;

    print("Setting $name updated\n");
}

sub add{
    my ($pass,$args) = @_;
    my $name = $args->{'setting_name'};
    my $value = $args->{'setting_value'};

    unless( $name and $value){
        print("Setting Name or Value is not passed");
        exit()
    }

    my $rs = $schema->resultset('Settings');
    my $item = $rs->find($name);

    if ($item){
        print("Setting already exists");
        exit();
    }
    
    $rs->create({
        name => $name,
        value => $value,
    });   

    print("Setting $name added\n");

}

sub load{
    #non public method to load settings on deploy/undeploy
    my ($pass, @settings_list) = @_;
    my $query_rs;
    if(scalar(@settings_list)){
        $query_rs = $rs->search({ "name" => { '-in' => \@settings_list } });
    }
    else{
        $query_rs = $rs->search({});
    }
    my %res = ();
    while (my $item = $query_rs->next) {
        $res{$item->name} = $item->value;
    }
    return \%res;
}   


1;