.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Storage
=======

**You need at least 1 TB SSD** in order to sync the Ethereum 1.0 blockchain. Again, there is no chance of 
syncing the blockchain with an HDD disk.

Raspberry Pi 4
--------------

You will need an SSD to run an Ethereum node 
(without an SSD drive there’s absolutely no chance 
of syncing the Ethereum blockchain). There are 2 options:

  * Use an USB portable SSD disk such as the Samsung Portable T5/T7 SSDs.
  * Use an USB 3.0 External Hard Drive Case with a SSD Disk. 
    In our case we used a Inateck 2.5 Hard Drive Enclosure FE2011. 
    Make sure to buy a case with an UASP (USB Attached SCSI) compliant chip, particularly, one of these: 

    * JMicron JMS567
    * JMicron JMS578
    * ASMedia (ASM1153E).

In all cases, avoid getting low quality SSD disks as it is a key component of your node 
and it can drastically affect the node performance (and sync times). 
Keep in mind that you need to plug the disk to an USB 3.0 port (in blue).

.. warning::
  Take into account that, even with a curated hardware list, there is a chance of getting into
  issues.
