# Ansible Playbook Low-Level Explanation

This document explains how `playbook.yml` (with `vars.yml` and the `install.sh` wrapper) provisions an Ethereum on ARM node on first boot. It walks through the automation step by step, with a deep dive into the disk, `/home` and user handling, which is where the playbook can destroy data if it gets a decision wrong.

## 1. Playbook Overview

The playbook runs locally on the device (`hosts: localhost`, `connection: local`). Its goal is to turn a generic Armbian image into an Ethereum node by configuring networking, storage, users and packages.

**Supported targets.** Any ARM64 board with at least 16 GB of RAM and a 2 TB-class NVMe disk, running an Armbian image based on Ubuntu **noble (24.04)** or **resolute (26.04)**. The three boards the project shipped for (Rock 5B, Orange Pi 5 Plus, NanoPC-T6) are still recognised by name, but a board does not need to be listed to work.

**Two phases.**

| Phase | What it does | Changes the system? |
| ----- | ------------ | ------------------- |
| **Phase 1** (1a-1f) | Requirement checks, board / NVMe / `/home` / user discovery, safety gates, prints the plan | **No** (read-only) |
| **Phase 2** (2a-2j) | APT, network, disk, users, packages, monitoring, security, finalize | Yes |

Phase 2 only starts if Phase 1 finished without a failure. With `plan_only=true` (`install.sh --plan`) the play stops after printing the plan, so you can see exactly what would happen before anything is touched. `install.sh` always runs Phase 1 first as a separate pass and asks for confirmation before running the full playbook.

## 2. Phase 1: Read-Only Checks and Discovery

### 1a. Requirements

Each check fails the run with a clear message, before anything has changed:

* **Architecture**: must be `aarch64`.
* **RAM**: at least `min_ram_mb` (default 15000 MB, because a 16 GB board reports about 15.5-16 GB usable).
* **Armbian**: `/etc/armbian-release` must exist (`require_armbian`).
* **Ubuntu release**: `ansible_distribution_release` must be in `supported_releases` (`noble`, `resolute`). `skip_os_check=true` bypasses this at your own risk.

### 1a (continued). APT suite selection

Two third-party repositories are tied to an Ubuntu release: `ethereum-on-arm` and `nginx.org`. In `vars.yml` their `repo` line contains the placeholder `@SUITE@` instead of a hard-coded release name.

1. `os_suite` is the running release (`noble` or `resolute`), or `fallback_release` (`noble`) if `skip_os_check` let an unlisted release through.
2. If `os_suite` differs from `fallback_release` (for example on resolute), the playbook sends an HTTP `HEAD` request to each repository's `suite_probe` URL (`.../dists/<suite>/InRelease`).
3. A request that gets no answer at all (network still coming up) is retried up to 5 times, 6 seconds apart.
4. A repository answering **200** uses the running release. A repository answering with **any other HTTP status** (typically 404) makes **that repository only** fall back to `fallback_release`, so a suite that is not published cannot break `apt update` later. If it still cannot be reached after the retries, the running release is kept: nothing is known about the suite, and `apt update` would fail on a dead network whatever suite was chosen.
5. The plan prints the result, for example `ethereum-on-arm: noble (resolute not published there, using fallback); nginx: resolute`.

On noble nothing is probed and both repositories use `noble`. Grafana's repository has no `@SUITE@` and is used as written.

### 1b. Board detection

1. Reads `/sys/firmware/devicetree/base/model`.
2. Strips null bytes.
3. Looks for the **longest** matching `pattern` in the `devices` dictionary (so `ROCK 5B+` wins over `ROCK 5B`) and uses its `hostname_seed`.
4. If nothing matches, builds a seed from the model string (lower-cased, non-alphanumerics replaced by `-`, kept short enough for a valid hostname), or `arm64` if the model is empty.

The disk path and partition naming are **not** stored per board any more. They are detected (next step), which is what makes unlisted boards work.

Swap size is `min(2 x RAM, swap_max_mb)`.

### 1c. NVMe discovery

1. Finds the disk that holds `/` (`findmnt` + `lsblk`) so it can be excluded.
2. Lists `/dev/nvme*n*` disks (retrying for up to 30 seconds if none is visible yet, because at first boot the NVMe can enumerate a little after the service starts) and keeps those of at least `min_nvme_size_gb` (default 1900 GB).
3. Selection:
    * `nvme_device` given: it must be one of the candidates, otherwise the run fails.
    * Exactly one candidate: it is used.
    * No candidate: the run fails.
    * Several candidates: the run fails as ambiguous. Choose one with `--nvme /dev/nvmeXnY`.
