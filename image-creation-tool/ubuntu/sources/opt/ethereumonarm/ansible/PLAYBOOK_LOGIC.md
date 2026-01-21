# Ansible Playbook Low-Level Explanation

This document provides a detailed, low-level explanation of the `playbook.yml` used for the first-boot provisioning of Ethereum on ARM nodes. It breaks down how the automation works, step-by-step, with a specific deep dive into the disk management logic.

## 1. Playbook Overview

The playbook runs locally on the device (`hosts: localhost`, `connection: local`) immediately after the first boot. Its primary goal is to turn a generic Ubuntu image into a specialized Ethereum node by configuring hardware, users, networking, storage, and installing necessary software.

## 2. Low-Level Task Analysis

### Device Detection
This section identifies which board the OS is running on (e.g., Rock 5B, Raspberry Pi 5).
1.  **Reads Device Tree**: It reads `/sys/firmware/devicetree/base/model` to get the raw hardware identifier string.
2.  **Regex Cleaning**: Removes null bytes (`\x00`) from the string to make it usable.
3.  **Pattern Matching**: Loops through a dictionary of known devices (`vars.yml`) to find a match.
    *   It matches the "detected_model" against patterns like "ROCK 5B".
    *   **Crucial Variables Set**: When a detection match is found, it sets:
        *   `target_disk`: The NVMe device path (e.g., `/dev/nvme0n1`).
        *   `partition_suffix`: How partitions are named (e.g., `p1` vs `1`).
        *   `hostname_seed`: A short name for hostname generation.

### APT Setup
Sets up the package manager sources.
*   **Non-interactive**: Forces `DEBIAN_FRONTEND=noninteractive` in `/etc/environment` to prevent apt from pausing for user input during installs.
*   **Key Management**: Downloads GPG keys for repositories (`get_url`) or fetches and de-armors ASCII keys (`curl | gpg --dearmor`) to `/etc/apt/keyrings`.
*   **Pinning**: Sets priority for Nginx packages to prefer `nginx.org` over Ubuntu default repos.
*   **Repository Addition**: Adds the actual `deb [...]` lines to `/etc/apt/sources.list.d/`.

### Network Configuration
*   **Netplan Override**: Creates a high-priority netplan config (`99-optional-interfaces.yaml`) ensuring that if an ethernet interface fails to come up, it doesn't block the boot process (`optional: true`).
*   **NTP (Time)**: Time synchronization is critical for blockchains. It configures `systemd-timesyncd` with custom NTP servers and creates a notification handler to restart the service if changed.
*   **Hostname Generation**:
    1.  Finds the active network interface (via `ip route get 8.8.8.8`).
    2.  Reads the MAC address of that interface.
    3.  Hashes the MAC address with SHA256 and takes the first 8 characters.
    4.  Constructs hostname: `ethereumonarm-[model]-[hash]`.
    5.  Updates `/etc/hostname` and `/etc/hosts` immediately.

---

## 3. Deep Dive: Disk Login (Configuration & Formatting)

This is the most critical and complex part of the playbook. It decides whether to wipe your disk or preserve your existing blockchain data.

### The Decision Logic: "To Format or Not To Format?"

The goal is idempotency: **If the user already has data, do not touch it. If it's a fresh install or explicitly requested, wipe it.**

1.  **Identify Partition Path**:
    Constructs the full path string: `{{ target_disk }}{{ partition_suffix }}` (e.g., `/dev/nvme0n1p1`).

2.  **Check Existing Filesystem (`blkid`)**:
    *   Runs `blkid -o value -s TYPE /dev/nvme0n1p1`.
    *   **If it returns a type (e.g., `ext4`)**: The variable `partition_type.stdout` will contain "ext4".
    *   **If it returns nothing/error**: The partition is raw/empty. `partition_type.stdout` is empty.

