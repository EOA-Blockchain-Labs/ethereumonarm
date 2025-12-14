.. _manual-binary-verification:

Manual Binary Verification Guide
================================

This guide explains how to verify the locally installed client binaries against upstream releases.

.. note::
   This guide assumes you are verifying the binaries installed by the ``ethereumonarm`` packages, typically located in ``/usr/bin/``.

Prerequisites
-------------

Ensure you have ``gnupg`` installed:

.. code-block:: bash

   sudo apt-get install gnupg

Method 1: Direct GPG Verification
---------------------------------

Some clients (like Prysm) publish detached PGP signatures for the raw binary. This allows you to verify the installed binary directly without downloading the full release again.

Prysm (Consensus)
~~~~~~~~~~~~~~~~~

1. **Import the Public Key** (Preston Van Loon):

   .. code-block:: bash

      gpg --keyserver keyserver.ubuntu.com --recv-keys 0AE0051D647BA3C1A917AF4072E33E4DF1A5036E

2. **Download the detached signature** for your installed version:

   .. code-block:: bash

      # Find version
      VERSION=$(beacon-chain --version | grep -oP 'v\d+\.\d+\.\d+' | head -1)

      # Download ONLY the signature
      wget "https://github.com/prysmaticlabs/prysm/releases/download/${VERSION}/beacon-chain-${VERSION}-linux-arm64.sig"
      wget "https://github.com/prysmaticlabs/prysm/releases/download/${VERSION}/validator-${VERSION}-linux-arm64.sig"

3. **Verify the installed binary**:

   .. code-block:: bash

      # Verify beacon-chain
      gpg --verify "beacon-chain-${VERSION}-linux-arm64.sig" /usr/bin/beacon-chain

      # Verify validator
      gpg --verify "validator-${VERSION}-linux-arm64.sig" /usr/bin/validator

   You should see ``Good signature from "Preston Van Loon..."``.

Method 2: SHA256 Hash Comparison
--------------------------------

For clients distributed as compressed archives (Lighthouse, Reth, Besu, Geth), the upstream PGP signature typically applies to the *archive*, not the binary itself. To verify these without downloading the full archive again, you can calculate the SHA256 hash of the installed binary and compare it with the official checksums provided in the release notes.

.. warning::
   Some projects only publish the hash of the *archive* (tar.gz/zip). In those cases, you cannot verify the installed binary hash against the release notes directly. You would need to download the archive to verify. The steps below assume valid binary hashes are available or known.

General Steps
~~~~~~~~~~~~~

1. **Calculate the hash** of your installed binary:

   .. code-block:: bash

      sha256sum /usr/bin/<client-executable>

2. **Check the Upstream Release Page**:
   Go to the official release page for the version you have installed.
3. **Compare**:
   Find the SHA256 checksum for the ``aarch64`` or ``arm64`` binary in the release notes or ``checksums.txt`` asset. Ensure it matches your output.

Client Specific URLs
~~~~~~~~~~~~~~~~~~~~

**Lighthouse**
   - **Check Version**: ``lighthouse --version``
   - **Releases**: `Sigma Prime Releases <https://github.com/sigp/lighthouse/releases>`_
   - *Note*: Lighthouse typically provides hashes for the ``.tar.gz`` archive.

**Reth**
   - **Check Version**: ``reth --version``
   - **Releases**: `ParadigmXYZ Reth Releases <https://github.com/paradigmxyz/reth/releases>`_

**Besu**
   - **Check Version**: ``besu --version``
   - **Releases**: `Hyperledger Besu Releases <https://github.com/hyperledger/besu/releases>`_
   - *Note*: Besu releases are typically ``.zip`` or ``.tar.gz``.

**Geth**
   - **Check Version**: ``geth version``
   - **Releases**: `Go-Ethereum Releases <https://geth.ethereum.org/downloads>`_