4. **Refuses to touch a disk that holds the OS**: any mount of `/`, `/boot`, `/usr`, `/var`, `/etc`, `/opt` or `/root` on it, or active swap on it, stops the run. The installer expects the OS on the SD card / eMMC.
5. Derives `partition_suffix` (`p1` for NVMe) and `partition_device` (e.g. `/dev/nvme0n1p1`).

### 1d. What is on the disk (`disk_state`)

`blkid -p` (which reads the device itself, not a cache) is run on the whole disk and on every partition. It reports a filesystem, RAID, LVM or LUKS signature if there is one. The disk is then put in exactly one state:

| `disk_state` | Meaning |
| ------------ | ------- |
| `ext4` | The **first partition** is ext4 |
| `blank` | No signature anywhere: a new disk, an empty partition table, or partitions that carry no filesystem ("unformatted") |
| `foreign` | Any other filesystem or container: NTFS, exFAT, FAT, HFS+, APFS, XFS, btrfs, swap, LVM, RAID, LUKS, ... |
| `ext4_elsewhere` | ext4 exists, but **not** as the first partition (a reused Linux disk with an EFI partition first, or ext4 written straight onto the whole disk) |

For `ext4` the playbook looks inside. If the partition is not already mounted it mounts it **read-only** on a temporary directory (a mounted one is inspected in place), then checks for:

* the **format flag file**: `/home/ethereum/.format.me` as seen when the disk is mounted on `/home`, which is `ethereum/.format.me` at the root of the partition. The same file with an underscore (`.format_me`) and the original location `/home/.format_me` also count. The list is `format_flag_files` in `vars.yml`.
* an existing `ethereum` directory,
* the top-level entries (shown in the plan),

and unmounts again. It also finds all mount points that use the disk, its UUID, and every device node on it.

### 1e. Where `/home` lives and who already exists

* **`/home` location**, from `findmnt`: on the root filesystem (SD card / eMMC), already on the NVMe partition, or a separate mount from another device.
* **`migrate_home`** is true only if `migrate_existing_home` is on, `/home` is **not** already on the target partition, and it has content.
* **Users**: regular accounts are those with a UID inside `UID_MIN..UID_MAX` from `/etc/login.defs`. The user who launched the run (`SUDO_USER`) is **always protected** from removal, even with `existing_users_policy: remove`.
* **`ethereum_password_managed`** is true only if the `ethereum` account is new or `reset_ethereum_password=true`. An existing `ethereum` account keeps its password.

### 1f. The plan

The plan lists: OS release and APT suites, board, NVMe disk / size / state, the format decision **and the reason for it**, where `/home` is now, the migration, existing users and the user actions. There is no separate authorisation step for formatting: the rules in section 3 are the authorisation. Interactive protection comes from `install.sh`, which shows this plan and asks for confirmation before it changes anything.

If `plan_only=true` the play ends here.

---

## 3. Deep Dive: Disk, `/home` and Users

This is the part that decides whether your data survives. An ext4 data disk is never formatted by accident: it takes a flag file you create on purpose. Anything that is not ext4, or holds nothing, is replaced.

### The Decision Logic: "To Format or Not To Format?"

Three rules decide it:

1. **ext4 is kept**, unless the flag file `/home/ethereum/.format.me` is on it.
2. **A new or unformatted disk is formatted.**
3. **A disk with any other filesystem (Windows, macOS, ...) is formatted.**

Nothing has to be passed on the command line for any of this, so a first-boot service and `install.sh` behave the same way. There is no `allow_disk_format` any more.

Four situations are not covered by the rules, and each is handled conservatively:

| Situation | What happens | Why |
| --------- | ------------ | --- |
| Non-ext4 first partition that is **mounted as `/home` right now** | Kept and left as it is | It is somebody's live home; destroying it under their feet is not what rule 3 is for |
| ext4 that is **not the first partition** (or ext4 on the whole disk) | **Refused**, nothing changed | Rule 1 forbids formatting it, but only an ext4 first partition can be used as `/home`. Wipe it yourself (`wipefs -a`) or pick another disk with `--nvme` |
| `/home` served by another partition of the target disk | **Refused** | The layout is not one this installer can keep or replace safely |
| The disk holds `/`, `/boot`, `/usr`, `/var`, `/etc`, `/opt`, `/root` or active swap, or several NVMe disks qualify | **Refused** | Unchanged from section 1c |

