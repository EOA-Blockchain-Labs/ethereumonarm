Download and Install
====================

.. grid:: 1 2 2 3
   :gutter: 2

   .. grid-item-card:: 1️⃣ Download
      :link: #image-downloads
      :link-type: ref
      :text-align: center
      :class-card: sd-border-primary
      
      📥
      
      Get the latest image for your board

   .. grid-item-card:: 2️⃣ Flash
      :link: #flashing-the-image
      :link-type: ref
      :text-align: center
      :class-card: sd-border-primary
      
      💾
      
      Write image to microSD card

   .. grid-item-card:: 3️⃣ Boot
      :link: #first-boot
      :link-type: ref
      :text-align: center
      :class-card: sd-border-primary
      
      🚀
      
      Power on and wait 10-15 min

Ethereum on ARM provides official support for the following Single Board Computers (SBCs):

.. list-table:: Supported Hardware
   :widths: 25 25 50
   :header-rows: 1

   * - Board
     - Minimum RAM
     - Notes
   * - **NanoPC T6**
     - 16 GB
     - Compact and powerful
   * - **Rock 5B**
     - 16 GB
     - Excellent performance
   * - **Orange Pi 5 Plus**
     - 16 GB (32 GB for Supernode)
     - Supernode requires 32GB RAM for higher resource demands
   * - **Raspberry Pi 5**
     - 16 GB
     - Widely available

Prerequisites
-------------

Before you begin, ensure you have the following components:

* **microSD Card**: For the operating system image.
* **NVMe SSD**: M.2 2280 NVMe SSD. A high-end or mid-range disk is recommended.
* **Ethernet Cable**: For a stable network connection.
* **Power Supply**: Official or high-quality power supply recommended for your specific board.

.. warning::
   Avoid NVMe disks with a **Phison controller** due to known Linux kernel compatibility issues.
   Check the `SSD Compatibility List <https://docs.google.com/spreadsheets/d/1B27_j9NDPU3cNlj2HKcrfpJKHkOf-Oi1DbuuQva2gT4/edit>`_ before purchasing.

Hardware Purchase
-----------------

NanoPC T6
~~~~~~~~~
* `NanoPC T6 board 16 GB`_

Rock 5B
~~~~~~~
* `Rock 5B board 16 GB`_
* `Acrylic protector with passive heatsink`_
* `Radxa power supply`_

Orange Pi 5 Plus
~~~~~~~~~~~~~~~~
* `Orange Pi 5 Plus 16 GB RAM`_
* `Orange Pi 5 Plus 32 GB RAM`_
* `Orange Pi 5 Plus Case with heatsink`_

Raspberry Pi 5
~~~~~~~~~~~~~~
* `Raspberry Pi 5 (16 GB RAM)`_
* **Geekworm** P579 case and X1001 NVMe Hat or **GeeekPi** case with N04 NVMe Hat.

.. _NanoPC T6 board 16 GB: https://www.friendlyelec.com/index.php?route=product/product&product_id=292
.. _Rock 5B board 16 GB: https://shop.allnetchina.cn/products/rock5-model-b?variant=39514839515238
.. _Acrylic protector with passive heatsink: https://shop.allnetchina.cn/products/rock5-b-acrylic-protector?variant=39877626396774
.. _Radxa power supply: https://shop.allnetchina.cn/products/radxa-power-pd-30w?variant=39929851904102
.. _Orange Pi 5 Plus 16 GB RAM: http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-5-plus.html
.. _Orange Pi 5 Plus 32 GB RAM: http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-5-plus-32GB.html
.. _Orange Pi 5 Plus Case with heatsink: https://aliexpress.com/item/1005005728553439.html
.. _Raspberry Pi 5 (16 GB RAM): https://www.raspberrypi.com/products/raspberry-pi-5/

Image Downloads
---------------

Download the image for your board. Each card includes the download link and SHA256 checksum for verification.

.. grid:: 2
   :gutter: 3

   .. grid-item-card:: 🖥️ NanoPC T6
      :class-header: sd-bg-primary sd-text-white
      
      :bdg-success:`16GB RAM` :bdg-info:`Compact`
      
      **Download**: |nanopct6_file|_  
      **SHA256**: |nanopct6_sha256|

   .. grid-item-card:: 🖥️ Rock 5B
      :class-header: sd-bg-primary sd-text-white
      
      :bdg-success:`16GB RAM` :bdg-info:`Excellent Performance`
      
      **Download**: |rock5b_file|_  
      **SHA256**: |rock5b_sha256|

   .. grid-item-card:: 🖥️ Orange Pi 5 Plus
      :class-header: sd-bg-primary sd-text-white
      
      :bdg-success:`16GB` :bdg-warning:`32GB for Supernode`
      
      **Download**: |orangepi5-plus_file|_  
      **SHA256**: |orangepi5-plus_sha256|

   .. grid-item-card:: 🖥️ Raspberry Pi 5
      :class-header: sd-bg-primary sd-text-white
      
      :bdg-success:`16GB RAM` :bdg-info:`Widely Available`
      
      **Download**: |rpi5_file|_  
      **SHA256**: |rpi5_sha256|

To verify the checksum in your terminal:

.. code-block:: bash

   sha256sum <image_file_name.zip>


Installation Guide
==================

Flashing the Image
------------------

