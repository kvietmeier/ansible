# 
Ansible Playbook Repo

A set of roles/tasks to bootstrap some basic server parameters to prep for overlaying apps..

The scratch directory has some snippets of code and a playbook to prep a node for runninng CBT.

```
.
├── README.md
├── ansible.cfg
├── ansible.cfg.allsettings.cfg
├── bootstrap
│   ├── ansible.cfg
│   ├── bonding
│   ├── bootstrap.yml
│   ├── files
│   ├── inventory
│   ├── sysctl.yml
│   └── upgrade_nic_drivers.yml
├── filter_plugins
│   └── default.yml
├── group_vars
│   └── all.yml
├── host_vars
│   └── default.yml
├── inventory
├── library
│   └── default.yml
├── roles
│   ├── ceph
│   ├── common
│   └── rhelosp
├── scratch
│   ├── bootstrap.yml
│   ├── cbt.yml
│   ├── hosts
│   └── snippets.yml
└── site.yml
```
