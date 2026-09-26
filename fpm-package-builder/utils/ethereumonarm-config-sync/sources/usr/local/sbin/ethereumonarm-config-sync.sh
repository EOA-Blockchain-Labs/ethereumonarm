#!/bin/bash
#
# ethereumonarm-config-sync.sh
#
# Mirrors a small set of paths between the root disk (SD card / eMMC) and the NVMe disk, in
# whichever direction keeps each one backed up onto the disk it doesn't normally live on. If
# one disk later fails and gets replaced, the Ansible playbook's first boot restores what it
# can from the surviving disk's copy - see "Cross-disk Backups" in PLAYBOOK_LOGIC.md.
#
# Run on a schedule by ethereumonarm-config-sync.timer, and safe to run manually or on demand
# (e.g. via "systemctl start ethereumonarm-config-sync.service") at any time in between.
#
# The two directions are not symmetric, and this script does not try to make them so:
#   - root_disk_paths:  live on the root disk, mirrored onto the NVMe disk. This is a plain
#     mirror in both directions of travel - synced here with --delete so the backup doesn't
#     accumulate files the live config no longer has, and restored by Ansible by overlaying
#     the backup onto fresh package defaults (see the playbook for that half).
#   - home_disk_paths:  live under the ethereum home (on the NVMe disk), mirrored onto the
#     root disk. Also synced here with --delete for the same reason, but Ansible only ever
#     restores these when the live copy is missing entirely - never overlaid on top of one
#     that already exists. This is for state that cannot be regenerated if lost (for example,
#     an Obol Charon cluster's data).
#
# Keep the paths below in sync with root_disk_backup_paths / home_disk_backup_paths /
# home_disk_backup_root in the Ansible playbook's vars.yml - the playbook can only restore
# what this script backs up to the location it expects.

set -euo pipefail

ETHEREUM_HOME="/home/ethereum"
HOME_DISK_BACKUP_ROOT="/var/backups/ethereumonarm"

ROOT_DISK_PATHS=(
  "/etc/ethereum"
  "/var/spool/cron/crontabs/ethereum"
)

HOME_DISK_PATHS=(
  "$ETHEREUM_HOME/.charon"
)

# sync_path SRC DEST
# Mirrors SRC onto DEST, matching whichever of the two it is (a single file or a whole
# directory), and does nothing if SRC doesn't exist yet (nothing has been set up to back up).
# (No -z: source and destination are both on the same host, so compression only costs CPU.)
sync_path() {
  local src="$1" dest="$2"
  if [[ ! -e "$src" ]]; then
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  if [[ -d "$src" ]]; then
    mkdir -p "$dest"
    rsync -a --delete "$src/" "$dest/"
  else
    rsync -a "$src" "$dest"
  fi
}

# The systemd service that runs this script defaults to root (no User= directive), which is
# needed here: some of the paths above (the crontab file, the charon directory) are readable
# only by the ethereum account otherwise, and root is the only account guaranteed to read both
# sides regardless of who owns what.

for path in "${ROOT_DISK_PATHS[@]}"; do
  dest="$ETHEREUM_HOME/.${path#/}"
  sync_path "$path" "$dest"
done

for path in "${HOME_DISK_PATHS[@]}"; do
  dest="$HOME_DISK_BACKUP_ROOT$path"
  sync_path "$path" "$dest"
done

# The ethereum user's own backups (everything under $ETHEREUM_HOME/.<...>) should be readable
# by that account, matching the rest of its home directory. This is not needed for
# $HOME_DISK_BACKUP_ROOT, which lives outside $ETHEREUM_HOME entirely and is only ever read by
# root (via this script and the Ansible restore).
if [[ -d "$ETHEREUM_HOME" ]]; then
  chown -R ethereum:ethereum "$ETHEREUM_HOME"/.[!.]* 2>/dev/null || true
fi

# Lock down the root-disk backup root: it can hold sensitive data (an Obol Charon cluster's
# validator keys and slashing protection database), and nothing other than root needs to read
# it - the Ansible restore that reads it back also runs as root.
if [[ -d "$HOME_DISK_BACKUP_ROOT" ]]; then
  chmod 700 "$HOME_DISK_BACKUP_ROOT"
fi

echo "Cross-disk backups synced."