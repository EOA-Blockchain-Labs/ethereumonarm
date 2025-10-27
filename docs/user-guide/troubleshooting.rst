.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

.. |check_script| replace:: :command:`eoa_check`
.. |send_script| replace:: :command:`eoa_send`

Troubleshooting
===============

If you run into some issue with the image installation or running the Ethereum on ARM node, please **follow these
steps** in order to solve the issue or get assistance.

EOA Check script
----------------

This script is designed to check for common issues that users may encounter when trying to install
and run their first Ethereum on ARM node. It checks for various system information such as hardware,
software, and service status and looks for the usual problems that users may face based on the shared
experiences in the Discord community.

The script's purpose is to help users troubleshooting info and identify any potential issues that may be
preventing the Ethereum on ARM node from running properly.

We will include it by default in the next images release. From now, you can install it by typing:

.. code-block:: bash

  sudo apt-get update && sudo apt-get install ethereumonarm-utils

.. raw:: html

   <br>

**What the script checks:**

The |check_script| utility performs a comprehensive system diagnosis in the following five key areas:

* **Hardware:** Checks RAM adequacy (e.g., must be $\geq 8 \text{ GB}$), disk type (looking for NVMe/SSD), CPU load, and temperature.
* **Network:** Verifies local/public IP configuration, checks if the essential P2P ports **30303** and **9000** are open, and runs an internet speed test.
* **System:** Examines the OS, kernel, firewall (UFW) status, pending system updates, and lists relevant EOA packages.
* **Ethereum Software:** Detects active Execution Layer (EL) and Consensus Layer (CL) clients, verifies the presence of the crucial **JWT secret file**, and confirms local communication ports (like **8545**) are open.
* **Logs:** Lists the largest log files and, optionally, shows detailed system and kernel logs.

.. raw:: html

   <br>

Usage is quite simple. Type the following command in order to run all checks locally:

.. code-block:: bash

  sudo eoa_check -l

If you don't know what the report means or you have questions about it, you can send the log to a paste
service in order to make it publicly available. Run:

.. code-block:: bash

  sudo eoa_send

The command will return an URL which you can use to show others the report content.

.. rubric:: Getting Further Assistance

Discord Channel
---------------

You can ask for help in our **Discord** channel. Paste the |send_script| content URL here if, as stated above,
you don't know what the |check_script| output means. This is our channel:

`EOA Discord channel`_

.. _EOA Discord channel: http://discord.gg/ve2Z8fxz5N