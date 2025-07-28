# VAST NFS Driver Installation & Mount Preparation Role

## Overview

This role automates:
1. **Prerequisite setup** (cloud-init check, GCC installation, kernel validation).
2. **Download and build** of the latest VAST NFS driver (supports Ubuntu & RedHat families).
3. **Installation** of the driver, regeneration of initramfs, and reboot.
4. **Verification** of the driver (rpm or modinfo checks).
5. **Mount point preparation** and generation of a reusable NFS mount command.

The role is designed for environments where test clients are frequently rebuilt and simplifies driver reinstallation and mounting.

---

## Directory Structure

```text
roles/
└── vast_nfs/
    ├── tasks/
    │   ├── main.yml         # Master flow (includes all sub-task files)
    │   ├── prereqs.yml      # Wait for cloud-init, install GCC, kernel checks
    │   ├── download.yml     # Download and extract driver
    │   ├── build.yml        # Build driver binaries
    │   ├── install.yml      # Install and reboot
    │   ├── verify.yml       # Verify driver installed correctly
    │   └── mountprep.yml    # Prepare mount point and save mount command
    ├── vars/
    │   └── main.yml         # Default variables (DNS, mount path, view name, etc.)
    └── README.md            # This file
```

---

## Default Variables (`vars/main.yml`) - for VAST View mount command

```text
|-----------------------|------------------------|----------------------------------------------------------|
| Variable              | Default Value          | Description                                              |
|-----------------------|------------------------|----------------------------------------------------------|
| `dns_alias`           | `sharespool`           | DNS alias of the VAST VIP pool                           |
| `dns_domain`          | `busab`                | DNS domain suffix                                        |
| `view_path`           | `nfs_share_1`          | NFS export path to mount (overrideable)                  |
| `mount_point`         | `/mount/share1`        | Local directory to mount share                           |
| `port_range`          | `33.20.1.11-33.20.1.13`| VAST NFS remote port range                               |
| `conns`               | `11`                   | Number of parallel connections (nconnect)                |
|-----------------------|------------------------|----------------------------------------------------------|
```

## Default Variables (`vars/main.yml`) - For download/build of driver

```text
|-----------------------|-------------------------------------------------|----------------------------------------------------------|
| Variable              | Default Value                                   | Description                                              |
|-----------------------|-------------------------------------------------|----------------------------------------------------------|
| `download_script_url` | `https://vast-nfs.s3.amazonaws.com/download.sh` | Script to fetch VAST NFS source                          |
| `output_log`          | `/tmp/ansible-out.txt`                          | Log file for build and debug output                      |
|-----------------------|-------------------------------------------------|----------------------------------------------------------|
```

---

## Tags

The role supports targeted execution via tags:

- `prereqs`   → Cloud-init wait, GCC setup, kernel check  
- `download`  → Download and extract driver tarball  
- `build`     → Build driver  
- `install`   → Install package and reboot  
- `verify`    → Verify driver module installation  
- `mountprep` → Create mount point and write mount command  
- `mount_now` → (Optional) Execute the mount command immediately  

Example: Run only mount setup and skip driver install:
```bash
ansible-playbook playbook.yml --tags mountprep
```

## Example Usage

Example: Install + Mount Command Generation

```bash
ansible-playbook -i inventory playbook.yml
```

Example: Run only mount setup and skip driver install:
```bash
ansible-playbook playbook.yml --tags mountprep
```

Example: Immediate Mount After Setup
*This runs the mount command right after preparing the mount point and saving it to file.*
```bash
ansible-playbook -i inventory playbook.yml --tags mount_now
```

Example: Override Variables
*You can override mount point, view path, or DNS settings at runtime:*
```bash
ansible-playbook -i inventory playbook.yml \
  -e "mount_point=/mnt/test view_path=nfs_share_test dns_alias=myshare dns_domain=corp"
```

---
### Integration

Include the role in a top-level playbook (vast_site.yml):

```yaml
---
- name: Install VAST NFS driver and prepare mount
  hosts: clients
  become: yes
  roles:
    - vast_nfs
```

---

### Notes

- *Cloud-init wait*: Ensure ~7–10 min after VM creation before running role.
- *Idempotent*: Tasks will not rebuild or reinstall unnecessarily.
- *Mount command saved*: Written to /usr/local/bin/nfs_mount_cmd.txt for later manual mounting.

---

Created by **Karl Vietmeier** – KCV Consulting

---

## License
Copyright (c) 2025 KCV Consulting

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
