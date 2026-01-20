# How to Add a New Project to Ethereum on ARM

This guide outlines the steps required to add a new software package (e.g., a new Client, Tool, or Service) to the Ethereum on ARM repository.

The process involves setting up the build environment, defining the package metadata, creating documentation, and registering the package for status tracking.

## 1. Directory Setup

Navigate to `fpm-package-builder` and choose the appropriate category for your project:

- **Layer 1 Consenus**: `l1-clients/consensus-layer/<project-name>`
- **Layer 1 Execution**: `l1-clients/execution-layer/<project-name>`
- **Layer 2**: `l2-clients/<project-name>` or `l2-clients/<ecosystem>/<project-name>`
- **Infrastructure**: `infra/<project-name>` or `infra/dvt/<project-name>`
- **Tools**: `tools/<project-name>`
- **Web3**: `web3/<project-name>`

Create the directory structure:

```bash
mkdir -p fpm-package-builder/<category>/<project-name>
cd fpm-package-builder/<category>/<project-name>
```

## 2. Package Build Configuration (Makefile)

The build process is controlled by a `Makefile`. The easiest way to start is to copy an existing `Makefile` from a similar project or use a template.

### Key Makefile Sections to Customize

- **Metadata**:

  ```makefile
  PKG_NAME        ?= my-new-project
  PKG_DESCRIPTION ?= Short description of the project
  WEB_URL         ?= https://github.com/org/repo
  ```

- **Upstream Source**:
  Define how to fetch the version and source code (tarball, binary, or source).

  ```makefile
  UPSTREAM_TAG_V := $(shell curl -s "https://api.github.com/repos/org/repo/releases/latest" | jq -r '.tag_name')
  ```

- **Build/Stage Steps**:
  Implement the `prepare` target to download and place files into `sources/usr/bin`, `sources/usr/lib`, etc.

### 2.1. Binary Verification (Mandatory)

All downloaded binaries **MUST** be verified against an upstream checksum (SHA256) or GPG signature.

#### Option A: SHA256 Verification (Recommended for GitHub Releases)

Use the GitHub API to fetch the SHA256 digest listed in the release assets (as seen in `grandine`).

```makefile
# Fetch digest from GitHub Release Asset "digest" field
UPSTREAM_SHA256 := $(shell curl -sL "https://api.github.com/repos/org/repo/releases/latest" | jq -r '.assets[] | select(.name == "$(BINARY_NAME)") | .digest' | sed 's/sha256://')

prepare:
 # ... download ...
 @echo "$(UPSTREAM_SHA256)  $(SOURCESDIR)/usr/bin/binary" | sha256sum -c - || { echo "❌ SHA256 FAILED!"; exit 1; };
```

#### Option B: GPG Verification (Higher Security)

If the upstream project provides a PGP signature (like `geth`), prefer this method.

```makefile
PGP_KEY_ID := 9BA28146

prepare:
 # Download binary and signature (.asc)
 wget -O binary url...
 wget -O binary.asc signature_url...
 
 @echo "🔐 Verifying GPG..."
 gpg --list-keys $(PGP_KEY_ID) >/dev/null 2>&1 || \
  gpg --keyserver keyserver.ubuntu.com --recv-keys $(PGP_KEY_ID)
 gpg --verify binary.asc binary || { echo "❌ GPG FAILED!"; exit 1; };
```

## 3. System Integration

If the package runs as a service (daemon), you need to provide a systemd service file.

1. Create an `extras` directory:

    ```bash
    mkdir extras
    ```

2. Add your service file (e.g., `my-project.service`) to `extras/`.
3. Ensure your `Makefile` includes the systemd flags (most templates already do):

    ```makefile
    $(shell test -d extras && find extras -name '*.service' | sed 's/^/--deb-systemd /')
    ```

### Post-Install Scripts (Optional)

If you need to run commands after installation (e.g., creating a user, setting permissions), add a `postinst` script in `extras/` and reference it in the `Makefile` with `--after-install extras/postinst`.

## 4. Documentation (RST & README.Debian)

We use **ReStructuredText (RST)** in the `docs/` directory as the source of truth. This documentation is automatically synced to the package's `README.Debian`.

1. **Create the RST file**:
    Create a new file in `docs/packages/<category>/<project-name>.rst`.
    Follow the standard format:
    - Introduction
    - Installation (via apt)
    - Configuration (locations of config files, systemd service names)
    - commands (how to check logs, restart service)

2. **Register for Sync**:
    Open `fpm-package-builder/build-scripts/sync_docs.sh`.
    Add a new mapping line to the `PACKAGE_MAPPINGS` array:

    ```bash
    "category/project.rst|path/to/your/project/sources/usr/share/doc/package-name/README.Debian"
    ```

    *Note: The second path is where the `README.Debian` will be generated inside your build directory.*

3. **Generate the README.Debian**:
    Run the sync script to generate the file:

    ```bash
    ./fpm-package-builder/build-scripts/sync_docs.sh --package <project-name>
    ```

## 5. Status Tracking

To have your package appear in the automated `STATUS.md` report, you must add it to the tracker.

1. Open `fpm-package-builder/build-scripts/packages.json`.
2. Add an entry under the appropriate category:

    ```json
    "org/repo": "package-name"
    ```

    - **Key**: The GitHub `owner/repo` string (used to query the GitHub API for the latest version).
    - **Value**: The package name in our repository (used to query our APT repo for the current version).

## 6. Public Listing

Finally, make sure the world knows about the new support!

1. Open the root `README.md`.
2. Add your project to the **Supported Software** tables.
    - Format: `| **Project Name** | [org/repo](https://github.com/org/repo) |`

## Checklist

- [ ] Directory created in `fpm-package-builder`
- [ ] `Makefile` builds `.deb` and `.rpm` created successfully
- [ ] Systemd service works (start/stop/restart)
- [ ] Documentation added to `docs/packages/`
- [ ] `sync_docs.sh` mapping added and run
- [ ] `packages.json` updated
- [ ] Root `README.md` updated
