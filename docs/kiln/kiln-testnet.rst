About Kiln Raspberry Pi 4 image
===============================

The Kiln network is a public testnet for the upcoming Ethereum upgrade 
to Proof of Stake called **The Merge**. It will be (most probably) the last 
public testnet before **The merge**.

This is a **Plug and Play** image for the **Raspberry Pi 4** that sets up and 
installs all the software necessary to test Execution Layer and Consensus Layer clients 
just **by starting their Systemd services**.

Please check here the `recommended-hardware`_ section before installing the image:

.. _recommended-hardware: https://ethereum-on-arm-documentation.readthedocs.io/en/latest/quick-guide/recommended-hardware.html

Amazon ARM AWS AMI Image
========================

If you don't have a Raspberry Pi 4 but you have an **AWS account** (or you are willing to open one), 
we've built a public **ARM AMI image** so you can run a **Kiln Ethereum node and try the testnet**.

.. warning::
  The image only works with an ARM64 architecture.

This AMI **contains exactly the same software and configuration that the Raspberry Pi 4** one so the 
instructions are the same for both except from the installation process (Flashing the MicroSD for 
the Raspberry and launching the AMI from the AWS console).

.. tip::

  As these images are intended only for testing, we recommend picking up an **AWS spot instance** to 
  cut some costs (prices are up to 90% lower than the On-Demand one). See more info here:

  `AWS spot instances`_

.. _AWS spot instances: https://aws.amazon.com/ec2/spot/

.. note::
  Remember to open the necessary ports in order to make sure all clients work properly:

  * **30303**: For Execution Layer clients (:guilabel:`Geth`, :guilabel:`Besu` and :guilabel:`Nethermind`)
  * **9000**: For Consensus Layer (:guilabel:`Lighthouse`, :guilabel:`Nimbus` and :guilabel:`Teku`)
  * **12000 (UDP) & 13000 (TCP)**: for Consensus Layer :guilabel:`Prysm`
  * **3000**: For Grafana dashboards

You can find the AMI here:

`ami-0eac5fc607c257931`_

.. _ami-0eac5fc607c257931: https://eu-west-1.console.aws.amazon.com/ec2/v2/home?region=eu-west-1#ImageDetails:imageId=ami-0eac5fc607c257931

Download and Install
====================

.. note::

  Please, check the requirements for run an Ethereum on ARM Raspberry Pi image:

  `recommended-hardware`

  https://ethereum-on-arm-documentation.readthedocs.io/en/latest/quick-guide/recommended-hardware.html

Download the image here:

ethonarm_kiln_22.01.00.img.zip_

.. _ethonarm_kiln_22.01.00.img.zip: https://www.ethereumonarm.com/downloads/ethonarm_kiln_22.01.00.img

You can verify the file with the following ``SHA256`` Hash:

``SHA256 b80cfba7b42d141bf2e416f53a1c29863d67d470b1bcc1a14f54e41a5ddeb423``

By running:

.. prompt:: bash $

  sha256sum ethonarm_kiln_22.01.00.img.zip

Flash 
-----
,
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

   unzip ethonarm_kiln_22.01.00.img.zip
   sudo dd bs=1M if=ethonarm_kiln_22.01.00.img of=/dev/mmcblk0 conv=fdatasync status=progress

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

  * **30303**: For Execution Layer clients (:guilabel:`Geth`, :guilabel:`Besu` and :guilabel:`Nethermind`)
  * **9000**: For Consensus Layer (:guilabel:`Lighthouse`, :guilabel:`Nimbus` and :guilabel:`Teku`)
  * **12000 (UDP) & 13000 (TCP)**: for Consensus Layer :guilabel:`Prysm`
  * **3000**: For Grafana dashboards if you want to access from the outside

What's included
===============

As you may know, Eth1 clients are renamed to **Execution Layer** clients and 
Eth2 clients are renamed to **Consensus Layer** clients and **we need to run 
both at the same time** (EL+CL) so they can work together.

The image includes all Consensus Layer clients and Execution Layer binaries ready
to run and all necessary tools to make the deposit and generate the keys to enable 
a Validator.

This is the software included:

