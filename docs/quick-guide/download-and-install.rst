.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Download and Install
====================

Download
--------

Download the image here:

ubuntu-20.04.1-preinstalled-server-arm64_

.. _ubuntu-20.04.1-preinstalled-server-arm64: http://www.ethraspbian.com/downloads/ubuntu-20.04.1-preinstalled-server-arm64+raspi-eth2-medalla.img.zip 

You can verify the file with the following ``SHA256`` Hash:

``SHA256 149cb9b020d1c49fcf75c00449c74c6f38364df1700534b5e87f970080597d87``

By running:

.. prompt:: bash $

  md5sum image

Flash 
-----

Insert the microSD in your Desktop / Laptop and flash the image.

.. note::
  If you are not comfortable with command line or if you are 
  running Windows, you can use Etcher_

.. _Etcher: https://www.balena.io/etcher/

Open a terminal and check your MicroSD device name running:

.. prompt:: bash $

   sudo fdisk -l

You should see a device named ``mmcblk0`` or ``sd(x)``.

.. warning::
  The ``dd`` command will completely erase your device so make sure you are targeting 
  the correct one.

Unzip and flash the image:

.. prompt:: bash $

   unzip ubuntu-20.04.1-preinstalled-server-arm64+raspi-eth2-medalla.img.zip
   sudo dd bs=1M if=ubuntu-20.04.1-preinstalled-server-arm64+raspi.img of=/dev/mmcblk0 conv=fdatasync status=progress

Insert MicroSD
--------------

.. warning::
  The image will wipe out your USB disk, so be careful if you already have data
  on it.

Insert de MicroSD into the Raspberry Pi 4. Connect an Ethernet cable and attach 
the USB SSD disk (make sure you are using a blue port).

Power on
--------

The Ubuntu OS will boot up in less than one minute and will start to perform the necessary tasks
to turn the device into a full Ethereum node.

.. warning::

  You will need to wait for about 5 minutes to allow the script to install and configure all the software.

Log in
------

Once the device is available, You can log in through SSH or using the console 
(if you have a monitor and keyboard attached)::

  User: ethereum
  Password: ethereum

Through SSH:

.. prompt:: bash $

  ssh ethereum@your_raspberrypi_IP

.. tip::
  If you don't have a monitor with a keyboard you can get your Raspberry Pi ``IP`` address by looking into your router 
  or using some kind of network tool such as ``fping`` or ``nmap``. For instance (assuming you are in the 192.168.1.0 network)):

  With Nmap

  .. prompt:: bash $
  
     sudo apt-get install nmap
     nmap -sP 192.168.1.0/24
  
  With Fping

  .. prompt:: bash $

     sudo apt-get install fping
     fping -a -g 192.168.1.0/24
  
.. note::
  You will be prompted to change the password on first login, so you will need to log in twice.
