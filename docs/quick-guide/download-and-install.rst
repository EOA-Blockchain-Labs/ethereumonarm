.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Download and Install The Image
==============================

Download
--------

Download the image here:

ubuntu-20.04.1-preinstalled-server-arm64_

.. _ubuntu-20.04.1-preinstalled-server-arm64: http://www.ethraspbian.com/downloads/ubuntu-20.04.1-preinstalled-server-arm64+raspi-eth2-medalla.img.zip 

You can verify the file with the following SHA256 Hash:

``SHA256 149cb9b020d1c49fcf75c00449c74c6f38364df1700534b5e87f970080597d87``

Flash 
-----

Insert the microSD in your Desktop / Laptop and download the file.

.. note::
  If you are not comfortable with command line or if you are 
  running Windows, you can use Etcher_

.. _Etcher: https://www.balena.io/etcher/

Open a terminal and check your MicroSD device name running:

.. prompt:: bash $

   sudo fdisk -l

You should see a device named mmcblk0 or sdd. Unzip and flash the image:

.. prompt:: bash $

   unzip ubuntu-20.04.1-preinstalled-server-arm64+raspi-eth2-medalla.img.zip
   sudo dd bs=1M if=ubuntu-20.04.1-preinstalled-server-arm64+raspi.img of=/dev/mmcblk0 conv=fdatasync status=progress

Insert MicroSD
--------------

Insert de MicroSD into the Raspberry Pi 4. Connect an Ethernet cable and attach 
the USB SSD disk (make sure you are using a blue port).

Power on
--------

The Ubuntu OS will boot up in less than one minute and will automatically perform the necessary tasks
to turn the device into a full Ethereum node.

.. warning::

  You will need to wait for about 8 to 10 minutes to allow the script to install and configure all the software.