.. csv-table:: Kiln Supported Clients
   :header: Execution Layer, Consensus Layer

   `Geth`, `Lighthouse`
   `Nethermind`, `Prysm`
   `Besu`,`Nimbus`
   ` `, `Teku`

Kiln tools

    * **eth2-val-tools** 
    * **ethereal** 


Managing the clients
====================

As you need to run both **Execution Layer and Consensus Layer at once** we set up 
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
  to run a Validator. We'll get to that in the `"Validator config"` section

So, this means that **we need a Systemd service for every EL+CL combination**.

For stopping a client, use the Systemctl stop directive, for instance:

.. prompt:: bash $

  sudo systemctl stop geth-lh

Once you choose which clients you want to run, check the following table in order 
to manage the correct services:

.. note::
  All config files are located in the **/etc/ethereum/kiln** directory.

.. csv-table:: KINTSUGI SUPPORTED CLIENTS
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
  Geth, Teku, "| geth-teku
  | teku-geth", "| geth-teku.conf
  | teku-geth.conf"
  Nethermind, Lighthouse, "| neth-lh
  | lh-neth-beacon
  | lh-neth-validator","| neth-lh.conf
  | lh-neth-beacon.conf 
  | lh-neth-validator.conf"
  Nethermind, Prysm, "| neth-pry
  | pry-neth-beacon
  | pry-neth-validator", "| neth-pry.conf
  | pry-neth-beacon.conf 
  | pry-neth-validator.conf"
  Nethermind, Nimbus, "| neth-nim
  | nim-neth", "| neth-nim.conf
  | nim-neth.conf"
  Nethermind, Teku, "| neth-teku
  | teku-neth", "| neth-teku.conf
  | teku-neth.conf"
  Besu, Lighthouse, "| besu-lh
  | lh-besu-beacon
  | lh-besu-validator", "| besu-lh.conf
  | lh-besu-beacon.conf 
  | lh-besu-validator.conf"
  Besu, Prysm, "| besu-pry
  | pry-besu-beacon
  | pry-besu-validator", "| besu-pry.conf
  | pry-besu-beacon.conf 
  | pry-besu-validator.conf"
  Besu, Nimbus, "| besu-nim
  | nim-besu", "| besu-nim.conf
  | nim-besu.conf"
  Besu, Teku, "| besu-teku
  | teku-besu", "| besu-teku.conf
  | teku-besu.conf"
  

