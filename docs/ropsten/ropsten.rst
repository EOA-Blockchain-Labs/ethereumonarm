About Ropsten fork
==================

In preparation for the Merge, the **Ropsten** testnet will transition from POW to POS 
on 7th or 8th June 2022.

We are supporting the fork with :guilabel:`Geth` as Execution Layer client and 
:guilabel:`Lighthouse`, :guilabel:`Nimbus` and :guilabel:`Prysm` as Consensus Layer clients.

.. warning::
  
  Please check here the `recommended-hardware`_ as you need some requirements for the 
  installer to work such as an USB-SSD Disk.

.. _recommended-hardware: https://ethereum-on-arm-documentation.readthedocs.io/en/latest/quick-guide/recommended-hardware.html

Download and Install
====================

You will need the Kiln image in order to install the **Ropsten** clients:

Download the image here:

ethonarm_kiln_22.03.01.img.zip_

.. _ethonarm_kiln_22.03.01.img.zip: https://ethereumonarm-my.sharepoint.com/:u:/p/dlosada/ES56R_SuvaVFkiMO1Tgnf6kB7lEbBfla5c2c18E3WQRJzA?download=1

You can verify the file with the following ``SHA256`` Hash:

``485cf36128ca60a41b5de82b5fee3ee46b7c479d0fc5dfa5b9341764414c4c57``

By running:

.. prompt:: bash $

  sha256sum ethonarm_kiln_22.03.01.img.zip

Flash 
-----

Insert the microSD in your Desktop / Laptop and flash the image.

.. note::
  If you are not comfortable with the command line or if you are 
  running Windows, you can use Etcher_

.. _Etcher: https://www.balena.io/etcher/

Open a terminal and check your MicroSD device name running:

.. prompt:: bash $
fs 
   sudo fdisk -l

You should see a device named ``mmcblk0`` or ``sd(x)``.

.. warning::
  The ``dd`` command will completely erase your MicroSD device so make sure you are targeting 
  the correct one.

Unzip and flash the image:

.. prompt:: bash $

   unzip ethonarm_kiln_22.03.01.img.zip
   sudo dd bs=1M if=ethonarm_kiln_22.03.01.img of=/dev/mmcblk0 conv=fdatasync status=progress

Insert MicroSD
--------------

.. warning::
  The image will wipe out your USB SSD disk, so be careful if you already have data
  on it.

Insert de MicroSD into the Raspberry Pi 4. Connect an Ethernet cable and attach 
the USB SSD disk (make sure you are using a blue port that corresponds to USB 3).

Power on
--------

The Ubuntu OS will boot up in less than one minute and will start to perform the necessary tasks
to turn the device into a full Ethereum node.

.. warning::

  You need to wait for about 10-15 minutes to allow the script to install and configure all the software.

Log in
------

Once the device is available, You can log in through SSH or using the console (if you have a monitor 
and keyboard attached) using the ``ethereum`` account::

  User: ethereum
  Password: ethereum

Through SSH (if you are running the AWS image follow their instructions):

.. prompt:: bash $

  ssh ethereum@your_raspberrypi_IP

.. tip::
  If you don't have a monitor with a keyboard you can get your Raspberry Pi ``IP`` address by looking into your router 
  or using some kind of network tool such as ``fping`` or ``nmap``. For instance (assuming you are in the 192.168.1.0 network)).

  In your Linux Desktop / Laptop, run:

  Using Nmap

  .. prompt:: bash $
  
     sudo apt-get install nmap
     nmap -sP 192.168.1.0/24
  
  Using Fping

  .. prompt:: bash $

     sudo apt-get install fping
     fping -a -g 192.168.1.0/24
  
.. note::
  You will be **prompted to change the password on the first login**, so you will need to log in twice.

.. tip::

  Remember that you will need to forward/open the following ports for the clients to perform well:

  * **30303**: For the Execution Layer client (:guilabel:`Geth`)
  * **9000**: For Consensus Layer (:guilabel:`Lighthouse`, :guilabel:`Nimbus`)
  * **12000 (UDP) & 13000 (TCP)**: for Consensus Layer :guilabel:`Prysm`

What's included
===============

Ropsten configuration: **ropsten-config** package
Execution Layer: :guilabel:`Geth` clients
Consensus Layer clients: :guilabel:`Lighthouse`, :guilabel:`Nimbus` and :guilabel:`Prysm`

The image includes all Consensus Layer clients and Execution Layer binaries ready
to run through Systemd services and all necessary tools to make a deposit in the staking 
contract and generate the keys to enable a Validator.


Ropsten configuration
=====================

The **network configuration** depends upon ``ropsten-config`` package. It contains all necessary files to 
provide **info to the Execution and Consensus clients**.

The config files are located on ``/etc/ethereum/ropsten/merge-testnets/ropsten/``. This is a **Git repository** 
mantained by the EF core developers. If the repo gets an upgrade **you can update it** by running the following 
command:

.. prompt:: bash $

  sudo systemctl restart ropsten-config

