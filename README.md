## Ansible Playbook Repository

This repository contains Ansible playbooks and roles to bootstrap and configure servers for various workloads. It is designed for flexible environments and supports both RHEL and Ubuntu-based systems.

### Overview

- **Purpose**: Prepare base server configurations to support application overlays (e.g., storage testing, databases, Kubernetes).
- **Use Cases**:
  - Bootstrapping nodes for internal testing (moved to cloud-init/Terraform).
  - Polishing up/final configuration for clients used in labs/training (vast_clients)
  - Preparing infrastructure for VAST NFS deployments (vast_nfs).
  - Setting up database testing environments on Azure (Archive).
- **Status**:
  - VAST Data NFS driver - current.
  - Client Setup - current
  - RHEL-specific code archived (archive/).
  - Volt_db Azure setup (archive/).

### Repository Structure

```text
├── archive/            # Legacy RHEL-specific code and scripts
├── files/              # Static files used by roles/playbooks (e.g., elbencho binaries)
├── filter_plugins/     # Custom Jinja2 filters for Ansible
├── group_vars/         # Global variables (including private overrides)
├── host_vars/          # Host-specific variables
├── library/            # Custom Ansible modules
├── library             # Custom Ansible modules
├── playbooks           # Collection of single use playbooks 
├── roles               # Reusable roles
├── README.md           # This file
├── inventory.ini       # Current inventory of hosts
├── one_liners.txt      # Misc notes amd examples for running Playbooks/Ad Hoc commands
├── ansible.cfg         # Ansible configuration
└── site.yml            # Main entry-point playbook
```

---

### TBD

---

### Key Roles

- vast_client
  Sets up clients for a lab environment - users, mount points, etc.
- vast_nfs
  Builds and configures the VAST NFS driver on multi-OS environments.

---

### Development Notes

- *Archive Directory*:
  Legacy code