.. note::
  :guilabel:`Besu` needs a little set up before starting it:
  Edit the config file (depending on the CL, for example: 
  ``/etc/ethereum/kiln/besu-lh.conf`` and replace the `$COINBASE` 
  variable from the ``--miner-coinbase`` flag with your Metamask address.

Enabling a Validator
====================

First of all, make sure the **Consensus Layer and Execution Layer** are in sync.

Deposit and Keys generation
---------------------------

Get some **Kiln ETH** (fake ETH) from the public faucet, your **ETH address** and your 
**address private key**. Please, check `Remy Roy's`_ guide to do so (only this part).

.. _Remy Roy's: https://github.com/remyroy/ethstaker/blob/main/merge-devnet.md#trying-the-kiln-testnet-and-performing-transactions

Once you have **Metamask** configured and received 32 ETH from the public faucet, run twice the 
following command in order to get your Validator keys and validator Withdrawl mnemonics:

.. prompt:: bash $

  eth2-val-tools mnemonic && echo
  eth2-val-tools mnemonic && echo

Save both mnemonics.

Now, we need to set some ``env`` variables and run the deposit script:

Use your favorite editor (vim, for instance):

.. prompt:: bash $

  sudo vim /etc/ethereum/kiln/secrets.env

Fill the following variables in (inside the quotation marks):

.. prompt:: bash $

  VALIDATORS_MNEMONIC (your first mnemonic)
  WITHDRAWALS_MNEMONIC (your second mnemonic)
  PRYSM_PASSWD (a random password for the Prysm wallet)
  ETH1_FROM_ADDR (your Metamask address from Remy's guide)
  ETH1_FROM_PRIV (your Metamask address private key from Remy's guide)

Save the changes and exit.

Now, we need to run the **`devnet_deposits.sh`** script to make the deposit in the Kiln 
staking contract and generate the keys for the validator:

.. prompt:: bash $

  devnet_deposits.sh

You should see now a message displaying the transaction data and your validator
 public key. All keystore data is in the ``/home/etherem/assigned_data`` directory. 
 Now let's get the secret key generated by the script:

.. prompt:: bash $

  cat /home/ethereum/assigned_data/secrets/<pubkey> && echo

replace the `<pubkey>` with your public key.

**Write down the secret** displayed as you will need it in the next steps.


Validator config
----------------

Let's enable 1 validator. Check the consensus Layer previously chosen as some config 
files and services depend on it (and again, make sure that EL+CL are in sync),

Lighthouse
~~~~~~~~~~

First, you need to write down the **Beacon Chain data directory**. For instance, if you started :guilabel:`Geth` with :guilabel:`Lighthouse`, 
the data directory will be ``/home/ethereum/.lh-geth/kiln/testnet-lh``

Import the validator keys (we will suppose you've been running :guilabel:`Geth`):

.. prompt:: bash $

  lighthouse-ks account validator import --directory=/home/ethereum/assigned_data/keys --datadir=/home/ethereum/.lh-geth/kiln/testnet-lh

Paste the **keystore private password** (the one from /home/ethereum/assigned_data/secrets/<pubkey>)

Now, start the :guilabel:`Lighthouse` validator service (again, the example command asumes :guilabel:`Geth` as EL):

.. prompt:: bash $

  sudo systemctl start lh-geth-validator

Prysm
~~~~~

You will need the :guilabel:`Prysm` password that you previously set in the `secrets.env` file. 
Put this password in the wallet file as follows:

.. prompt:: bash $

  sudo bash -c "echo $PRYSM_PASSWD > /etc/ethereum/kiln/prysm-wallet-password.txt"
  
Replace `$PRYSM_PASSWD` variable for your password.

All set, now run the validator systemd service (for instance, :guilabel:`Nethermind` as EL):

.. prompt:: bash $

  sudo systemctl start pry-neth-validator

Nimbus
~~~~~~

Again, you need to check the **Beacon Chain data directory** (depends on your 
CL+EL clients. For instance, asuming :guilabel:`Besu` as EL, let's import the keys into 
the :guilabel:`Nimbus` account:

.. prompt:: bash $

  nimbus_beacon_node-ks deposits import /home/ethereum/assigned_data/keys --data-dir=/home/ethereum/.nim-besu/kiln/testnet-nim

Paste the keystore private password (the one from `/home/ethereum/assigned_data/secrets/<pubkey>`).

Teku
~~~~

Check the **Beacon Chain data directory**. We need to place some variables in the Teku 
config file. Let's asume :guilabel:`Geth` as EL client.

First, we need to grab the .json and .txt file name located in `/home/ethereum/assigned_data` dir.

.. prompt:: bash $

  ls /home/ethereum/assigned_data/teku-secrets/ | cut -d "." -f 1

Write this down and edit the Teku+Geth config file (with vim, for instance):

.. prompt:: bash $

  sudo vim /etc/ethereum/kiln/teku-geth.conf

And replace `{**teku-key-file**}` and `{**teku-secret-file**}`** placeholders with this value.

Finally, get your Metamask address and replace the `{**your_eth_address**}` placeholder with it.

You should have something like this:

.. prompt:: bash $

  ARGS='--data-path /home/ethereum/.teku-geth/kiln/datadir-teku --network kiln --Xee-endpoint http://localhost:8545 --validator-keys=/home/ethereum/assigned_data/teku-keys/0x811becb8b9bbca53a0fc8fc5b71690e813e9f6defac4b08e2131f1e27b1875d913d4968ce40bb1d66791ce077805944c.json:/home/ethereum/assigned_data/teku-secrets/0x811becb8b9bbca53a0fc8fc5b71690e813e9f6defac4b08e2131f1e27b1875d913d4968ce40bb1d66791ce077805944c.txt --Xvalidators-proposer-default-fee-recipient 0x22898bd71D42aE90AaE78dF2ED8db34F2aE4958c'

All set, start :guilabel:`Teku` (for instance, assuming :guilabel:`Geth` as EL):

.. prompt:: bash $

  systemctl start teku-geth
