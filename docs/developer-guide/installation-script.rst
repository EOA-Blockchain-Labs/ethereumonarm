.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Installation Script
===================

The installation script is located at ``/etc/rc.local``. It just run once and 
performs all necessary tasks to turn the devices into full Ethereum node.

It is included on an Ubuntu Server image file.

Hostname
--------

The first step is to change the hostname:

.. prompt:: bash $

  MAC_HASH=`cat /sys/class/net/eth0/address | sha256sum | awk '{print substr($0,0,9)}'`
  echo ethereumonarm-$MAC_HASH > /etc/hostname
  sed -i "s/127.0.0.1.*/127.0.0.1\tethereumonarm-$MAC_HASH/g" /etc/hosts

This changes the hostname to something like *ethereumonarm-d853a4cec*. The hex part
comes from a MAC hash chunk.

Disk Setup
----------

The scripts formats the USB disk and mount it as home in the next reboot.

.. warning::

  The script will wipe out your disk, so be careful and make sure there is no important 
  data on it.

.. prompt:: bash $

  if stat  /dev/sda > /dev/null 2>&1;
  then
    echo USB drive found
    echo Partitioning and formatting USB Drive...
    wipefs -a /dev/sda
    sgdisk -n 0:0:0 /dev/sda

    mkfs.ext4 -F /dev/sda1
    echo '/dev/sda1 /home ext4 defaults 0 2' >> /etc/fstab && mount /home
  else
    echo no SDD detected
  fi 

If a ``sda`` disk is detected it is partitioned and formated with an Ext4 FS.


Ethereum Account
----------------

The ``ethereum`` user account is created. This is important as it is the user that will run 
all Ethereum software and write to the SSD disk.

.. prompt:: bash $

  echo "Creating ethereum  user"
  if ! id -u ethereum >/dev/null 2>&1; then
    adduser --disabled-password --gecos "" ethereum
  fi

  echo "ethereum:ethereum" | chpasswd
  for GRP in sudo netdev audio video dialout plugdev; do
    adduser ethereum $GRP
  done

  # Force password change on first login
  chage -d 0 ethereum

The last command will force the user to change the default password (``ethereum``) on the 
first log in.

RAM and SWAP Configuration
==========================



Disk Setup
==========

User Account
============




