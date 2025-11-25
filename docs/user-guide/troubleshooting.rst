.. Ethereum on ARM documentation master file
   Created by sphinx-quickstart on Wed Jan 13 19:04:18 2021.

.. |check_script| replace:: :command:`eoa_check`
.. |send_script| replace:: :command:`eoa_send`

Troubleshooting
===============

If you encounter issues during image installation or while running your Ethereum on ARM node, please **follow these steps** to identify and resolve the problem or to request assistance from the community.

EOA Check Script
----------------

The |check_script| utility provides a detailed diagnostic of your system and is designed to detect common issues encountered when deploying or running an Ethereum on ARM node.

It analyzes your device’s **hardware**, **network**, **system configuration**, and **Ethereum client status**, drawing on real-world cases frequently discussed in the EOA Discord community.

Its main goal is to simplify troubleshooting and help users quickly identify potential misconfigurations or resource limitations preventing their node from operating correctly.

Installation
~~~~~~~~~~~~

The script will be included by default in future image releases.  
For existing installations, it can be installed manually with:

.. code-block:: bash

   sudo apt-get update && sudo apt-get install ethereumonarm-utils

.. raw:: html

   <br>

What the Script Checks
~~~~~~~~~~~~~~~~~~~~~~

The |check_script| utility performs a comprehensive system diagnosis in **five key areas**:

* **Hardware:**  
  Checks total RAM (must be ≥ 8 GB), detects disk type (NVMe, SSD, or USB), displays CPU model, load average, and board temperature.

* **Network:**  
  Shows local and public IPs, verifies open ports (P2P ports **30303** and **9000**), and performs a download/upload speed test.

* **System:**  
  Displays OS and kernel information, firewall (UFW) and AppArmor status, pending updates, and installed Ethereum on ARM packages.

* **Ethereum Software:**  
  Detects active Execution Layer (EL) and Consensus Layer (CL) clients (including all testnet and MEV variants), verifies the presence of the **JWT secret file**, and ensures key communication ports (e.g. **8545**) are open.

* **Logs and Processes:**  
  Lists the largest log files and, if extended logging is enabled, displays the most CPU-intensive processes and the latest kernel (`dmesg`) and system (`syslog`) entries.

.. raw:: html

   <br>

Usage
~~~~~

To run all checks locally and generate a diagnostic report:

.. code-block:: bash

   sudo eoa_check -l

The script outputs a detailed summary on the console and saves a complete log to ``/var/log/eoa_check.log``.

If you are unsure how to interpret the output or wish to share it for assistance, you can automatically upload it to a public paste service using:

.. code-block:: bash

   sudo eoa_send

This command will return a URL that you can share to display your report.

Real Case Scenarios
-------------------

This section covers common maintenance scenarios.

Reflash SD Card
~~~~~~~~~~~~~~~

If you need to reflash your MicroSD card (e.g., for an OS upgrade or corruption fix), follow these steps.

**Before you begin:**

The system automatically runs a config sync daily to backup your ``/etc/ethereum`` directory to your NVMe drive (``/home/ethereum/.etc/ethereum``). However, it is **highly recommended** to run this manually before reflashing to ensure you have the very latest configurations backed up.

.. code-block:: bash

   sudo ethereumonarm-config-sync.sh

**Procedure:**

1.  **Power off** your board safely.
2.  **Remove** the MicroSD card.
3.  **Flash** the new image onto the MicroSD card using Etcher or ``dd``.
4.  **Insert** the card and **Power on**.

**Post-Installation:**

On the first boot, the system will detect the backup on your NVMe drive and automatically restore your ``/etc/ethereum`` configurations.

However, the system will **not** automatically restart your previous clients. You must manually re-enable the services you were using.

**Example (using Geth and Nimbus):**

.. code-block:: bash

   # Enable and start the Execution Layer client
   sudo systemctl enable --now geth

   # Enable and start the Consensus Layer client
   sudo systemctl enable --now nimbus-beacon

   # If you are running a validator:
   sudo systemctl enable --now nimbus-validator

Replace NVMe Drive
~~~~~~~~~~~~~~~~~~

On Ethereum on ARM, the NVMe drive is mounted directly at ``/home`` (specifically ``/dev/nvme0n1p1`` on ``/home``). This means replacing the drive involves significant data loss beyond just the blockchain data.

**What you will LOSE:**

*   **Prometheus Metrics:** Historical charts stored in ``/home/prometheus/metrics2`` will reset to zero.
*   **SSH Keys:** The ``/home/ethereum/.ssh`` folder. **Critical:** If you use keys to log in, backup this folder or you might lock yourself out.
*   **Personal Configs:** Files like ``.bash_aliases`` or ``.bashrc``. Any custom shortcuts you made are here.
*   **Validator/Wallet Info:** Even default installs have ``.ethereum/keystore`` and ``.nimbus-beacon/validators`` here. If you ever imported keys, they are gone.

**Procedure:**

1.  **Power off** the board and **replace** the NVMe drive.
2.  **Power on** the board.
3.  **Log in**. Since the system expects ``/home`` to be on the NVMe (which is now unformatted), the mount will fail. You will be logged into a temporary or fallback home directory on the SD card.
4.  **Create partition and format**:

    You need to create the partition and format it so it matches what ``fstab`` expects (partition 1, ext4).

    .. code-block:: bash

       # Create GPT label
       sudo parted /dev/nvme0n1 mklabel gpt

       # Create primary partition using 100% of the disk
       sudo parted -a opt /dev/nvme0n1 mkpart primary ext4 0% 100%

       # Format it to ext4
       sudo mkfs.ext4 /dev/nvme0n1p1

5.  **Reboot**:

    Now that ``/dev/nvme0n1p1`` exists and is formatted, the system will mount it automatically at ``/home`` upon reboot.

    .. code-block:: bash

       sudo reboot

**Result:**

The system will mount the new drive at ``/home``. Your clients will start automatically and begin **resyncing from scratch**.

.. rubric:: Getting Further Assistance

Discord Channel
---------------

For personalized support, join the **Ethereum on ARM Discord** and share your |send_script| report link.

You can find us here:

`EOA Discord channel`_

.. _EOA Discord channel: http://discord.gg/ve2Z8fxz5N