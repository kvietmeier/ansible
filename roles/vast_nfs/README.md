# VAST NFS Driver Installation & Mount Preparation Role

Builds and installs the VAST NFS kernel driver on lab/cloud clients.
Optional tags prepare **`/mount/vast`** and write a reusable mount command.

**Does not** run elbencho or fio. After the driver is up:

- Short demos / baselines → `~/tools/sys-perf-tools/fio-jobs/` (dir `/mount/vast/fio`)
- Multi-client benchmark examples → `playbooks/elbencho.yml` + `files/elbencho_scripts/`

## Scope

- Debian/Ubuntu and RHEL-family
- Prereqs, download, build, install, verify
- Opt-in: `mountprep` / `mount_now`

## Directory structure

```text
roles/vast_nfs/
├── defaults/  # mount_point=/mount/vast, DNS, view, nconnect, …
├── tasks/     # main, prereqs, download, build, install, verify, mountprep
├── vars/      # empty stub (defaults live above)
└── README.md
```

## Default variables (`defaults/main.yml`)

| Variable | Default | Description |
|----------|---------|-------------|
| `dns_alias` | `sharespool` | VIP pool DNS alias (placeholder) |
| `dns_domain` | `busab` | Domain suffix (placeholder) |
| `view_path` | `nfs_01` | NFS export path |
| `mount_point` | `/mount/vast` | Local mount root (standard) |
| `port_range` | `33.20.1.11-33.20.1.13` | remoteports (placeholder VIP range) |
| `conns` | `11` | nconnect |
| `download_script_url` | `https://vastnfs.vastdata.com/download.sh` | Driver fetch |
| `output_log` | `/tmp/vast_nfs_build.log` | Build log |

Override with `-e`, inventory, or `group_vars`. Uses `base_user` from `group_vars` when writing `nfs_mount_cmd.txt`.

## Tags

| Tag | What runs |
|-----|-----------|
| `install_driver` | Full driver path via `site.yml` (prereqs → verify). **Does not** mount. |
| `mountprep` | Create mount point + write `~/nfs_mount_cmd.txt` |
| `mount_now` | Same as mountprep, then mount immediately |
| `prereqs` `download` `build` `install` `verify` | Stage re-runs (need prior outputs) |

```bash
# Driver only (recommended)
ansible-playbook -i inventory.ini site.yml --tags install_driver

# Mount helpers (opt-in; not part of install_driver)
ansible-playbook -i inventory.ini site.yml --tags mountprep
ansible-playbook -i inventory.ini site.yml --tags mount_now \
  -e "mount_point=/mount/vast view_path=nfs_share_test dns_alias=myshare dns_domain=corp"
```

For multi-client bench mounts, prefer `playbooks/elbencho.yml --tags mount`.

## Integration

Via `site.yml` (`tags: install_driver`) or:

```yaml
- hosts: clients
  become: yes
  roles:
    - vast_nfs
```

## After the driver

1. Mount under `/mount/vast` (`mountprep` / `mount_now`, elbencho playbook, or manual).
2. **fio (demo / baseline):** `cd ~/tools/sys-perf-tools/fio-jobs && ./quick-smoke.sh /mount/vast/fio`
3. **elbencho (multi-client example):**  
   `ansible-playbook -i inventory.ini playbooks/elbencho.yml --tags mount,elbencho_serv,copy_scripts`  
   then run scripts from `files/elbencho_scripts/` on the primary client.

## Notes

- Wait for cloud-init (~7–10 min) on fresh VMs before this role.
- Ubuntu: unattended-upgrades are disabled so a later kernel update does not strand the driver.
- Mount command saved under `/home/<base_user>/nfs_mount_cmd.txt`.

## Author / License

Karl Vietmeier — Apache 2.0
