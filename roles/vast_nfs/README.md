# VAST NFS Driver Installation & Mount Preparation Role

Builds and installs the VAST NFS kernel driver on lab/cloud clients, prepares
the **`/mount/vast`** mount point, and writes a reusable mount command.

**Does not** run elbencho or fio. After the driver is up:

- Short demos / baselines → `~/tools/sys-perf-tools/fio-file/` (dir `/mount/vast/fio`)
- Multi-client benchmark examples → `playbooks/elbencho.yml` + `files/elbencho_scripts/`

## Scope

- Debian/Ubuntu and RHEL-family
- Prereqs, download, build, install, verify, mountprep

## Directory structure

```text
roles/vast_nfs/
├── tasks/     # main, prereqs, download, build, install, verify, mountprep
├── vars/      # mount_point=/mount/vast, DNS, view, nconnect, …
└── README.md
```

## Default variables (`vars/main.yml`)

| Variable | Default | Description |
|----------|---------|-------------|
| `dns_alias` | `sharespool` | VIP pool DNS alias |
| `dns_domain` | `busab` | Domain suffix |
| `view_path` | `nfs_01` | NFS export path |
| `mount_point` | `/mount/vast` | Local mount root (standard) |
| `port_range` | `33.20.1.11-33.20.1.13` | remoteports |
| `conns` | `11` | nconnect |
| `download_script_url` | `https://vastnfs.vastdata.com/download.sh` | Driver fetch |
| `output_log` | `/tmp/vast_nfs_build.log` | Build log |

## Tags

- `prereqs` `download` `build` `install` `verify` `mountprep` `mount_now`

```bash
ansible-playbook -i inventory.ini site.yml --tags install_driver
ansible-playbook -i inventory.ini site.yml --tags mountprep
ansible-playbook -i inventory.ini site.yml --tags mount_now \
  -e "mount_point=/mount/vast view_path=nfs_share_test dns_alias=myshare dns_domain=corp"
```

## Integration

Via `site.yml` (`tags: install_driver`) or:

```yaml
- hosts: clients
  become: yes
  roles:
    - vast_nfs
```

## After the driver

1. Mount under `/mount/vast` (mountprep / mount_now or manual).
2. **fio (demo / baseline):** `cd ~/tools/sys-perf-tools/fio-file && ./quick-smoke.sh`
3. **elbencho (multi-client example):**  
   `ansible-playbook -i inventory.ini playbooks/elbencho.yml --tags mount,elbencho_serv,copy_scripts`  
   then run scripts from `files/elbencho_scripts/` on the primary client.

## Notes

- Wait for cloud-init (~7–10 min) on fresh VMs before this role.
- Mount command saved for later manual use (see role tasks).

## Author / License

Karl Vietmeier — Apache 2.0
