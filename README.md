## Ansible Playbook Repository

This repository contains Ansible playbooks and roles to bootstrap and configure servers for various workloads. It is designed for flexible environments and supports both RHEL and Ubuntu-based systems.

### Overview

- **Purpose**: Prepare base server configurations to support application overlays (e.g., storage testing, databases, Kubernetes).
- **Use Cases**:
  - Bootstrapping nodes for internal testing.
  - Preparing infrastructure for VAST NFS deployments.
  - Setting up database testing environments on Azure.
- **Status**:
  - VAST Data NFS driver - current.
  - RHEL-specific code archived (archive/).
  - Volt_db Azure setup (archive/).

### Repository Structure

```text
.
├── archive/             # Legacy RHEL-specific code and scripts
├── files/               # Static files used by roles/playbooks (e.g., elbencho binaries)
├── filter_plugins/      # Custom Jinja2 filters for Ansible
├── group_vars/          # Global variables (including private overrides)
├── host_vars/           # Host-specific variables
├── library/             # Custom Ansible modules
├── playbooks/           # Collection of playbooks (multi-OS, VAST, etc.)
├── roles/               # Reusable roles (bootstrap, database, kubernetes, vast_nfs, etc.)
├── scratch/             # Experimental playbooks and code snippets
├── ansible.cfg          # Default Ansible configuration
├── inventory            # Current inventory of hosts
├── site.yml             # Main entry-point playbook
└── vast_site.yml        # VAST-specific orchestration playbook

```

---

### Key Roles

- bootstrap
  Sets up basic server parameters (packages, users, networking) for new nodes.
- common
  Shared configuration applied across all hosts (security, sysctl, etc.).
- kubernetes
  Installs and configures components for Kubernetes clusters.
- vast_nfs
  Builds and configures the VAST NFS driver on multi-OS environments.

---

### Development Notes

- *Scratch Directory*:
  Contains snippets, prototypes, and experimental playbooks. Not production-ready.
- *Archive Directory*:
  Legacy RHEL code (being phased out in favor of Ubuntu roles).


