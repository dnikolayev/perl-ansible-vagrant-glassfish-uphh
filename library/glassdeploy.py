#!/usr/bin/python
from __future__ import print_function
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
---
module: glassfishdeploy
version_added: 0.1
short_description: Custom module to deploy/undeploy/list java(war) applications to Glassfish(Payara) server.
description:
  - Manage (add, remove, list) individual war applications in a Glassfish instance via command line.
options:
  path_to_glassfish:
    description:
      - Root for the application on Glassfish server. 
      - Example: I(/opt/glassfish/payara41/)
    required: true
    default: null
  appname:
    description:
      - Name of the application that is displayed in the "Applications" tab of the administrative console. Required for Undeploy.
    required: false
    default: null
  filepath:
    description:
      - File path of the war-application to deploy
      - Example: I(/vagrant/apps/hello.war)
    required: false
    default: null
  action:
    description:
      - Describes whether to deploy, undeploy or list
    choices: ["deploy", "undeploy", "list"]
    default: list
author:
  - "Dmytro Nikolayev"
'''

EXAMPLES = '''
# Deploy a web-application named hello.war (hello) 
ansible test -m glassdeploy -a "action=deploy path_to_glassfish=/opt/glassfish/payara41/ filepath=/vagrant/apps/hello.war"
# Undeploy a web-application named hello
ansible test -m glassdeploy -a "action=undeploy path_to_glassfish=/opt/glassfish/payara41/ appname=hello"
# List deployed apps
ansible test -m glassdeploy -a "action=list path_to_glassfish=/opt/glassfish/payara41/"
'''

RETURN = '''
changed:
  description: Boolean representing a change of state in Glassfish due to the module
  type: boolean
result:
  description: object with message and status of action
  type: JSON
  sample: "result": {
        "apps": [
            "hello"
        ],
        "msg": null,
        "status": true
    }
'''

from ansible.module_utils.urls import *
import os
from subprocess import check_output
import sys
import re

def create_pass_file():
    try:
        f = open("/tmp/p.file", "w")
        print("AS_ADMIN_PASSWORD=admin", file=f)
        close(f)
        return {"msg": "pass file created", "status": True}
    except:
        return {"msg": sys.exc_info()[0], "status": False}

def remove_pass_file():
    try:
        os.unlink("/tmp/p.file")
        return {"msg": "pass file deleted", "status": True}
    except:
        return {"msg": sys.exc_info()[0], "status": False}

def deploy(path_to_glassfish="/opt/glassfish/payara41/", filepath="/vagrant/apps/hello.war"):
    try:
        t = check_output([os.path.join(path_to_glassfish,"bin/asadmin") +" --user admin --passwordfile /tmp/p.file deploy " + filepath], shell=True)
        if "Command deploy failed." in t:
            return {"msg": t, "status": False}
        else:
            appname = re.findall("^Application deployed with name (.*?)\.$", t.split("\n")[0])[0]
            return {"msg": t, "appname": appname, "status": True}
    except:
        return {"msg": sys.exc_info()[0], "status": False}

def undeploy(path_to_glassfish="/opt/glassfish/payara41/", appname="hello"):
    try:
        t = check_output([os.path.join(path_to_glassfish,"bin/asadmin") +" --user admin --passwordfile /tmp/p.file undeploy " + appname], shell=True)
        if "Command undeploy failed." in t:
            return {"msg": t, "status": False}
        else:
            return {"msg": t, "status": True}
    except:
        return {"msg": sys.exc_info()[0], "status": False}

def list_apps(path_to_glassfish="/opt/glassfish/payara41/"):
    try:
        t = check_output([os.path.join(path_to_glassfish,"bin/asadmin") +" --user admin --passwordfile /tmp/p.file list-applications"], shell=True)
        as_arr = t.split("\n")[:-2]
        if len(as_arr) and as_arr[0] == 'Nothing to list.':
            as_arr = []
        as_arr = [x.split()[0] for x in as_arr]
        return {"msg": sys.exc_info()[0], "apps": as_arr, "status": True}
    except:
        return {"msg": sys.exc_info()[0], "status": False}

def main():
    module = AnsibleModule(
        argument_spec =     dict(
        appname=            dict(required=False),
        filepath=           dict(required=False),
        action =            dict(required=False, default='list', choices=['list', 'deploy','undeploy']),
        path_to_glassfish=  dict(required=True),
        )
    )

    action            = module.params['action']
    appname           = module.params['appname'] 
    filepath          = module.params['filepath']
    path_to_glassfish = module.params['path_to_glassfish']

    create_pass_file()
    t = {}
    if action == 'list':
        t = list_apps(path_to_glassfish=path_to_glassfish)
    elif action == 'deploy':
        t = deploy(path_to_glassfish=path_to_glassfish, filepath=filepath)    
    elif action == 'undeploy':
        t = undeploy(path_to_glassfish=path_to_glassfish, appname=appname)
    else:
        remove_pass_file()
        module.exit_json(result={"msg": "No action passed, How did it get here??"}, changed=0)

    remove_pass_file()
    module.exit_json(result=t, changed=t['status'])

from ansible.module_utils.basic import *

if __name__ == '__main__':
    main()