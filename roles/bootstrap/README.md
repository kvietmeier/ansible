# bootstrap

Day-0 bootstrap for lab / CI Linux VMs. Ansible equivalent of Terraform
[`lab_bootstrap.sh`](https://github.com/kvietmeier/Terraform/tree/main/scripts/cloud-init)
+ cloud-init packages so OOB images reach the same tools-ready state.

**Does not** install the VAST NFS kernel driver (stub only). Use `vast_nfs`
(`site.yml --tags install_driver`) for download/build/install.

Overlap with cloud-init and with `vast_nfs` prereqs is intentional and
idempotent — a later full playbook run rolls over already-satisfied packages.

## Boundary

| Layer | Owns |
|-------|------|
| Terraform + cloud-init | VM birth when you control user-data |
| **bootstrap** (this role) | Same day-0 path via Ansible (OOB / CI VMs) |
| vast_client | Lab users, `/mount/vast` dirs, S3 cfg, refresh tools |
| vast_nfs | VAST NFS kernel driver install |

## Platforms

- Ubuntu (Debian family)
- Rocky / CentOS / RHEL / AlmaLinux

## What it does

1. Disable auto-updates and host firewalls (bench stability)
2. Ensure lab user (`strata`), passwordless sudo, SSH key copy, bash aliases
3. Install portable + distro packages, NFS/S3 clients, chrony
4. Optional: build deps + compile fio / iperf / dool / sockperf / elbencho
5. Optional: clone `~/tools/{sys-perf-tools,system-tools}`
6. Prep for VAST NFS driver (kernel modules, RDMA, headers, toolchain)
7. Stub for driver install (points at `vast_nfs`)

## Usage

```bash
# Full bootstrap (default toggles)
ansible-playbook -i inventory.ini site.yml --tags bootstrap

# Skip bench compiles
ansible-playbook -i inventory.ini site.yml --tags bootstrap \
  -e bootstrap_install_bench_tools=false

# Later: driver install rolls over shared prereqs
ansible-playbook -i inventory.ini site.yml --tags install_driver
```

## Variables

See `defaults/main.yml`. Key toggles:

| Variable | Default | Meaning |
|----------|---------|---------|
| `bootstrap_lab_user` | `strata` | Lab SSH user |
| `bootstrap_install_bench_tools` | `true` | Compile fio/iperf/elbencho/… |
| `bootstrap_clone_tools_repos` | `true` | Clone tool repos under `~/tools` |
| `bootstrap_prep_nfs_driver` | `true` | Kernel/RDMA/headers prep |

Uses `base_user` from `group_vars` when `bootstrap_lab_user` is not overridden
in a way that conflicts — effective user is set in `tasks/facts.yml`.

## Author / License

Karl Vietmeier — Apache 2.0
