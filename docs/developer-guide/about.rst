.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

About Developer Guide
======================

The Ethereum on ARM image is an Ubuntu server OS for the Raspberry Pi that includes a boot script which performs all necessary tasks to turn the device into a full Ethereum 1 / Ethereum 2 node (or both).

The installation script, located at /etc/rc.local, runs only once, sets up the system (including external disks and the user account) and installs all the Ethereum related software.

This is a guide of the image creation process and all the tasks and packages related to it as well as the tools and scripts used to release the EOA image.
