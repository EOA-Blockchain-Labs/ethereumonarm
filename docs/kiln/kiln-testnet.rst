About Kiln Raspberry Pi 4 image
===============================

The Kiln network is a public testnet for the upcoming Ethereum upgrade 
to Proof of Stake called **The Merge**. It will be (most probably) the last 
public testnet before **The merge**.

This is a **Plug and Play** image for the **Raspberry Pi 4** that sets up and 
installs all the software necessary to test Execution Layer and Consensus Layer clients 
just **by starting their Systemd services**. It includes all necessary tools to enable 
and test a **validator** as well.

**Please check here the `recommended-hardware`_ section before installing the image**:

.. _recommended-hardware: https://ethereum-on-arm-documentation.readthedocs.io/en/latest/quick-guide/recommended-hardware.html

Amazon ARM AWS AMI Image
========================

If you don't have a Raspberry Pi 4 but you own an **AWS account** (or you are willing to open one), 
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

RELEASE TBA

Download and Install
====================

Download the image here:

RELEASE TBA

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
Eth2 clients are renamed to **Consensus Layer** clients. **We need to run 
both at the same time** (EL+CL) so they can work together.

The image includes all Consensus Layer clients and Execution Layer binaries ready
to run through Systemd services and all necessary tools to make a deposit in the staking 
contract and generate the keys to enable a Validator.

This is the software included:

.. csv-table:: Kiln Supported Clients
   :header: Execution Layer, Consensus Layer

   `Geth`, `Lighthouse`
   `Nethermind`, `Prysm`
   `Besu`,`Nimbus`
   ` `, `Teku`

Kiln tools

    * **eth2-deposit-cli**: Generates keys and sets up deposit config.
    * **kiln-config**: Network setup.

Managing the clients
====================

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

In order to stake and run a validator you will need:

  * An ETH address (you can create one easily with Metamask)
  * 32 KILN ETH (never send REAL ETH to this network)
  * An Execution Layer client
  * A Consensus Layer client consisting of:
    * A Beacon Chain
    * A/several Validator(s)

For making the 32 ETH deposit you need to create **2 key pairs** and a **Json file** with the 
necessary information to interact with the Eth2 Kiln contract through a transaction.

The Ethereum Foundation provides a tool (**eth2.0-deposit-tool**) to create the keys and the 
deposit information (which among others contains your validator(s) public key(s)). This 
tool is already installed in your node.

Additionally, the Ethereum Foundation set up a **Launchpad** portal to make the staking process 
much more easy. Here you can upload the Json file and make the 32 ETH transaction 
with your wallet or a web3 wallet (we will use Metamask).

Preparation
-----------

The first step is to get some **Kiln ETH** (fake ETH).

1. Create an address in **Metamask**.

2. Go to the **Kiln portal information** and add the Kiln network to Metamask:

`https://kiln.themerge.dev/`_

.. _https://kiln.themerge.dev/: https://kiln.themerge.dev/

Click **"Add network to Metamask"**

3. Go to the **public faucet** to get 32 KILN ETH:

`https://faucet.kiln.themerge.dev/`_

.. _https://faucet.kiln.themerge.dev/: https://faucet.kiln.themerge.dev/

Paste your ETH address, complete the captcha process and click **"Request funds"**.

Check your Metamask account. You should have now 32 KILN ETHs.

Keys generation and deposit
---------------------------

Visit the **EF Launchpad** website to start the process:

`https://kiln.launchpad.ethereum.org/`_

.. _https://kiln.launchpad.ethereum.org/: https://kiln.launchpad.ethereum.org/

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

  cd && deposit new-mnemonic --num_validators 1 --chain kiln

Choose your language and the mnemonic language. Create a password to secure the keystore (repeat the password 
for confirmation).

.. warning::

  Make sure you wrote down the nnemonic on a safe place.

Type again your mnemonic phrase to complete the process.

Now you have 2 json files under the ``/home/ethereum/validator_keys`` directory:

  * A deposit data file for making the **32 ETH transaction to the Kiln contract**.
  * A keystore file with your **validator keys** that will be used by your **Consensus Client**.


6. Back to the Launchpad website, check **"I am keeping my keys safe and have written down 
my mnemonic phrase"**. Click **"Continue"**.

7. We need to upload the deposit file (located in your Ethereum node). You can, either copy and paste the 
file content and save it as a new json file in your desktop computer or copy the file 
from the Raspberry/AWS image to your desktop through SSH.

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
for both EL and CL (you can compare them with the ones displayed on the Kiln explorer:

`https://beaconchain.kiln.themerge.dev/`_

.. _https://beaconchain.kiln.themerge.dev/: https://beaconchain.kiln.themerge.dev/

Lighthouse
~~~~~~~~~~

First, you need to check for the **Beacon Chain data directory**. For instance, if you started :guilabel:`Geth` with :guilabel:`Lighthouse`, 
the data directory will be ``/home/ethereum/.lh-geth/kiln/testnet-lh``

Import the validator keys (we will suppose you've been running :guilabel:`Geth`):

.. prompt:: bash $

  lighthouse-kl account validator import --directory=/home/ethereum/validator_keys --datadir=/home/ethereum/.lh-geth/kiln/testnet-lh

Type your keystore password.

Now, start the :guilabel:`Lighthouse` validator service (again, the example command assumes :guilabel:`Geth` as EL):

.. prompt:: bash $

  sudo systemctl start lh-geth-validator

Prysm
~~~~~

We need to import the validator keys. Run under the ethereum account. Assuming we are using :guilabel:`Geth` as Execution Layer:

.. prompt:: bash $

  validator-kl accounts import --keys-dir=/home/ethereum/validator_keys --wallet-dir /home/ethereum/.pry-geth/kiln/testnet-pry
  
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

  nimbus_beacon_node-kl deposits import /home/ethereum/validator_keys --data-dir=/home/ethereum/.nim-besu/kiln/testnet-nim

Type your keystore password and restart the validator process:

.. prompt:: bash $

  sudo systemctl restart .nim-besu

Teku
~~~~

Check the **Beacon Chain data directory**. We need to place some variables in the Teku 
config file. Let's asume :guilabel:`Geth` as EL client.

We need to set some variables before starting the client.

First, let's get the keystore json file:

.. prompt:: bash $

  ls /home/ethereum/validator_keys/keystore*

Copy the json file (only the file, not the entire path).

Finally, get your Metamask address and put both together in the following command:

.. prompt:: bash $

  sudo sed -i 's/changeme1/$KEYSTORE_FILE/' /etc/ethereum/kiln/teku-geth.conf
  sudo sed -i 's/changeme2/$YOUR_ETH_ADDRESS/' /etc/ethereum/kiln/teku-geth.conf

Replace $KEYSTORE_FILE for your json file and $YOUR_ETH_ADDRESS for your Metamask address.

All set, start :guilabel:`Teku` (for instance, assuming :guilabel:`Geth` as EL):

.. prompt:: bash $

  systemctl start teku-geth
