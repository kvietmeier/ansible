# vast_client

Day-2 polish for VAST lab / cloud test clients. Makes an already-bootstrapped
VM into a usable lab client: users, mount dirs, shell/S3 config, tool repos.

**Does not** build fio/elbencho (cloud-init / `lab_bootstrap.sh` does that).
**Does not** generate I/O.

## Boundary

| Layer | Owns |
|-------|------|
| Terraform + cloud-init | VM birth, packages, fio/elbencho binaries, initial `~/tools` clone |
| **vast_client** (this role) | Lab users, `/mount/vast/*` dirs, bashrc, S3 cfg, refresh tool clones |
| vast_nfs | VAST NFS kernel driver |
| elbencho playbook | Multi-client campaign orchestration |
| sys-perf-tools `fio-file/` | Quick smash / smoke / baseline jobfiles |

## Mount convention

All VAST mounts use **`/mount/vast`** (never `/mnt/vast`).

| Path | Role |
|------|------|
| `/mount/vast` | NFS/SMB mount root |
| `/mount/vast/fio` | Default FIO work dir (`sys-perf-tools/fio-file`) |
| `/mount/vast/data`, `gns-*` | Shared lab dirs |

## What it does

1. Install `nfs-common` / `rpcbind`
2. Create numbered lab users (`labuser01`…) with passwordless sudo (optional)
3. Ensure `/mount/vast/...` directories exist
4. Distribute bashrc, dircolors, SSH keys, `.s3cfg`
5. Clone **`sys-perf-tools`** + **`system-tools`** → `/home/labuser/tools/`

## Usage

```bash
# From ansible repo root
ansible-playbook -i inventory.ini site.yml --tags client

# Tools clone only
ansible-playbook -i inventory.ini site.yml --tags git_tools
```

Quick FIO after mount (manual):

```bash
cd ~/tools/sys-perf-tools/fio-file
./quick-smoke.sh /mount/vast/fio
./runfio.sh -j ./vast-p01-p06-p09-baseline.ini -d /mount/vast/fio
```

## Variables

See `group_vars/all.yml` and `defaults/main.yml` (`base_user`, `tools_repos`,
`vast_shared_directories`, `create_individual_user_mounts`, …).

## Author

Karl Vietmeier — Apache 2.0
