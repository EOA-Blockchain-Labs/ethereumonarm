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

.. rubric:: Getting Further Assistance

Discord Channel
---------------

For personalized support, join the **Ethereum on ARM Discord** and share your |send_script| report link.

You can find us here:

`EOA Discord channel`_

.. _EOA Discord channel: http://discord.gg/ve2Z8fxz5N