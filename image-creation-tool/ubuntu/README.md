# Ubuntu Image Builder

This directory contains tooling to build custom **Ethereum on ARM** images for ARM single-board computers (SBCs) based on Armbian.

## Overview

The build process downloads official Armbian minimal images, mounts them, injects the Ethereum on ARM first-boot scripts, and produces ready-to-flash `.img` files for supported devices.

## Supported Devices

| Device | Armbian Base | Kernel |
| ------ | ------------ | ------ |
| **Raspberry Pi 5** | `rpi4b` | Current 6.12.x |
| **Rock 5B** | `rock-5b` | Vendor 6.1.x |
| **Rock 5T** | `rock-5t` | Vendor 6.1.x |
| **Orange Pi 5 Plus** | `orangepi5-plus` | Vendor 6.1.x |
| **NanoPC T6** | `nanopct6-lts` | Vendor 6.1.x |

## Prerequisites

- **Linux host** (Ubuntu 22.04+ recommended)
- **sudo** privileges for mounting images
- **Tools**: `wget`, `xz-utils`, `make`

```bash
sudo apt-get install wget xz-utils make
```

## Usage

### Build All Images

```bash
make all
```

This downloads Armbian images for all supported devices, injects the first-boot scripts, and outputs final images.

### Build a Single Device

```bash
make build DEVICE=rock5b
```

Available devices: `rpi5`, `rock5b`, `rock5t`, `orangepi5-plus`, `nanopct6`

### Show Help

```bash
make help
```

### Clean Up

```bash
make clean
```

Removes all downloaded archives and generated images.

## Output

Built images are named using the format:

```text
ethonarm_<device>_<YY.MM>.<release>.img
```

Example: `ethonarm_rock5b_26.01.00.img`

A `manifest.txt` file is generated with SHA256 checksums for verification.

## How It Works

1. **Download** — Fetches the compressed Armbian minimal image from the official mirror
2. **Decompress** — Extracts the `.img` file from the `.xz` archive
3. **Mount** — `modify_image.sh` detects the root partition using `fdisk` and loop-mounts it
4. **Inject Scripts** — Copies the `ethereum-first-boot` script and systemd service
5. **Cleanup** — Removes Armbian's interactive first-login prompts using `modify_image.sh`
6. **Finalize** — Unmounts, renames to the final format, and generates checksums

## Source Files

| File | Description |
| ---- | ----------- |
| `sources/usr/local/bin/ethereum-first-boot` | Main initialization script |
| `sources/etc/systemd/system/ethereum-first-boot.service` | Systemd service |
| `sources/usr/local/sbin/check_install` | Installation verification |

## Customization

### Adding a New Device

1. Find the Armbian minimal image URL from [sbcmirror.org](https://es.sbcmirror.org/)
2. Add the device to the `Makefile`:

```makefile
# Add to DEVICES list
DEVICES = rpi5 rock5b rock5t orangepi5-plus nanopct6 newdevice

# Add device configuration
newdevice_url := https://es.sbcmirror.org/dl/newdevice/...
newdevice_iso := Armbian_XX.XX.X_Newdevice_noble_...img
```

## Troubleshooting

| Issue | Solution |
| ----- | -------- |
| **Mount failed** | Verify the partition offset with `fdisk -l` |
| **Permission denied** | Run with `sudo` or ensure you have sudo privileges |
| **Download failed** | Check the URL is still valid on sbcmirror.org |
| **xz decompression error** | Re-download the archive (may be corrupted) |

## Related Resources

- [Armbian Documentation](https://docs.armbian.com/)
- [Ethereum on ARM Documentation](https://ethereum-on-arm-documentation.readthedocs.io/)
- [Cloud Image Builder](../cloud/)