All **EL and CL clients config files** are located on ``/etc/ethereum/ropsten`` as well as the ``jwtsecret`` file necessary for 
**EL and CL client communication**.

Quick start guide
=================

First step is to install the clients:

.. prompt:: bash $

  sudo apt-get update
  sudo apt-get install geth-ropsten lighthouse-ropsten prysm-ropsten nimbus-ropsten

Now start the ropsten-config repo. Run:

.. prompt:: bash $

  sudo systemctl start ropsten-config

.. warning::

  Please make sure you do run this command as it contains the network config.

As you need to run along **Execution Layer and Consensus Layer** we set up 
all **EL+CL combinations** as Systemd services for making it easy to start them.

For example, if you want to run :guilabel:`Geth` and :guilabel:`Lighthouse` Beacon 
Chain you need to start both services by running:

.. prompt:: bash $

  sudo systemctl start geth-lh 
  sudo systemctl start lh-geth-beacon 

These 2 commands will start the **Execution Layer and the Consensus Layer Beacon Chain**.

You can check both client logs by running:

.. prompt:: bash $
  sudo journalctl geth-lh -f
  sudo journalctl lh-geth-beacon -f

.. note::
  For :guilabel:`Lighthouse` and :guilabel:`Prysm` you will need to start an additional service 
  to run a Validator. We'll get to that in the `"Enabling a Validator"` section

So, this means that **we need 2 Systemd services for every EL+CL combination** (and 3 if you are 
running a validator with :guilabel:`Lighthouse` or :guilabel:`Prysm`).

For stopping a client, use the Systemctl stop directive, for instance:

.. prompt:: bash $

  sudo systemctl stop geth-lh

Once you choose which clients you want to run, check the following table in order 
to manage the correct services:

.. note::
  All config files are located in the **/etc/ethereum/ropsten** directory.

.. csv-table:: ROPSTEN SUPPORTED CLIENTS
  :header: Execution Layer, Consensus Layer, Services, Config Files

  Geth, Lighthouse, "| geth-lh
  | lh-geth-beacon
  | lh-geth-validator", "| geth-lh.conf
  | lh-geth-beacon.conf 
  | lh-geth-validator.conf"
  | Geth, Prysm, "| geth-pry
  | pry-geth-beacon
  | pry-geth-validator", "| geth-pry.conf
  | pry-geth-beacon.conf 
  | pry-geth-validator.conf"
  Geth, Nimbus, "| geth-nim
  | nim-geth", "| geth-nim.conf
  | nim-geth.conf"
  
.. note::
  Please note that the **Ropsten** network is a almost 6 years old testnet so it may take 
  several hours to sync. (The beacon chain is a new testnet so it would sync in 1 or 2 hours)


Enabling a Validator
====================

In order to stake and run a validator you will need:

  * An ETH address (you can create one easily with Metamask)
  * 32 ROPSTEN ETH (never send REAL ETH to this network)
  * An Execution Layer client
  * A Consensus Layer client consisting of:
    * A Beacon Chain
    * A/several Validator(s)

For making the 32 ETH deposit you need to create **2 key pairs** and a **Json file** with the 
necessary information to interact with the Eth2 Ropsten contract through a transaction.

The Ethereum Foundation provides a tool (**eth2.0-deposit-tool**) to create the keys and the 
deposit information (which among others contains your validator(s) public key(s)). This 
tool is already installed in your node.

Additionally, the Ethereum Foundation set up a **Launchpad** portal to make the staking process 
much more easy. Here you can upload the Json file and make the 32 ETH transaction 
with your wallet or a web3 wallet (we will use Metamask).

Preparation
-----------

The first step is to get some **Ropsten ETH** (fake ETH).

1. Create an address in **Metamask**.

2. Add Ropsten network to Metamask.

3. Go to the **public faucet** to get 32 ROPSTEN ETH:

`https://faucet.egorfine.com/`_

.. _https://faucet.egorfine.com/: https://faucet.egorfine.com/

Paste your ETH address, complete the captcha process and click **"Request funds"**.

Check your Metamask account. You should have now 32 KILN ETHs.

Keys generation and deposit
---------------------------

Visit the **EF Launchpad** website to start the process:

`https://ropsten.launchpad.ethereum.org/en/`_

.. _https://ropsten.launchpad.ethereum.org/en/: https://ropsten.launchpad.ethereum.org/en/

Follow these steps:

1. Click **"Become a validator"**.

2. Read carefully all the information and click **"Continue"** and **"I Accept"** in the following pages
until you reach the **"Confirmation"** screen. Click **"Continue"**. 
   
3. In the following screens you should choose an **Execution client** and a **Consensus client**. You can skip 
these instructions as all software is already included in the image and ready to run. Click **"Continue"** in 
both screens.

4. Now it is time to generate the key pairs. Select the number of validators you want to run in order to check 
the total ETH you will need. **skip the operating system and the key tool selection as we don't need it either**.

5. Go to your node and open a terminal in order to create the key pairs. Type the following command (as ethereum user):