A foreign disk that is mounted somewhere **other** than `/home` (for example an NTFS disk auto-mounted under `/media`) is unmounted and formatted; if the unmount fails because it is busy, the run stops before anything is wiped.

### Decision Flow Diagram

```text
Look at the disk: blkid -p on the disk and on every partition
│
├─ no signature anywhere (new disk, empty partition table, unformatted) ──► 🔴 FORMAT   (rule 2)
│
├─ first partition is ext4
│    ├─ /home/ethereum/.format.me exists ─────────────────────────────────► 🔴 FORMAT   (rule 1)
│    └─ no flag file ─────────────────────────────────────────────────────► 🟢 KEEP     (rule 1)
│
├─ ext4 exists, but not as the first partition (or on the whole disk) ────► ⛔ REFUSE   (nothing is changed)
│
└─ anything else: NTFS, exFAT, APFS, XFS, btrfs, LVM, RAID, LUKS, ...
     ├─ the first partition is mounted as /home right now ────────────────► 🟢 KEEP     (live /home)
     └─ otherwise ────────────────────────────────────────────────────────► 🔴 FORMAT   (rule 3)
```

### Decision Summary Table

| Disk | Extra condition | Action |
| ---- | --------------- | ------ |
| New disk, empty partition table, or partitions without a filesystem | none | **FORMAT** (rule 2) |
| ext4 first partition | no flag file | **KEEP** ✓ (rule 1) |
| ext4 first partition | `/home/ethereum/.format.me` present | **FORMAT** (rule 1) |
| Other filesystem (NTFS, exFAT, HFS+, APFS, XFS, btrfs, LVM, RAID, LUKS, ...) | not mounted as `/home` | **FORMAT** (rule 3) |
| Other filesystem | first partition mounted as `/home` right now | **KEEP** ✓ (live home) |
| ext4 that is not the first partition | none | **REFUSE** |

### The Formatting Process (if `should_format` is true)

1. **Unmount** every mount point that uses the disk, in reverse order. If one is busy the run **fails** with "Nothing has been wiped" instead of continuing.
2. **Drop stale `/etc/fstab` entries** that reference the old partition path or the old UUID (a backup is kept), so the next boot cannot hang on a device that no longer exists.
3. **Wipe signatures** with `wipefs --all --force`, partitions first, then the disk.
4. **Partition table**: `label: gpt`, then one Linux partition spanning the disk, both through `sfdisk`.
5. **Kernel sync**: `partprobe`, `udevadm settle`, then `wait_for` until the partition device node exists (replaces a fixed sleep).
6. **Filesystem**: `ext4` with label `ethereum_data`; `force: true` overwrites a stubborn leftover signature.
7. **Optimisation**: `tune2fs -m 0` sets reserved blocks to 0%. The default 5% would waste about 100 GB on a 2 TB disk.

### `/home` Scenarios

Before the NVMe is mounted on `/home`, the playbook handles whatever `/home` is today:

| Situation | What happens |
| --------- | ------------ |
| **A. `/home` is on the SD card / eMMC** (existing user with home on the root filesystem) | The data partition is mounted on a temporary staging directory and the current `/home` content is copied with `rsync -aHAX --numeric-ids --ignore-existing --exclude=/lost+found`. Existing NVMe files are **never overwritten**. Only then is the NVMe mounted over `/home`. The original files remain on the SD card, hidden under the mount. Turn this off with `migrate_existing_home: false`. rsync exit code 24 (files vanished during the copy) is treated as success. |
| **B. `/home` is already on the NVMe** | Nothing to copy. If the disk is preserved it is simply (re)mounted by UUID. |
| **C. `/home` is a separate mount from another device** | Content is copied as in A, then the old mount is released. If it is busy the run fails with a clear message (the copy has already happened). |
| **D. Preserved disk already holds an `ethereum` home** | If the `ethereum` user does not exist yet, its numeric UID/GID are read from that directory and reused when they are free and in the normal user range, so no ownership fix is needed. |

### Mounting

