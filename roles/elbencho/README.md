# elbencho

Multi-client **benchmark platform examples** for VAST (NFS/S3). Use these as
a foundation: copy, parameterize, and grow into a fuller testing solution.

Binary install is cloud-init / `lab_bootstrap.sh`. This repo wires mounts,
starts `elbencho --service`, and ships ready-to-run example scripts.

For short demos, smoke, and baselines, prefer **fio**:
`~/tools/sys-perf-tools/fio-file/` (default dir `/mount/vast/fio`).

## Boundary

| Layer | Owns |
|-------|------|
| cloud-init | Compile/install `elbencho` binary |
| **playbooks/elbencho.yml** | Mount, start/stop `--service`, copy example scripts |
| **files/elbencho_scripts/** | Canonical prep / block-size examples (+ static binary) |
| roles/elbencho/files/ | Mirror of the scripts (same content) |
| sys-perf-tools | fio jobfiles for smoke / baseline demos |

## Mount convention

Use **`/mount/vast`** (standard). Workload files go under
`/mount/vast/elbencho-files`. Override `mount_point` if needed.

## Usage

```bash
ansible-playbook -i inventory.ini playbooks/elbencho.yml --tags mkdirs
ansible-playbook -i inventory.ini playbooks/elbencho.yml --tags mount
ansible-playbook -i inventory.ini playbooks/elbencho.yml --tags elbencho_serv
ansible-playbook -i inventory.ini playbooks/elbencho.yml --tags copy_scripts
# run example scripts manually on primary client, then:
ansible-playbook -i inventory.ini playbooks/elbencho.yml --tags kill_all
```

## Author

Karl Vietmeier — Apache 2.0
