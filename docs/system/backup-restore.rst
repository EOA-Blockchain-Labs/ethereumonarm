.. Ethereum on ARM Backup Utility (Restic Edition)
   SPDX-License-Identifier: MIT

##############################################
Ethereum on ARM Secure Backup Utility (Restic)
##############################################

The ``ethereumonarm-utils`` package provides an automated, **encrypted, incremental backup system** for Ethereum nodes.

It integrates `Restic <https://restic.net/>`_ (for encryption, deduplication, and versioning) with `Rclone <https://rclone.org/>`_ (for cloud storage support) to create a lightweight, verifiable, and resource-efficient backup solution.

The backup runs automatically through a ``systemd`` timer, minimizing I/O and user maintenance.

.. contents:: Table of Contents
   :local:

Installation
============

To install the package from the official Ethereum on ARM repository:

.. code-block:: bash

   sudo apt update
   sudo apt install ethereumonarm-utils

The installation process will:

1. Place the main backup script at ``/usr/sbin/eoa_restic_backup``.
2. Install the default configuration file at ``/etc/ethereum/restic_eoa.conf``.
3. Create and register the ``ethereum-backup.service`` and ``ethereum-backup.timer`` units for automated execution.

Configuration
=============

Before using the backup system, you must configure **Rclone** (to access cloud storage) and **Restic** (for encryption and deduplication).

Step 1: Configure Rclone Remote
-------------------------------

``Rclone`` provides access to cloud backends such as Google Drive, Dropbox, or S3.

Follow the official setup instructions:

* `Rclone Documentation <https://rclone.org/>`_
* `Configure Remotes <https://rclone.org/docs/#configure>`_
* `Google Drive Example <https://rclone.org/drive/>`_

Once you have created your remote, verify it with:

.. code-block:: bash

   rclone listremotes

You will use the remote name in the next step.

Step 2: Configure Restic Repository
-----------------------------------

After setting up Rclone, edit the main configuration file:

.. code-block:: bash

   sudo vim /etc/ethereum/restic_eoa.conf

Example configuration:

.. code-block:: ini

   ######################################
   # Ethereum on ARM Restic Backup Config
   ######################################

   # Name of the Rclone remote (from `rclone listremotes`)
   RCLONE_REMOTE=mydrive-crypt

   # Location of the Restic repository (via Rclone)
   RESTIC_REPOSITORY=rclone:mydrive-crypt:/ethereumonarm-backups

   # File containing the Restic encryption password
   RESTIC_PASSWORD_FILE=/etc/ethereum/restic.passwd

   # Directories to back up (one per line)
   SOURCE_FOLDERS=
   /etc/ethereum
   /home/ethereum/.charon

Create the password file used to encrypt your repository:

.. code-block:: bash

   sudo sh -c 'echo "YourStrongResticPassword" > /etc/ethereum/restic.passwd'
   sudo chmod 600 /etc/ethereum/restic.passwd

.. note::
   Keep a secure copy of this password offline. Without it, **your backups cannot be restored**.

Step 3: Initialize Restic Repository
------------------------------------

Initialize the encrypted Restic repository (this must be done once):

.. code-block:: bash

   sudo -E restic init

Expected output:

.. code-block:: none

   created restic repository 3ef5f6a3 at rclone:mydrive-crypt:/ethereumonarm-backups

Enabling Automatic Backups
==========================

Once configuration is complete, enable the daily backup timer:

.. code-block:: bash

   sudo systemctl enable --now ethereum-backup.timer

To verify scheduling:

.. code-block:: bash

   systemctl list-timers | grep ethereum-backup

Usage and Management
====================

Manual Backup
-------------

You can trigger an immediate backup at any time:

.. code-block:: bash

   sudo systemctl start ethereum-backup.service

Viewing Logs
------------

All backup activity (including Restic and Rclone output) is logged to the ``systemd`` journal:

.. code-block:: bash

   journalctl -u ethereum-backup.service -f

Backup Script Logic
===================

The script automatically performs the following steps:

1. Verifies or initializes the Restic repository.
2. Backs up all directories listed in ``SOURCE_FOLDERS``.
3. Applies retention policy (7 daily, 4 weekly, 6 monthly).
4. Logs results to ``systemd-journal`` for review.

Simplified Logic Example
------------------------

.. code-block:: bash

   #!/bin/bash
   set -euo pipefail
   source /etc/ethereum/restic_eoa.conf

   export RESTIC_REPOSITORY="$RESTIC_REPOSITORY"
   export RESTIC_PASSWORD_FILE="$RESTIC_PASSWORD_FILE"

   log() { echo "[EOA Backup] $*" | systemd-cat -t ethereum-backup; }

   log "Starting Ethereum on ARM backup..."

   if ! restic snapshots > /dev/null 2>&1; then
       log "Initializing Restic repository..."
       restic init
   fi

   if restic backup ${SOURCE_FOLDERS} --host "$(hostname)" --tag "ethereumonarm"; then
       log "Backup completed successfully."
   else
       log "ERROR: Restic backup failed."
       exit 1
   fi

   restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
   log "Old snapshots pruned. Backup finished."

Managing Snapshots
==================

List all snapshots
------------------

.. code-block:: bash

   restic snapshots

Forget and prune old snapshots
------------------------------

.. code-block:: bash

   restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune

Check repository integrity
--------------------------

.. code-block:: bash

   restic check

Restore files or directories
----------------------------

Restore the latest snapshot:

.. code-block:: bash

   sudo restic restore latest --target /tmp/restore

Restore specific directories:

.. code-block:: bash

   sudo restic restore latest --include /etc/ethereum --target /tmp/recovery


Security and Resource Recommendations
=====================================

==========================  ===============================================  =====================
Setting                     Purpose                                          Recommended
==========================  ===============================================  =====================
**Encrypted Rclone Remote** Adds an extra layer of encryption                ✅ Yes
**Password File Permissions** Protect password secrecy                       ``chmod 600``
**Exclude Blockchain Data** Avoid huge backups of chain DB                   ✅ Yes
**Systemd Timer**           Safe for unattended Armbian nodes                ✅ Yes
**Upload Throttling**       Avoid bandwidth saturation                       ``--limit-upload 1M``
**Disable Compression**     Reduce CPU load on SBC                           ``--no-compress``
==========================  ===============================================  =====================

Troubleshooting
===============

===============================  =======================================  ===================================
Problem                          Likely Cause                             Solution
===============================  =======================================  ===================================
``repository master key not found`` Incorrect password file               Check ``/etc/ethereum/restic.passwd``
``rclone not configured``        Missing remote                           Run ``rclone config``
``Permission denied``            Wrong ownership or permissions           Use ``root:root`` and mode ``600``
``Upload too slow``              Limited bandwidth                        Add ``--limit-upload 1M``
``Out of memory``                Small SBC RAM                            Limit number of source folders
===============================  =======================================  ===================================

Summary
=======

This Restic-based backup system provides:

* 🔐 **End-to-end encryption**
* 🧠 **Incremental and deduplicated backups**
* 🧱 **Automatic versioning and retention**
* 💾 **Minimal disk wear and I/O**
* ☁️ **Cloud-agnostic storage (via Rclone)**
* ⚙️ **Seamless integration with ``systemd``**

Essential Ethereum node data — configurations, validator keys, and service settings — are now **securely encrypted, versioned, and verifiable**, ensuring rapid recovery in case of hardware failure or SD corruption.