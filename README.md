## Ansible Playbook Repository

Playbooks and roles to **polish** VAST lab / cloud test clients after
Terraform + cloud-init birth the VM. Supports Debian/Ubuntu and RHEL-family.

### Ownership boundary

| Layer | Owns | Does **not** |
|-------|------|----------------|
| **Terraform + cloud-init** | VM, packages, fio/elbencho **binaries**, initial `~/tools` clone | Run I/O |
| **ansible** (this repo) | Lab users, `/mount/vast` dirs, VAST NFS driver, elbencho **campaigns** | Replace cloud-init |
| **sys-perf-tools** | fio jobfiles (`fio-file/`) for quick smoke / hammer | Fleet config |
| **system-tools** | Shell env / host helpers | Bench orchestration |

```text
cloud-init  →  swiss-army client (tools ready)
ansible     →  attach blades for this lab/cluster
fio         →  quick smash (manual)
elbencho    →  multi-client project runs (playbooks/elbencho.yml)
```

### Use cases

- Day-2 client polish for labs/training (`vast_client`)
- VAST NFS driver install (`vast_nfs`)
- Elbencho multi-client campaigns (`playbooks/elbencho.yml`)
- App overlays (Trino, ClickHouse, …) under `playbooks/`

Bootstrapping nodes for internal testing lives in **Terraform cloud-init**, not here.

### Repository structure

```text
├── files/elbencho_scripts/   # Canonical elbencho helpers (+ optional static binary)
├── group_vars/               # Global vars (tools_repos, /mount/vast dirs)
├── playbooks/                # Single-purpose playbooks (elbencho, …)
├── roles/
│   ├── vast_client/          # Users, mounts, S3 cfg, ~/tools clones
│   ├── vast_nfs/             # VAST NFS kernel driver
│   └── elbencho/             # Docs + script mirror (orchestration → playbooks/)
├── inventory.ini
├── site.yml                  # Main entry (vast_client + vast_nfs, tagged never)
└── one_liners.txt            # HISTORICAL notes — not current procedure
```

### Mount convention

All VAST client mounts: **`/mount/vast`** (never `/mnt/vast`).

| Path | Role |
|------|------|
| `/mount/vast` | NFS/SMB mount root |
| `/mount/vast/fio` | Default FIO work directory |
| `/mount/vast/elbencho-files` | Elbencho campaign files |
| `/mount/vast/data`, `gns-*` | Shared lab dirs |

### Key roles / playbooks

| Name | Purpose |
|------|---------|
| `vast_client` | Lab users, mount dirs, refresh `~/tools/{sys-perf-tools,system-tools}` |
| `vast_nfs` | Build/install VAST NFS driver |
| `playbooks/elbencho.yml` | Mount, elbencho service, copy campaign scripts |

```bash
# Client polish
ansible-playbook -i inventory.ini site.yml --tags client

# Driver only
ansible-playbook -i inventory.ini site.yml --tags install_driver

# Elbencho campaign prep
ansible-playbook -i inventory.ini playbooks/elbencho.yml --tags mount,elbencho_serv,copy_scripts
```

On the host (manual fio):

```bash
cd ~/tools/sys-perf-tools/fio-file
./quick-smoke.sh /mount/vast/fio
```

### Author

Karl Vietmeier — Apache 2.0
