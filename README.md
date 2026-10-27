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
| **fio (`sys-perf-tools/fio-jobs`)** | Short demo / smoke / baseline jobfiles — first proof the platform works |
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
| **sys-perf-tools** | fio jobfiles (`fio-jobs/`) for smoke / baseline demos | Fleet config |
| **system-tools** | Shell env / host helpers | Bench orchestration |

### Maturity model

| Stage | Where | Intent |
|-------|-------|--------|
| **Concept / get-started** | `playbooks/` | Try an idea, teach a pattern, smoke a stack |
| **Mature** | `roles/` | Reusable, tagged, documented — promoted from a playbook |

Playbooks are the sandbox. When something is solid enough to reuse across labs,
it graduates into a role (and may keep a thin playbook as the entrypoint).

### Use cases

- Lab / training client polish (`vast_client`)
- VAST NFS driver install (`vast_nfs`)
- Multi-client benchmark platform examples (`playbooks/elbencho.yml`)
- Concept overlays under `playbooks/` (e.g. ClickHouse, Trino cluster)

Bootstrapping nodes for internal testing lives in **Terraform cloud-init**, not here.

### Provision clients first (Terraform)

Day-0 Linux fleets live in [kvietmeier/Terraform](https://github.com/kvietmeier/Terraform) — one stack per cloud (not a cross-cloud orchestrator):

| Cloud | Identical pool | Unique map |
|-------|----------------|------------|
| AWS | [`aws/ec2/multi_vm`](https://github.com/kvietmeier/Terraform/tree/main/aws/ec2/multi_vm) | [`multi_vm_map`](https://github.com/kvietmeier/Terraform/tree/main/aws/ec2/multi_vm_map) |
| GCP | [`gcp/VMs/multi_vm`](https://github.com/kvietmeier/Terraform/tree/main/gcp/VMs/multi_vm) | [`multi_vm_map`](https://github.com/kvietmeier/Terraform/tree/main/gcp/VMs/multi_vm_map) |
| Azure | [`azure/VMs/multi_vm`](https://github.com/kvietmeier/Terraform/tree/main/azure/VMs/multi_vm) | [`multi_vm_map`](https://github.com/kvietmeier/Terraform/tree/main/azure/VMs/multi_vm_map) |

Shared bootstrap: [`scripts/cloud-init`](https://github.com/kvietmeier/Terraform/tree/main/scripts/cloud-init) (packages + user **`strata`** — not the VAST NFS kernel driver).

**Handoff**

1. `terraform apply` in the chosen `multi_vm` (or `multi_vm_map`) stack
2. Copy `vm_private_ips` (AWS/GCP) or `vm_public_ips` (Azure) into `[clients]` in `inventory.ini`
3. Set `ansible_ssh_user=strata` (matches cloud-init)
4. POC / demo ready:

```bash
ansible-playbook -i inventory.ini site.yml --tags client,install_driver
# optional live mount:
ansible-playbook -i inventory.ini site.yml --tags mountprep
# or: --tags mount_now -e 'view_path=nfs_01 dns_alias=sharespool dns_domain=example'
```

Default hostnames from TF examples: `kv-copper`, `kv-lead`, `kv-zinc`, `kv-moly`, `kv-silver`, `kv-gold` (`vm_name_prefix = "kv-"` + `vm_names` list).

### Repository structure

```text
├── files/elbencho_scripts/   # Canonical elbencho example scripts (+ optional binary)
├── group_vars/               # Global vars (tools_repos, /mount/vast dirs)
├── playbooks/                # Concept / get-started work (graduate → roles)
├── roles/
│   ├── vast_client/          # Mature — users, mounts, S3 cfg, ~/tools clones
│   ├── vast_nfs/             # Mature — VAST NFS kernel driver (+ opt-in mountprep)
│   ├── elbencho/             # Docs + script mirror (orchestration → playbooks/)
│   ├── trino/ specsfs/ kubernetes/  # Untested stubs — do not treat as ready
├── inventory.ini
├── site.yml                  # Main entry (vast_client + vast_nfs, tagged never)
└── one_liners.txt            # Learn Ansible via ad-hoc + lab cheat sheet
```

### Learn by doing (`one_liners.txt`)

Ad-hoc commands are the fastest path into Ansible: same inventory, modules,
`become`, and limits as playbooks — without writing YAML first. Start in
section 1 of `one_liners.txt`, then use lab sections for VAST client / fio /
elbencho examples.

Deeper ad-hoc walkthrough: [Ansible AdHoc Commands gist](https://gist.github.com/kvietmeier/d497360a0e304286285220066ff0b53c)
([all gists](https://gist.github.com/kvietmeier)).

### Mount convention

All VAST client mounts: **`/mount/vast`** (never `/mnt/vast`).

| Path | Role |
|------|------|
| `/mount/vast` | NFS/SMB mount root |
| `/mount/vast/fio` | Default FIO work directory |
| `/mount/vast/elbencho-files` | Elbencho example workload files |
| `/mount/vast/data`, `gns-*` | Shared lab dirs |

### Key roles / playbooks

| Name | Status | Purpose |
|------|--------|---------|
| `vast_client` | Mature | Lab users, mount dirs, refresh `~/tools/{sys-perf-tools,system-tools}` |
| `vast_nfs` | Mature | Build/install VAST NFS driver |
| `playbooks/elbencho.yml` | Concept → platform example | Mount, elbencho service, copy example scripts |
| `playbooks/clickhouse.yml`, `trino_cluster.yml` | Concept | Get-started / testing sketches |
| `roles/trino`, `specsfs`, `kubernetes` | Stub | Untested vibe-coded sketches — not supported yet |

```bash
# POC / demo (client polish + VAST NFS driver)
ansible-playbook -i inventory.ini site.yml --tags client,install_driver

# Client polish only
ansible-playbook -i inventory.ini site.yml --tags client

# Driver only
ansible-playbook -i inventory.ini site.yml --tags install_driver

# Elbencho benchmark platform example (prep)
ansible-playbook -i inventory.ini playbooks/elbencho.yml --tags mount,elbencho_serv,copy_scripts
```

On the host (manual fio demo):

```bash
cd ~/tools/sys-perf-tools/fio-jobs
./quick-smoke.sh /mount/vast/fio
```

### Author

Karl Vietmeier — Apache 2.0