* **UUID lookup**: `/etc/fstab` uses the UUID, because `/dev/nvme0n1` naming can change when other drives are added.
* **Mount and persist**: `ansible.posix.mount` with `state: mounted`, options `defaults,noatime`, filesystem type `ext4` after a format or the detected type when data is preserved.

### User Handling

* **`ethereum` group and user** are created only if missing (using the UID/GID hints from scenario D when they apply) with `move_home: true`.
* **Password**: forced to `ethereum_password` with a required change at first login **only when `ethereum_password_managed` is true** (new account, or `reset_ethereum_password=true`). An existing `ethereum` account keeps its password.
* **Sudo**: password-less sudo through `/etc/sudoers.d/90-ethereum-nopasswd`, validated with `visudo -c -f` before it is installed (this form works with both classic sudo and the `sudo-rs` shipped with Ubuntu 26.04).
* **Removing other users** (`existing_users_policy: remove`, default): only the **account** is removed (`remove: false`). Home directories are never deleted, because they may hold data that was just migrated or preserved. `SUDO_USER` is never removed. With `keep`, nobody is removed.

---

## 4. Remaining Tasks

### APT Setup (Phase 2a)

* **Non-interactive**: `DEBIAN_FRONTEND=noninteractive` in `/etc/environment`.
* **Prerequisites first**: installs `ca-certificates`, `curl` and `gpg` before any key is fetched (minimal images do not always ship them).
* **Keys**: downloaded with `get_url`, or fetched and de-armored (`curl | gpg --dearmor`) into `/etc/apt/keyrings` (nginx into `/usr/share/keyrings`).
* **Pinning**: prefers `nginx.org` packages over Ubuntu's.
* **Repositories**: each `repo` line has `@SUITE@` replaced by the suite chosen in Phase 1 (see "APT suite selection"), then written to `/etc/apt/sources.list.d/`.
* Then `apt update` and installation of `base_packages`.

### Network Configuration (Phase 2b)

* **Netplan override**: `99-optional-interfaces.yaml` marks interfaces `optional: true` so a missing cable does not block boot. Skipped if `/etc/netplan` does not exist.
* **NTP**: configures `systemd-timesyncd` with the servers from `vars.yml` and restarts it on change.
* **Hostname**: finds the interface used by the default route (`ip route get 8.8.8.8`, reading the token after `dev`, which stays correct whether or not the route has a `via` gateway), reads its MAC address, takes the first 8 characters of its SHA256, and builds `ethereumonarm-<hostname_seed>-<hash>`. `/etc/hostname` and `/etc/hosts` are updated immediately.

### Package Installation (Phase 2e)

Standard `apt install` for the Ethereum clients and dependencies, with an automatic `dpkg --configure -a` repair on failure.

### Ethereum Configuration (Phase 2f)

* **Directory structure**: creates the standard tree (`.ethereum`, `.lighthouse`, ...) in the ethereum home, which is now on the NVMe disk.
* **Swap file**: configures `dphys-swapfile` to create a swap file in the ethereum home on the NVMe (2 x RAM, capped at `swap_max_mb`).

### Monitoring (Phase 2g)

Creates the Prometheus user and directories, installs the monitoring packages and enables Prometheus, node exporter and Grafana.

### Security (Phase 2h)

* **Lock root**: `passwd -l root`, so people log in as `ethereum` and use `sudo`.
* **User cleanup**: removes other regular accounts as described under "User Handling".
* **Ownership check**: the recursive `chown` of the ethereum home runs **only** if a `find` finds a file with the wrong owner or group. A preserved multi-TB chain database is therefore not rewritten on every run.
* **Nginx** is enabled.

### Final Access Enforcement (Phase 2i)

Runs last so nothing installed earlier can undo it: enforces the password and the forced change at first login (only when `ethereum_password_managed`), makes sure SSH allows password login, and removes Armbian's `/root/.not_logged_in_yet` marker so the first-login wizard does not start.

### Finalize (Phase 2j)

* Creates the `first-run` flag file.
* Prints a summary: NVMe action, where `/home` was migrated from, users removed / kept / not removable, and the login details.
* Schedules `shutdown -r +1` **only if `reboot_after` is true** (`install.sh --no-reboot` turns it off).

---

## 5. Running as a First-Boot Service vs. `install.sh`

Both paths run the same `playbook.yml` and `vars.yml`. What differs is who is there to answer questions.

