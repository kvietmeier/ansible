Ansible Playbook Repo

A set of roles/tasks to bootstrap some basic server parameters to prep for overlaying apps..

The scratch directory has some snippets of code and a playbook to prep a node for runninng CBT.

RHEL related tasks/vars are in the archive folder, updating to work with Ubuntu

Updated to add a role to setup a Database testing platform on Azure


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
├── group_vars
│   ├── all.yml
│   └── private_vars.yml
├── host_vars
│   └── default.yml
├── inventory
├── library
│   └── default.yml
├── db_ports.txt
├── roles
│   ├── bootstrap
│   ├── ceph
│   ├── common
│   ├── kubernetes
│   ├── rhelosp
│   └── database
├── scratch
│   ├── bootstrap.yml
│   ├── cbt.yml
│   ├── hosts
│   └── snippets.yml
├── site.yml
├── testing.sh
├── db_init.sh
├── db_kill.sh
├── db_playbook.sh
├── db_runall.sh
├── db_setup_mgmt.sh
└── db_start_all.sh
```
