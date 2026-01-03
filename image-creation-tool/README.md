# Image Creation Tool

This directory contains the tooling to build custom **Ethereum on ARM** images based on Armbian.

## Overview

The build process downloads official Armbian minimal images, mounts them, injects the Ethereum on ARM first-boot scripts, and produces ready-to-flash `.img` files for supported devices.

## Supported Devices

| Device | Armbian Base | Notes |
| ------ | ------------ | ----- |
| **Raspberry Pi 5** | `rpi4b` | Uses RPi4 base image |
| **Rock 5B** | `rock-5b` | Vendor kernel 6.1.x |
| **Rock 5T** | `rock-5t` | Vendor kernel 6.1.x |
| **Orange Pi 5 Plus** | `orangepi5-plus` | Vendor kernel 6.1.x |
| **NanoPC T6** | `nanopct6-lts` | Vendor kernel 6.1.x |

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
cd ubuntu
make all
```

This downloads Armbian images for all supported devices, injects the first-boot scripts, and outputs final images.

### Build a Single Device

```bash
make build DEVICE=rock5b
```

Available devices: `rpi5`, `rock5b`, `rock5t`, `orangepi5-plus`, `nanopct6`

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

1. **Download**: Fetches the compressed Armbian minimal image from the official mirror.
2. **Decompress**: Extracts the `.img` file from the `.xz` archive.
3. **Mount**: Loop-mounts the root partition using the device-specific offset.
4. **Inject Scripts**: Copies the `ethereum-first-boot` script and systemd service.
5. **Cleanup**: Removes Armbian's interactive first-login prompts.
6. **Finalize**: Unmounts, renames to the final format, and generates checksums.

## Customization

### Adding a New Device

1. Find the Armbian minimal image URL from [sbcmirror.org](https://es.sbcmirror.org/).
2. Determine the root partition offset using `fdisk -l <image.img>`.
3. Add the device to the `Makefile`:

```makefile
# Add to DEVICES list
DEVICES = rpi5 rock5b rock5t orangepi5-plus nanopct6 newdevice

# Add device configuration
newdevice_url := https://es.sbcmirror.org/dl/newdevice/...
newdevice_iso := Armbian_XX.XX.X_Newdevice_noble_...img
newdevice_offset := <offset_in_bytes>
```

### Modifying First-Boot Scripts

Edit the scripts in `sources/`:

- `sources/usr/local/bin/ethereum-first-boot` - Main initialization script
- `sources/etc/systemd/system/ethereum-first-boot.service` - Systemd service
- `sources/usr/local/sbin/check_install` - Installation verification

## Troubleshooting

| Issue | Solution |
| ----- | -------- |
| **Mount failed** | Verify the partition offset with `fdisk -l` |
| **Permission denied** | Run with `sudo` or ensure you have sudo privileges |
| **Download failed** | Check the URL is still valid on sbcmirror.org |
| **xz decompression error** | Re-download the archive (may be corrupted) |

## Related Resources

- [Armbian Documentation](https://docs.armbian.com/)
- [Ethereum on ARM Docs](https://ethereum-on-arm-documentation.readthedocs.io/)
- [Package Builder](../fpm-package-builder/)