.. prompt:: bash $

  cd && deposit new-mnemonic --num_validators 1 --chain ropsten

Choose your language and the mnemonic language. Create a password to secure the keystore (repeat the password 
for confirmation).

.. warning::

  Make sure you wrote down the nnemonic on a safe place.

Type again your mnemonic phrase to complete the process.

Now you have 2 json files under the ``/home/ethereum/validator_keys`` directory:

  * A deposit data file for making the **32 ETH transaction to the Ropsten contract**.
  * A keystore file with your **validator keys** that will be used by your **Consensus Client**.


6. Back to the Launchpad website, check **"I am keeping my keys safe and have written down 
my mnemonic phrase"**. Click **"Continue"**.

7. We need to upload the deposit file (located in your Ethereum node). You can, either copy and paste the 
file content and save it as a new json file in your desktop computer or copy the file 
from the Raspberry to your desktop through SSH.

.. tabs::

  .. tab:: Copy and Paste

     Connected through SSH to your Raspberry Pi, type:

     .. prompt:: bash $

        cat validator_keys/deposit_data-$FILE-ID.json (replace $FILE-ID with yours)

     Copy the content (the text in square brackets), go back to your desktop, paste it 
     into your favourite editor and save it as a json file.

  .. tab:: SCP (SSH remote copy)

     Pull the file from your desktop through SSH, copy the file:

     .. prompt:: bash $

        scp ethereum@$YOUR_RASPBERRYPI_IP:/home/ethereum/validator_keys/deposit_data-$FILE_ID.json /tmp

     Replace the variables (``$YOUR_RASPBERRYPI_IP`` and ``$FILE_ID``) with your data. 
     This command will copy the file to your desktop computer ``/tmp`` directory.

Once you have the file in your local desktop **click over "+"** and upload the deposit_data file.

8. Connect your **"Metamask"** wallet if it is not already connected.

9. Mark all checklists to confirm that you understand all warnings and click **"Continue"**.

10.  Finally, click **"Send deposit"** and **confirm the transaction**.

You will see your validator public key and the transaction status. In a few seconds the transaction will be 
confirmed. Now you will have to wait until you validator is enabled (the system takes some time to 
process all deposits).

**You can click the Beaconcha explorer (right below the Action menu) to get more information about your validator status**.

Click "Continue" to get a report of the staking process.

Congrats!, you just started your validator activation process.


Validator config
----------------

Let's enable 1 validator. Check the consensus Layer previously chosen as some config 
files and services depend on it (and again, make sure that EL+CL are in sync).

Clients give insightfull info about syncing status. Check the logs for errors and the last block number 
for both EL and CL (you can compare them with the ones displayed on the Ropsten explorer:

`https://beaconchain.ropsten.ethdevops.io/`_

.. _https://beaconchain.ropsten.ethdevops.io/: https://beaconchain.ropsten.ethdevops.io/

Lighthouse
~~~~~~~~~~

First, you need to check for the **Beacon Chain data directory**. For instance, if you started :guilabel:`Geth` with :guilabel:`Lighthouse`, 
the data directory will be ``/home/ethereum/.lh-geth/ropsten/testnet-lh``

Import the validator keys (we will suppose you've been running :guilabel:`Geth`):

.. prompt:: bash $

  lighthouse-rp account validator import --directory=/home/ethereum/validator_keys --datadir=/home/ethereum/.lh-geth/ropsten/testnet-lh

Type your keystore password.

Set the Suggested fee address:

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS/' /etc/ethereum/ropsten/lh-geth-validator.conf

Replace $YOUR_ETH_ADDRESS with your Metamask address.

Now, start the :guilabel:`Lighthouse` validator service (again, the example command assumes :guilabel:`Geth` as EL):

.. prompt:: bash $

  sudo systemctl start lh-geth-validator

Prysm
~~~~~

We need to import the validator keys. Run under the ethereum account. Assuming we are using :guilabel:`Geth` as Execution Layer:

.. prompt:: bash $

  validator-rp accounts import --keys-dir=/home/ethereum/validator_keys --wallet-dir /home/ethereum/.pry-geth/ropsten/testnet-pry
  
Accept the terms of service and create a password for a new wallet.

Enter your keystore password.

Store the walleta password:

.. prompt:: bash $

  echo "$YOUR_PASSWORD" > /home/ethereum/validator_keys/prysm-password.txt

Start the validator service

.. prompt:: bash $

  sudo systemctl start pry-geth-validator

Nimbus
~~~~~~

Again, you need to check the **Beacon Chain data directory** (depends on your 
CL+EL clients. For instance, assuming :guilabel:`Besu` as EL, let's import the keys into 
the :guilabel:`Nimbus` account:

.. prompt:: bash $

  nimbus_beacon_node-rp deposits import /home/ethereum/validator_keys --data-dir=/home/ethereum/.nim-besu/ropsten/testnet-nim

Type your keystore password and restart the validator process:

.. prompt:: bash $

  sudo systemctl restart .nim-besu

