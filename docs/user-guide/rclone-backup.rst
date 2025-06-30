.. ethereumonarm-utils backup documentation file

######################################
Ethereum on ARM Backup Utility Guide
######################################

The ``ethereumonarm-utils`` package provides an automated solution for backing up critical Ethereum node data to a cloud storage provider using `rclone <https://rclone.org/>`_. It is managed by a ``systemd`` timer for reliable daily execution.

.. contents:: Table of Contents
   :local:

Installation
============

To install the package from the repository, use ``apt`` with root privileges:

.. code-block:: bash

   sudo apt update
   sudo apt install ethereumonarm-utils

The installation process will:

1.  Place the main script at ``/usr/sbin/eoa_rclone``.
2.  Create a default configuration file at ``/etc/ethereum/rclone_eoa.conf``.
3.  Install a ``systemd`` service and timer for the backup job.

Configuration
=============

After installation, you **must** complete the following steps before the backup can run.

Step 1: Configure an rclone Remote
-----------------------------------

The backup script requires at least one `rclone remote <https://rclone.org/remote_setup/>`_ to be configured. A remote is a connection to a cloud storage provider like Google Drive, Dropbox, or an S3 bucket.

For security, it is **highly recommended** to use an `encrypted remote <https://rclone.org/crypt/>`_. This ensures that the data stored in the cloud is unreadable without your password.

**To configure your remotes, follow the official rclone documentation:**

* **Main Documentation:** `rclone.org <https://rclone.org/>`_
* **Setup Instructions:** `Configuring rclone Remotes <https://rclone.org/docs/#configure>`_
* **Google Drive Example:** `rclone Google Drive Setup <https://rclone.org/drive/>`_

Once you have configured a remote, you can see its name by running:

.. code-block:: bash

   rclone listremotes

Step 2: Edit the Configuration File
-----------------------------------

Open the configuration file with a text editor:

.. code-block:: bash

   sudo nano /etc/ethereum/rclone_eoa.conf

You need to edit two sections:

1.  **`CLOUD_REMOTE_NAME`**: Change ``your-encrypted-remote`` to the exact name of the rclone remote you want to use (from the ``rclone listremotes`` command).

    .. code-block:: ini

       CLOUD_REMOTE_NAME=my-gdrive-crypt

2.  **`SOURCE_FOLDERS`**: Under the ``SOURCE_FOLDERS=`` marker, add the full paths of all the directories you wish to back up. Each directory must be on its own line.

    .. code-block:: ini

       SOURCE_FOLDERS=
       /etc/ethereum
       /home/ethereum/.charon


    The list of source folders is completely customizable. You can add any directory you wish to include in the backup. The ``/home/ethereum/.charon`` path, for example, is only necessary if you are running a Distributed Validator with an Obol Charon cluster.

Save and close the file.

Step 3: Enable the Backup Timer
-------------------------------

Once you are satisfied with your configuration, you must manually enable the ``systemd`` timer. This will schedule the backup to run daily and ensure it starts automatically on boot.

.. code-block:: bash

   sudo systemctl enable --now ethereum-backup.timer

The ``--now`` flag starts the timer immediately. The first backup will run shortly after, according to the randomized delay.

Usage and Management
====================

The backup is designed to run automatically. Here’s how to manage and monitor it.

Checking the Timer Status
-------------------------

To see when the next backup is scheduled to run, use:

.. code-block:: bash

   systemctl list-timers

Look for the ``ethereum-backup.timer`` entry in the output.

Viewing Logs
------------

All output from the backup script (including progress, warnings, and errors) is sent to the ``systemd`` journal. To view the logs for the backup service, run:

.. code-block:: bash

   journalctl -u ethereum-backup.service

To follow the logs in real-time (for example, during a manual run), use the ``-f`` flag:

.. code-block:: bash

   journalctl -f -u ethereum-backup.service

Running a Manual Backup
-----------------------

If you need to trigger a backup immediately instead of waiting for the timer, you can start the service directly:

.. code-block:: bash

   sudo systemctl start ethereum-backup.service

You can then monitor its progress using the ``journalctl`` command above.
