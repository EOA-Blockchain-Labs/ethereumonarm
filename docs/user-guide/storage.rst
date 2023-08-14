.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Storage
=======

**You need at least 2 TB SSD** in order to run a Full Ethereum node. Again, there is no chance of 
syncing the blockchain with an HDD disk.

NanoPC T4, Rock 5B and Orange Pi 5 plus
---------------------------------------

These boards includes 4x M.2 2280 NVMe disk support.

Orange Pi 5
-----------

This board includes 1x M.2 2245 NVMe disk support.

Raspberry Pi 4
--------------

You will need an SSD to run an Ethereum node 
(without an SSD drive there's absolutely no chance 
of syncing the Ethereum blockchain). There are 2 options:

  * Use an USB portable SSD disk such as the Samsung Portable T5 SSDs.
  * Use an USB 3.0 External Hard Drive Case with a SSD Disk. 
    In our case we used a **Startech SATA to USB Cable**. 
    Make sure to buy a case with an UASP (USB Attached SCSI) compliant chip, particularly, one of these: 

    * JMicron JMS567
    * JMicron JMS578
    * ASMedia (ASM1153E).

.. tip::
  We strongly recommend **Startech SATA to USB Cable** if you are using a UASP bridge:

  .. _Startech: https://www.startech.com/en-us/hdd/usb3s2sat3cb

In all cases, avoid getting low quality SSD disks as it is a key component of your node 
and it can drastically affect the node performance (and sync times). 
Keep in mind that you need to plug the disk to an USB 3.0 port (in blue).

.. warning::
  Remember that the Raspberry Pi 4 can barely run a node after The Merge. Choose a board from the 
  above list if possible.

