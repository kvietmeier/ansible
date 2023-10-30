Ansible Playbook Repo

A set of roles/tasks to bootstrap some basic server parameters to prep for overlaying apps..

The scratch directory has some snippets of code and a playbook to prep a node for runninng CBT.

RHEL related tasks/vars are in the archive folder, updating to work with Ubuntu

Updated to add a role to setup a VoltDB testing platform on Azure


```
.
├── README.md
├── ansible.cfg
├── archive
│   ├── ansible.cfg.allsettings.cfg
│   ├── bootstrap
│   ├── bootstrap.bak.yml
│   ├── bootstrap.rhel
│   ├── inventory.old
│   └── roles
├── filter_plugins
│   └── default.yml
├── foobar.txt
│   ├── vdb-02
│   ├── vdb-03
│   ├── vdb-04
│   └── vdb-05
├── group_vars
│   ├── all.yml
│   └── private_vars.yml
├── host_vars
│   └── default.yml
├── inventory
├── library
│   └── default.yml
├── ports_volt.txt
├── roles
│   ├── bootstrap
│   ├── ceph
│   ├── common
│   ├── kubernetes
│   ├── rhelosp
│   └── voltdb
├── scratch
│   ├── bootstrap.yml
│   ├── cbt.yml
│   ├── hosts
│   └── snippets.yml
├── site.yml
├── testing.sh
├── volt_init.sh
├── volt_kill.sh
├── volt_playbook.sh
├── volt_runall.sh
├── volt_setup_mgmt.sh
└── volt_start_all.sh
```