.. tab-set::

   .. tab-item:: 🖱️ GUI Method (Recommended)
      
      **Using Balena Etcher** (Windows/Mac/Linux)
      
      1. **Insert the microSD card** into your computer
      2. **Download** `Balena Etcher <https://www.balena.io/etcher/>`_
      3. **Open Balena Etcher** and select:
         
         * Your downloaded image file
         * Your microSD card
         * Click "Flash!"

      .. tip::
         Balena Etcher automatically verifies the flash, so you don't need to manually check.

   .. tab-item:: 💻 Command Line
      
      **For Linux/Mac Users**
      
      1. **Insert the microSD card** into your computer
      
      2. **Identify your microSD device** (e.g., ``/dev/mmcblk0`` or ``/dev/sdX``):
      
         .. code-block:: bash
         
            # Linux
            sudo fdisk -l
            # Mac
            diskutil list
      
      3. **Unzip and flash** (example for NanoPC T6):
      
         .. code-block:: bash
         
            unzip ethonarm_nanopct6_|release|.img.zip
            sudo dd bs=1M if=ethonarm_nanopct6_|release|.img of=/dev/mmcblk0 conv=fdatasync status=progress
      
      .. warning::
         The ``dd`` command is destructive. Double-check your device name to avoid data loss.


First Boot
----------

1. Insert the **microSD card** into your board.
2. Ensure the **NVMe SSD** and **Ethernet cable** are connected.
3. Power on the board.

The system will boot up quickly, but the **initial setup script** will run in the background to configure the node. This process is fully automated and involves:

1.  **Internet Check**: Verifies connectivity (mandatory).
2.  **Disk Preparation**: Automatically formats the NVMe drive to ext4 (unless a previous installation is detected).
3.  **System Configuration**:
    *   Creates the ``ethereum`` user.
    *   Generates a unique hostname (e.g., ``ethereumonarm-rpi5-a1b2c3d4``).
    *   Optimizes kernel parameters (sysctl) for Ethereum performance.
    *   Configures swap space (2x RAM, max 64GB).
4.  **Software Installation**: Installs Execution and Consensus clients, monitoring tools, and utilities.
5.  **Security Hardening**: Locks the root account and removes default users.

.. warning::
   **Data Loss Warning**: If the script does not detect an existing Ethereum installation on the NVMe drive, **it will format the disk**. Ensure you have backed up any data on the NVMe drive before the first boot.

.. note::
   Please wait approximately **10-15 minutes** for the installation script to complete. The board **will reboot automatically** once finished. Do not interrupt the power supply.

Logging In
----------

Once the installation is complete, log in via SSH or a locally connected monitor/keyboard.

* **User**: ``ethereum``
* **Default Password**: ``ethereum``

.. warning::
   **Security Risk**: You MUST change the default password immediately upon first login. The system will prompt you to do so.

.. warning::
   **Firewall Disabled**: The system firewall (UFW) is **disabled by default** to prevent startup issues. If your node has a public IP, please refer to :doc:`../system/security` to enable and configure UFW immediately.

**Connecting via SSH:**

.. code-block:: bash

   ssh ethereum@<your_board_IP>

**Finding your IP Address:**

* **Router Admin Page**: Check your router's client list for a device named ``ethereum`` or similar.
* **Network Scan**: Use tools like ``nmap`` or ``fping``.

   .. code-block:: bash

      # Using nmap
      sudo nmap -sP 192.168.1.0/24

System Maintenance
==================

Update Ethereum Packages
------------------------

The system includes a convenient alias to update the Ethereum clients and tools. Run:

.. code-block:: bash

   update-ethereum

This command fetches the latest packages from the Ethereum on ARM repository and installs them.

Image Upgrade
-------------

To upgrade an existing Ethereum on ARM node to the new version without losing your chain data:

.. note::
   **How it works**: This process uses a script to backup your client configurations (`/etc/ethereum`) to a safe location on the NVMe drive (`/home/ethereum/.etc/ethereum`). When the new image boots, it detects this backup and restores your settings automatically.

1. **Back up your config** (Optional but highly recommended).
2. Install the sync tool on your **current** node:

   .. code-block:: bash

      sudo apt-get update && sudo apt-get install ethereumonarm-config-sync

3. Run the sync script:

   .. code-block:: bash

      ethereumonarm-config-sync.sh

4. **Flash the new image** to your microSD card (as described in "Flashing the Image").
5. Power on. The installer will detect the previous configuration backups and restore your `/etc/ethereum` client settings.

Re-installation (Wipe)
----------------------

To perform a clean install that **wipes all data** on the NVMe disk:

1. On your current node, run:

   .. code-block:: bash

      touch /home/ethereum/.format_me

   .. note::
      **Mechanism**: The startup script checks for this specific file on the NVMe drive during boot. If found, it forces the script to bypass the "preservation check" and triggers a full reformat of the partition, effectively wiping all data.

2. Reboot or power cycle. The startup script will detect this file and reformat the drive during the next boot process.

Troubleshooting
===============

* **LEDs not blinking?** Check your power supply voltage and cable connection.
* **No Network?** Ensure the Ethernet cable is plugged in *before* powering on.
* **Boot Loops?** Verify your power supply delivers sufficient amperage (PD 30W+ recommended for Rock 5B/NanoPC T6).