| | First-boot service (image) | `install.sh` |
| --- | --- | --- |
| Command | `ansible-playbook -i inventory.yml playbook.yml --connection=local` | The same, plus `-e` flags, after a `plan_only=true` pass |
| Operator | None | Yes (or `--yes`) |
| Confirmation | None: Phase 1 and Phase 2 run in one pass | Plan shown, then confirmed |
| `SUDO_USER` | Empty, so no account is protected from removal | The invoking user is protected |
| Dependencies | Must already be in the image | Installed by the script |
| Plan output | In the service log / journal | On screen and in `/var/log/eoa-install.log` |

What the first-boot service needs to guarantee:

* `ansible` **with** the `ansible.posix` and `community.general` collections (the Ubuntu `ansible` package bundles them; `ansible-core` does not) and `python3-passlib`, installed at image build time.
* The playbook directory outside `/home` (for example `/opt/ethereumonarm/ansible`).
* Network up before it starts (`After=network-online.target`); the run downloads packages and repository keys.
* The service must not run again once `/root/first-run.flag` exists (`ConditionPathExists=!/root/first-run.flag`). The playbook creates that flag only at the very end of a successful run.
* `/etc/armbian-release` present in the image (or `require_armbian=false`).
* `EOA_MINOR_VERSION` in the service environment if `/etc/eoa-release` should carry the real minor version (`install.sh` leaves it at `0`).

Behaviors that matter only when nobody is watching:

* **Nothing needs to be configured for the disk.** The three rules apply as they are: a new / unformatted disk or any non-ext4 disk is formatted, an ext4 disk is kept unless `/home/ethereum/.format.me` is on it. The image copy of `vars.yml` is the same file as the repository's; no build-time patching is needed.
* **Refusals are failures, not questions.** The disk holds the OS or swap, ext4 that is not the first partition, several qualifying NVMe disks, too little RAM or NVMe capacity: the run stops with the reason in the log before anything is changed. The flag file is not created, so the service tries again on the next boot.
* **A blank NVMe** is formatted with no questions, which is the normal first-boot case.
* **A previously provisioned NVMe** (ext4 with data, no `.format.me`) is kept and mounted, and the new SD card gets a fresh `ethereum` user that reuses the numeric IDs of the existing home when they are free.
* **Users**: with no `SUDO_USER`, every regular account other than `ethereum` is removed (home directories kept), as before.
* **`ethereum` account already present in the image**: its password is left alone (`ethereum_password_managed` is false). If the image builder pre-creates that user and the first-login password change is expected, set `reset_ethereum_password: true`.

---

## 6. Running It

`install.sh` installs the dependencies (`git`, `ansible`, `python3-passlib`, the `ansible.posix` and `community.general` collections), downloads the playbook, runs Phase 1, asks for confirmation and then runs the full playbook. It works from `/opt/eoa-installer` and pins Ansible's home to `/root`, never under `/home`, which gets remounted during the run.

```bash
sudo ./install.sh --plan        # read-only: print the plan, change nothing
sudo ./install.sh               # plan, confirm, run
```

| `install.sh` flag | Playbook variable | Effect |
| ----------------- | ----------------- | ------ |
| `--plan` | `plan_only=true` | Stop after Phase 1 |
| `-y`, `--yes` | (none) | Skip the confirmation prompt (required without a TTY) |
| `--nvme /dev/nvmeXnY` | `nvme_device` | Pick the disk when several qualify |
| `--keep-users` | `existing_users_policy=keep` | Do not remove existing users |
| `--no-reboot` | `reboot_after=false` | No reboot at the end |
| `--skip-os-check` | `skip_os_check=true` | Allow a release other than noble / resolute |
| `--ansible-dir DIR` | (none) | Use local playbook files instead of cloning |
| `--ref REF`, `--repo URL` | (none) | Use another git branch or repository |
| `-e K=V` | any | Pass an extra variable |

`--wipe-nvme` is still accepted so old command lines do not break, but it does nothing.

Variables that can only be set with `-e` / `vars.yml`: `min_ram_mb`, `min_nvme_size_gb`, `supported_releases`, `fallback_release`, `migrate_existing_home`, `reset_ethereum_password`, `format_flag_files`, `swap_max_mb`.

To ask for a wipe of an ext4 data disk on the next run, create the flag file while the disk is mounted on `/home`: `touch /home/ethereum/.format.me` (the `ethereum` user can do this without `sudo`). The disk is formatted on the next run, and the flag disappears with the rest of the data.