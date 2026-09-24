#!/usr/bin/env bash
#
# Ethereum on ARM - installer for Armbian (ARM64)
#
# Turns a fresh Armbian (Ubuntu noble or resolute) image on any ARM64 board with >= 16 GB RAM and a
# >= 2 TB NVMe disk into an Ethereum node / staking node. It:
#   1. installs git, ansible and python3-passlib
#   2. downloads the Ansible playbook + its files from the Ethereum on ARM repository
#   3. runs a READ-ONLY plan (what will happen to the NVMe, /home and the existing users)
#   4. asks for confirmation (skipped with --yes) and runs the playbook
#
# Manual equivalent:
#   apt update && apt -y install git ansible python3-passlib
#   git clone https://github.com/EOA-Blockchain-Labs/ethereumonarm.git
#   cd ethereumonarm/image-creation-tool/ubuntu/sources/opt/ethereumonarm/ansible/
#   ansible-playbook -i inventory.yml playbook.yml --connection=local
#
set -Eeuo pipefail

# ----------------------------------------------------------------------------
# Settings (all overridable from the environment)
# ----------------------------------------------------------------------------
REPO_URL="${EOA_REPO_URL:-https://github.com/EOA-Blockchain-Labs/ethereumonarm.git}"
REPO_REF="${EOA_REPO_REF:-main}"
# Used only to word the "run as root" hint correctly when this script is piped into bash
# (curl -fsSL ... | sudo bash) rather than run as a file. Not used for anything else.
INSTALL_URL="${EOA_INSTALL_URL:-https://raw.githubusercontent.com/EOA-Blockchain-Labs/ethereumonarm/main/install.sh}"
ANSIBLE_SUBDIR="image-creation-tool/ubuntu/sources/opt/ethereumonarm/ansible"
# Never under /home: /home is about to be replaced by the NVMe mount.
WORK_DIR="${EOA_WORK_DIR:-/opt/eoa-installer}"
LOG_FILE="${EOA_LOG_FILE:-/var/log/eoa-install.log}"
LOCK_FILE="${EOA_LOCK_FILE:-/run/eoa-install.lock}"

# Kept for error messages only: the parsing loop below consumes "$@" via shift, so by the
# time anything checks "$@" or "$*" again (e.g. the root check), the original flags are gone.
ORIG_ARGS=("$@")

ASSUME_YES=0
PLAN_ONLY=0
LOCAL_DIR=""
EXTRA_ARGS=()      # -e key=value pairs for ansible-playbook
PASSTHROUGH=()     # anything after "--" goes to ansible-playbook untouched

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------
log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARNING:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: install.sh [options] [-- extra ansible-playbook args]

Requirements: ARM64 board, >= 16 GB RAM, >= 2 TB NVMe disk, Armbian image based on
Ubuntu noble or resolute. The OS must live on the SD card / eMMC; the NVMe becomes /home.

What happens to the NVMe disk:
  ext4 first partition        kept, unless the file /home/ethereum/.format.me exists on it
  new / unformatted disk      formatted
  any other filesystem        formatted (Windows, macOS, XFS, btrfs, LVM/RAID/LUKS, ...)
  Refused instead (nothing is changed): the disk holds the OS or swap, ext4 data that is
  not its first partition, or several NVMe disks qualify (choose one with --nvme).
  The plan is always shown first; without --yes you are asked to confirm it.

Options:
  --plan              Run the read-only checks, print what would happen, change nothing.
  -y, --yes           Do not ask for confirmation (unattended / first-boot use).
  --nvme PATH         NVMe device to use (e.g. /dev/nvme1n1). Required only when more
                      than one NVMe disk qualifies.
  --keep-users        Do not remove the accounts that already exist on the image.
                      (By default they are removed - their home directories are kept -
                      except the user who launched this script.)
  --no-reboot         Do not schedule the reboot at the end.
  --skip-os-check     Do not insist on Armbian / Ubuntu noble or resolute (packages may not install).
  --ansible-dir DIR   Use the playbook files in DIR instead of downloading them
                      (DIR is copied to the work directory first).
  --ref REF           Git branch or tag of the repository to use (default: main).
  --repo URL          Git repository to download from.
  -e, --extra-vars K=V
                      Extra variable for the playbook (repeatable), e.g. -e min_ram_mb=7000
  -h, --help          This help.

Examples:
  sudo ./install.sh --plan                    # see what would happen, change nothing
  sudo ./install.sh                           # interactive install
  sudo ./install.sh --yes                     # unattended, no confirmation prompt

  # From GitHub, without downloading the file first:
  curl -fsSL <URL-of-install.sh> | sudo bash                     # default interactive install
  curl -fsSL <URL-of-install.sh> | sudo bash -s -- --plan        # flags need "-s --" first
  curl -fsSL <URL-of-install.sh> | sudo bash -s -- --yes

