## Ansible Playbook Repository

Robust **demo- and benchmark-ready examples** for standing up VAST test
clients, then building foundational benchmark platforms and larger testing
solutions on top. Day-2 polish after Terraform + cloud-init births the VM
(Debian/Ubuntu and RHEL-family).

### Positioning

| Piece | Role |
|-------|------|
| **Cloud client (cloud-init)** | Tools-ready host: fio + elbencho binaries, `~/tools` clones — no auto I/O |
| **This repo (ansible)** | Wire the host for a lab/cluster: users, `/mount/vast`, NFS driver, example bench orchestration |
| **fio (`sys-perf-tools/fio-file`)** | Short demo / smoke / baseline jobfiles — first proof the platform works |
| **elbencho (playbook + scripts)** | Multi-client benchmark **examples** you copy and extend into a full test solution |

```text
cloud-init  →  tools-ready client
ansible     →  lab/cluster wiring + benchmark platform examples
fio         →  short demos & baselines (manual)
elbencho    →  multi-client benchmark examples (manual)
```

### Ownership boundary

| Layer | Owns | Does **not** |
|-------|------|----------------|
| **Terraform + cloud-init** | VM, packages, fio/elbencho **binaries**, initial `~/tools` clone | Run I/O |
| **ansible** (this repo) | Lab users, `/mount/vast` dirs, VAST NFS driver, elbencho **examples** | Replace cloud-init |
| **sys-perf-tools** | fio jobfiles (`fio-file/`) for smoke / baseline demos | Fleet config |
| **system-tools** | Shell env / host helpers | Bench orchestration |

### Use cases

- Lab / training client polish (`vast_client`)
- VAST NFS driver install (`vast_nfs`)
- Multi-client benchmark platform examples (`playbooks/elbencho.yml`)
- App overlays (Trino, ClickHouse, …) under `playbooks/`

Bootstrapping nodes for internal testing lives in **Terraform cloud-init**, not here.

### Repository structure

```text
├── files/elbencho_scripts/   # Canonical elbencho example scripts (+ optional binary)
├── group_vars/               # Global vars (tools_repos, /mount/vast dirs)
├── playbooks/                # Single-purpose playbooks (elbencho, …)
├── roles/
│   ├── vast_client/          # Users, mounts, S3 cfg, ~/tools clones
│   ├── vast_nfs/             # VAST NFS kernel driver
│   └── elbencho/             # Docs + script mirror (orchestration → playbooks/)
├── inventory.ini
├── site.yml                  # Main entry (vast_client + vast_nfs, tagged never)
└── one_liners.txt            # Quick reference (current + historical)
```

### Mount convention

All VAST client mounts: **`/mount/vast`** (never `/mnt/vast`).

| Path | Role |
|------|------|
| `/mount/vast` | NFS/SMB mount root |
| `/mount/vast/fio` | Default FIO work directory |
| `/mount/vast/elbencho-files` | Elbencho example workload files |
| `/mount/vast/data`, `gns-*` | Shared lab dirs |

### Key roles / playbooks

| Name | Purpose |
|------|---------|
| `vast_client` | Lab users, mount dirs, refresh `~/tools/{sys-perf-tools,system-tools}` |
| `vast_nfs` | Build/install VAST NFS driver |
| `playbooks/elbencho.yml` | Mount, elbencho service, copy example scripts |

```bash
# Client polish
ansible-playbook -i inventory.ini site.yml --tags client

# Driver only
ansible-playbook -i inventory.ini site.yml --tags install_driver

# Elbencho benchmark platform example (prep)
ansible-playbook -i inventory.ini playbooks/elbencho.yml --tags mount,elbencho_serv,copy_scripts
```

On the host (manual fio demo):

```bash
cd ~/tools/sys-perf-tools/fio-file
./quick-smoke.sh /mount/vast/fio
```

### Author

Karl Vietmeier — Apache 2.0
