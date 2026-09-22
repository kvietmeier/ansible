# elbencho

Multi-client **project** benchmarking against VAST (NFS/S3). Binary install is
cloud-init / `lab_bootstrap.sh`; this repo orchestrates campaigns and ships
helper scripts.

For quick one-off smash tests, prefer **fio**:
`~/tools/sys-perf-tools/fio-file/` (default dir `/mount/vast/fio`).

## Boundary

| Layer | Owns |
|-------|------|
| cloud-init | Compile/install `elbencho` binary |
| **playbooks/elbencho.yml** | Mount, start/stop `--service`, copy scripts |
| **files/elbencho_scripts/** | Canonical prep / block-size scripts (+ static binary) |
| roles/elbencho/files/ | Mirror of the scripts (same content) |
| sys-perf-tools | fio jobfiles for smoke / short hammer |

## Mount convention

Use **`/mount/vast`** (standard). Workload files go under
`/mount/vast/elbencho-files`. Override `mount_point` if needed.

## Usage

```bash
ansible-playbook -i inventory.ini playbooks/elbencho.yml --tags mkdirs
ansible-playbook -i inventory.ini playbooks/elbencho.yml --tags mount
ansible-playbook -i inventory.ini playbooks/elbencho.yml --tags elbencho_serv
ansible-playbook -i inventory.ini playbooks/elbencho.yml --tags copy_scripts
# run scripts manually on primary client, then:
ansible-playbook -i inventory.ini playbooks/elbencho.yml --tags kill_all
```

## Author

Karl Vietmeier — Apache 2.0
