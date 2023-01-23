.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Troubleshooting
===============

If you run into some issue with the image installation or running the Ethereum on ARM node, please **follow these 
steps** in order to solve the issue or get assistance.


EOA Check script
----------------

We developed a script that performs some tests regarding your node Hardware, System and Ethereum software config. If 
your node doesn't run properly, please run this script and check the output.

We will include it by default in the next images release. From now, you can install it by typing:

.. prompt:: bash $

  sudo apt-get update && sudo apt-get install ethereumonarm-utils

Usage is quite simple. type the following command in order to run all checks locally: 

.. prompt:: bash $

  sudo eoa_check

If you don't know what the report means or you have questions about it, you can send the log to a paste 
service in order to make it publicly available. Run:

.. prompt:: bash $

  sudo eoa_send

The command will return an URL which you can use to show others the report content.

Discord Channel
---------------

You can ask for help in our **Discord** channel. Paste the ``eoa_send`` content here if, as stated above, 
you don't know what the ``eoa_check`` output means. This is our channel:

`EOA Discord channel`_

.. _EOA Discord channel: https://discord.com/channels/822548812472123404