3.  **The "Peek" inside the Disk**:
    If a filesystem *was* detected, the playbook doesn't trust it blindly. It looks inside to see if it's *our* data.
    *   **Create Temp Mount**: `disk_check_XXXX` directory.
    *   **Mount (Ephemeral)**: Mounts the partition to this temp directory.
    *   **Check for `ethereum` directory**: Look for `[mountpoint]/ethereum`. If this exists, we assume it's a valid data disk we should keep.
    *   **Check for `format_flag`**: Look for a specific file (e.g., `force_format`). If this exists, the user wants us to wipe the disk explicitly.
    *   **Unmount**: Immediately unmounts.

4.  **The Boolean Decision (`should_format`)**:
    A variable `should_format` is set to `true` IF:
    *   The partition has NO filesystem (`partition_type` is empty).
    *   **OR**
    *   The manual `format_flag` file was found inside the existing partition.

    *Crucially, if the filesystem exists AND the `ethereum` folder is found AND no format flag exists, `should_format` is `false`.*

### The Formatting Process (If `should_format` is True)

If the decision is verified as "Go for destroy":

1.  **Safety Unmount**: `umount /dev/nvme0n1*` ensures nothing is currently using the disk.
2.  **Wipe Signatures**: `wipefs --all --force` removes magic strings (like filesystem headers, RAID signatures) from the device, making it look "new" to the OS.
3.  **Partition Table Creation (sfdisk)**:
    *   Pipes `label: gpt` to `sfdisk`. This creates a brand new GUID Partition Table.
    *   Pipes `type=linux` to `sfdisk --append`. This creates a single partition spanning the entire disk.
4.  **Kernel Sync**:
    *   `partprobe`: Tells the kernel to re-read the partition table.
    *   `udevadm settle`: Pauses the playbook until `udev` (the device manager) has finished creating the device nodes (`/dev/nvme0n1p1`) in the filesystem. This prevents "File not found" errors in the next step.
5.  **Filesystem Creation (Format)**:
    *   Uses `fs_type: ext4`.
    *   Sets label (`-L data`).
    *   **`force: true`**: This is critical. If `wipefs` missed something deep, or if the kernel still thinks there's a signature (like we saw with the NTFS error), this flag tells `mkfs.ext4` to overwrite it regardless.
6.  **Optimization**: `tune2fs -m 0` sets the reserved blocks count to 0%. By default, Linux reserves 5% of disk space for root. For a 2TB drive, that's 100GB wasted. We reclaim that for blockchain data.

### Mounting
Once formatted (or inferred as safe):
*   **UUID Lookup**: Gets the stable UUID of the partition. We use UUIDs in `/etc/fstab` because `/dev/nvme0n1` naming can change if you plug in other drives.
*   **Fstab & Mount**: Adds the entry to `/etc/fstab` and mounts it to `/home`.

---

## 4. Remaining Tasks

### User Setup
*   Creates the `ethereum` user with a home directory.
*   **Hash Password**: Generates the SHA512 hash of the password provided in `vars.yml`.
*   **Idempotency**: `update_password: on_create` ensures that if you change the password later manually, the playbook won't overwrite it on a re-run.
*   **Sudo**: Grants password-less sudo access via `/etc/sudoers.d/`.

### Package Installation
*   Standard `apt install` for Ethereum clients and dependencies.
*   Auto-fixes broken installs (`dpkg --configure -a`).

### Ethereum Configuration
*   **Directory Structure**: Creates the standard directory tree (`.ethereum`, `.lighthouse`, etc.) inside the user's home (which is now on the NVMe drive).
*   **Swap File**: Configures `dphys-swapfile` to create a large swap file on the NVMe drive. This is crucial for ARM boards with limited RAM (e.g., 8GB/16GB) to prevent OOM kills during heavy syncing.

### Monitoring & Security
*   Sets up Prometheus/Grafana users and directories.
*   **Lock Root**: Disables the root password (`passwd -l root`) forcing users to login as `ethereum` and use `sudo`.
*   **User Cleanup**: Scans `/etc/passwd` for UID ranges and removes default users (like `ubuntu` or `rock`) that might have come with the base image, reducing the attack surface.

### Finalize
*   Creates a `first-run` flag file.
*   Schedules a reboot (`shutdown -r +1`) to ensure all kernel changes, hostname changes, and service starts take clean effect.
