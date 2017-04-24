# perl-ansible-vagrant-glassfish-uphh
Utility in Perl to play with deploys on Java applications to GlassFish in Vagrant(Ubuntu) via Ansible. Small Zoo.

Hello,

There was a small task to create a Perl utility to drive apps in GlassFish.

As I never used GlassFish, I was needed to get it working. To run it I used Vagrant with Ubuntu 16.04. To configure it I used Ansible. This pushed to make a small patch for existing role in ansible-galaxy (https://github.com/dpalomar/ansible-role-glassfish/pull/1). 

So, we are getting everything up using Ansible.
Then all actions are being applied to GlassFish/Payara on that virtual machine.

To start, you should have virtualenv installed in your system. (http://pythoncentral.io/how-to-install-virtualenv-python/)
Also, I was not adding automated cooking of Vagrant locally, so please install it too.

All tests were made on Mac OSX Sierra. Should be the same on any Linux too. 
I was trying to do fewer changes to host OS, so everything goes into the same directory including all Perl packages and ansible roles.

To start, please go to some directory, clone project from ..... and then do this:

*virtualenv venv*

and

*source ./venv/bin/activate*

After this, please do(Ansible will be installed in your virtualenv in local dir):

*pip install ansible*

After this, please do next command. I am asking for SUDO pass here to install App::Virtualenv Perl module into the Host system to allow storing of all next modules installs locally. This is equal to Python's virtualenv:

*ansible-playbook configure.yml --ask-become-pass*

It will take some time, create all needed dirs locally + download & run VM on Vagrant. Also, it will forward 2222(SSH), 8080 and 4848(GlassFish) ports to the Host system, so please keep this ports free.

Next, installing Java & Glassfish into the guest OS:

*ansible-playbook tasks/install_glassfish.yml*

When it finishes, you're good, and you can check http://127.0.0.1:8080/

Next action. You have everything ready to go. For Deployment/Undeployment to Glassfish I wrote Ansible module (available in ./library dir). It also has documentation about usage inside.

I was not automating this, can be done easily if needed, but please do first init of the app by hands, so:

*source ./perl-venv/bin/activate*

*perl gf_tool.pl --action init --config test.ini*

If I missed some module, like DBIx::Class::TimeStamp, don't hesitate to run:

*cpan DBIx::Class::TimeStamp*

It will be installed locally(my OS doesn't have many Perl modules, so installing this one took time :)).

and re-run initialization if there is a problem with module;)
Should be something like this:

`(perl-venv) (venv) Nikolayevs-MacBook-Pro:ansible nick$ perl gf_tool.pl --action init --config test.ini
Creating DB file
Saving Default Settings
Initialization Finished`


If everything is fine, you can do:

`(perl-venv) (venv) Nikolayevs-MacBook-Pro:ansible nick$ perl gf_tool.pl --action deploy --filepath ./hello.war
hello successfully deployed and checked!`

and then this web-service will be available at http://127.0.0.1:8080/hello/


gf_tool.pl uses modules in ./lib. I used SQLite as storage and DBIx to simplify the work with data (two tables)


Perl tool drives Ansible modules and stores data in SQLite DB. Also, there is a list of functions to modify settings, dump config, play with apps and even check for the list of live apps from server. However, it may be extended to synchronization DB state and GlassFish status, etc.

Glassfish also has an API for deploy/undeploy. I don't know if you want to deploy/undeploy via API, so it can be easily changed in ansible (rewriting the module).

Thanks!


