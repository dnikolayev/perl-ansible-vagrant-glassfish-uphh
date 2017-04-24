package GfDeploy::Action;
use strict;
use warnings;
use GfDeploy::Schema;
use GfDeploy::Conf;
use JSON;
use LWP::UserAgent;
use File::Spec;
use File::Copy;
use File::Basename;
use Cwd qw(abs_path);

my $file = 'gfdeploy.db';
my $schema = GfDeploy::Schema->connect("dbi:SQLite:$file");

sub __parse_ansible_output{
    my $text = shift;
    my @arr = split /=>/, $text;
    my $json = decode_json($arr[1]);
    return $json;
}

sub __check_status{
    my $url = shift;
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    my $response = $ua->get($url);
    if ($response->is_success) {
        return 1;
    }
    else {
        return 0;
    }
}

sub __update_app{
    my $args = shift;
    my ($appname, $filepath, $deployed, $url_works) = ($args->{'appname'}, $args->{'filepath'}, $args->{'deployed'}, $args->{'url_works'});
    
    my $rs = $schema->resultset('Apps');
    my $item = $rs->find($appname);

    unless ($item){
        $item = $rs->create({
            "appname" => $appname,
            "filepath" => $filepath?$filepath:'not_set',
            "deployed" => $deployed,
            "url_works" => $url_works
        });
    }
    else{
        $item->filepath( $filepath ) if $filepath;   
        $item->deployed( $deployed ) if $deployed;  
        $item->url_works( $url_works ) if $url_works;
        $item->update;
    }
}

sub deploy{
    my ($pass,$args) = @_;
    my $settings = GfDeploy::Conf->load();

    my $original_file_location = $args->{'filepath'};
    my $path_to_glassfish = $settings->{'path_to_glassfish'};
    my $baseurl = $settings->{'main_url'};

    my $filename = fileparse($original_file_location);
    my $local_new_path = File::Spec->catfile($settings->{'local_apps_directory'}, $filename);
    
    unless (abs_path($original_file_location) eq abs_path($local_new_path)){
        if (-e $local_new_path){
            unlink($local_new_path) or die "Unlink of existing file failed: $!";
        }

        copy($original_file_location,$local_new_path) or die "Copy failed: $!";
    }
    
    my $filepath = File::Spec->catfile($settings->{'apps_storage'}, $filename);


    my $res = `ansible test -m glassdeploy -a "action=deploy path_to_glassfish=$path_to_glassfish filepath=$filepath"`;
    my $data = __parse_ansible_output($res);
    
    if ($data->{'result'}->{'status'}){
        my $appname = $data->{'result'}->{'appname'};
        my $app_url = $baseurl . $appname . '/';
        my $check_url = __check_status($app_url);
        
        
        __update_app({'appname' => $appname, 'filepath' => $filepath, 'deployed' => 'true', 'url_works' => $check_url?'true':'false'});

        unless($check_url){
            print("Deployed, but URL doesn't reply!");
        }
        else{    
            print("$appname successfully deployed and checked!")       
        }

    }
    else{
        #TODO: possible to add a check by filepath to get appname and update about deployed: false
        print("Deploy failed: please check ansible log");
    }

}

sub undeploy{
    my ($pass,$args) = @_;
    my $settings = GfDeploy::Conf->load('path_to_glassfish');

    my $path_to_glassfish = $settings->{'path_to_glassfish'};
    my $appname = $args->{'appname'};
    my $res = `ansible test -m glassdeploy -a "action=undeploy path_to_glassfish=$path_to_glassfish appname=$appname"`;
    my $data = __parse_ansible_output($res);
    if ($data->{'result'}->{'status'}){
        __update_app({'appname' => $appname, 'filepath' => undef, 'deployed' => 'false', 'url_works' => 'false'});
        print("$appname successfully undeployed");
    }
    else{
        print("Undeploy failed: please check ansible log");
    }    
}

sub check_server_list{
    my $settings = GfDeploy::Conf->load('path_to_glassfish');
    my $path_to_glassfish = $settings->{'path_to_glassfish'};
    my $res = `ansible test -m glassdeploy -a "action=list path_to_glassfish=$path_to_glassfish"`;
    my $data = __parse_ansible_output($res);
    print("Apps in production:\n");
    foreach my $val (@{$data->{'result'}->{'apps'}}){
        print($val."\n")
    }
}

sub sync_deployed{
    
}

sub list_apps{

}

1;