Log: /var/log/eoa-install.log
EOF
}

have_tty() { [[ -t 0 ]] || { : </dev/tty; } 2>/dev/null; }

confirm() {
  local prompt="$1" answer=""
  if [[ -t 0 ]]; then
    read -r -p "$prompt [y/N] " answer || true
  else
    read -r -p "$prompt [y/N] " answer </dev/tty || true
  fi
  [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

# ----------------------------------------------------------------------------
# Arguments
# ----------------------------------------------------------------------------
while (($#)); do
  case "$1" in
    --plan)          PLAN_ONLY=1 ;;
    -y|--yes)        ASSUME_YES=1 ;;
    --wipe-nvme)     warn "--wipe-nvme is no longer needed and is ignored (see --help: what happens to the NVMe disk)" ;;
    --nvme)
      [[ $# -ge 2 ]] || die "--nvme needs a device path"
      [[ "$2" =~ ^/dev/nvme[0-9]+n[0-9]+$ ]] || die "--nvme expects a device like /dev/nvme0n1 (got '$2')"
      EXTRA_ARGS+=(-e "nvme_device=$2"); shift ;;
    --keep-users)    EXTRA_ARGS+=(-e "existing_users_policy=keep") ;;
    --no-reboot)     EXTRA_ARGS+=(-e "reboot_after=false") ;;
    --skip-os-check) EXTRA_ARGS+=(-e "skip_os_check=true") ;;
    --ansible-dir)
      [[ $# -ge 2 ]] || die "--ansible-dir needs a directory"
      LOCAL_DIR="$2"; shift ;;
    --ref)
      [[ $# -ge 2 ]] || die "--ref needs a value"
      REPO_REF="$2"; shift ;;
    --repo)
      [[ $# -ge 2 ]] || die "--repo needs a value"
      REPO_URL="$2"; shift ;;
    -e|--extra-vars)
      [[ $# -ge 2 && "$2" == *=* ]] || die "$1 needs KEY=VALUE"
      EXTRA_ARGS+=(-e "$2"); shift ;;
    -h|--help)       usage; exit 0 ;;
    --)              shift; PASSTHROUGH=("$@"); break ;;
    *)               usage >&2; die "unknown option: $1" ;;
  esac
  shift
done

# ----------------------------------------------------------------------------
# Environment
# ----------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
  if [[ -f "$0" ]]; then
    die "run as root:  sudo $0${ORIG_ARGS[*]+ "${ORIG_ARGS[*]}"}"
  else
    # $0 is "bash" here, not a usable path: this script is running piped into bash
    # (curl -fsSL ... | bash), so re-run the whole pipe with sudo instead.
    if ((${#ORIG_ARGS[@]})); then
      die "run as root, e.g.:  curl -fsSL $INSTALL_URL | sudo bash -s -- ${ORIG_ARGS[*]}"
    else
      die "run as root, e.g.:  curl -fsSL $INSTALL_URL | sudo bash"
    fi
  fi
fi
[[ "$(uname -m)" =~ ^(aarch64|arm64)$ ]] || die "this installer is for ARM64 boards (found $(uname -m))"
command -v apt-get >/dev/null 2>&1 || die "apt-get not found: a Debian/Ubuntu based image (Armbian) is required"

mkdir -p "$WORK_DIR" "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'printf "\n\033[1;31mERROR:\033[0m failed at line %s - see %s\n" "$LINENO" "$LOG_FILE" >&2' ERR

# One installer at a time.
exec 9>"$LOCK_FILE"
flock -n 9 || die "another installation is already running"

# Ansible (and this script) must not keep anything under /home: it is replaced by the
# NVMe mount half way through the run. Also stop sudo from leaking the caller's HOME.
export HOME=/root
export ANSIBLE_HOME=/root/.ansible
export ANSIBLE_LOCAL_TEMP=/root/.ansible/tmp
export ANSIBLE_REMOTE_TEMP=/root/.ansible/tmp
export ANSIBLE_NOCOLOR=1
export ANSIBLE_RETRY_FILES_ENABLED=0
export ANSIBLE_CALLBACK_RESULT_FORMAT=yaml      # readable multi-line output for the plan
export DEBIAN_FRONTEND=noninteractive
cd "$WORK_DIR"

log "Ethereum on ARM installer ($(date -Is))"
[[ -f /root/first-run.flag ]] && warn "This system was provisioned before. Re-running is safe: existing data and users are preserved."
if [[ -f /etc/armbian-release ]]; then
  # shellcheck disable=SC1091
  . /etc/armbian-release
  echo "Armbian ${VERSION:-?} on ${BOARD_NAME:-${BOARD:-unknown board}}"
fi

# ----------------------------------------------------------------------------
# 1. Dependencies
# ----------------------------------------------------------------------------
log "Installing git, ansible and python3-passlib"
APT=(apt-get -y -o DPkg::Lock::Timeout=300 -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold)
"${APT[@]}" update
"${APT[@]}" install ca-certificates curl gpg git ansible python3-passlib

# The apt 'ansible' package bundles these, but can lag behind: an old collection build can carry
# now-deprecated code of its own (import paths, module_utils APIs, ...) that prints warnings
# unrelated to anything in this playbook. Always try to upgrade to the latest release, not only
# when a collection is missing outright.
log "Updating ansible.posix / community.general collections"
if ! ansible-galaxy collection install ansible.posix community.general --upgrade; then
  warn "Could not reach Ansible Galaxy to update collections; continuing with what is already installed"
fi

missing=()
ansible-doc -t module ansible.posix.mount >/dev/null 2>&1        || missing+=(ansible.posix)
ansible-doc -t module community.general.filesystem >/dev/null 2>&1 || missing+=(community.general)
if ((${#missing[@]})); then
  die "Required Ansible collection(s) still missing after the update attempt: ${missing[*]}. Install manually with: ansible-galaxy collection install ${missing[*]}"
fi

# ----------------------------------------------------------------------------
# 2. Playbook files
# ----------------------------------------------------------------------------
SRC_DIR="$WORK_DIR/src"
rm -rf "$SRC_DIR"
if [[ -n "$LOCAL_DIR" ]]; then
  [[ -f "$LOCAL_DIR/playbook.yml" ]] || die "$LOCAL_DIR/playbook.yml not found"
  log "Using local playbook files from $LOCAL_DIR"
  ANSIBLE_DIR="$SRC_DIR/ansible"
  mkdir -p "$ANSIBLE_DIR"
  cp -a "$LOCAL_DIR"/. "$ANSIBLE_DIR"/
else
  log "Downloading the playbook from $REPO_URL ($REPO_REF)"
  mkdir -p "$SRC_DIR"
  git -C "$SRC_DIR" init -q
  git -C "$SRC_DIR" remote add origin "$REPO_URL"
  git -C "$SRC_DIR" sparse-checkout set --cone "$ANSIBLE_SUBDIR"     # only this directory
  git -C "$SRC_DIR" fetch -q --depth 1 --filter=blob:none origin "$REPO_REF" \
    || git -C "$SRC_DIR" fetch -q --depth 1 origin "$REPO_REF" \
    || die "could not download $REPO_URL ($REPO_REF) - check the network connection"
  git -C "$SRC_DIR" checkout -q FETCH_HEAD
  ANSIBLE_DIR="$SRC_DIR/$ANSIBLE_SUBDIR"
fi
for f in playbook.yml vars.yml inventory.yml; do
  [[ -f "$ANSIBLE_DIR/$f" ]] || die "$f is missing in $ANSIBLE_DIR"
done

run_playbook() {
  (cd "$ANSIBLE_DIR" && ansible-playbook -i inventory.yml playbook.yml --connection=local \
      "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}" "${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}" "$@")
}

# ----------------------------------------------------------------------------
# 3. Read-only plan + safety checks
# ----------------------------------------------------------------------------
log "Checking the board and building the plan (read-only, nothing is changed)"
if ! run_playbook -e plan_only=true; then
  die "the checks failed or the run was refused (see above). Nothing has been changed."
fi
if ((PLAN_ONLY)); then
  log "Plan only: stopping here. Run again without --plan to install."
  exit 0
fi

# ----------------------------------------------------------------------------
# 4. Confirmation + provisioning
# ----------------------------------------------------------------------------
if ((!ASSUME_YES)); then
  have_tty || die "no terminal to ask for confirmation. Re-run with --yes to proceed unattended."
  confirm "Apply the plan above?" || die "aborted by the user. Nothing has been changed."
fi

log "Provisioning (this takes a while: it downloads all Ethereum clients)"
run_playbook

log "Done."
cat <<'EOF'

Log in as  ethereum  (password: ethereum - you will be asked to change it), unless the
'ethereum' user already existed: then its current password is unchanged.
The board reboots one minute after the run to apply the configuration
(pass --no-reboot to skip it).
EOF
