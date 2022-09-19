.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Consensus Layer
===============

.. warning::

  **DISCLAIMER**: Ethereum is an experimental technology. Running the Ethereum on ARM image as 
  an Consensus Layer validator node can lead you to loss of ETH. This is a risk operation and you 
  alone are responsible for your actions using the Ethereum sofware included in this image 
  or following the instructions of this guide.

  We strongly recommend to try first an Consensus Layer testnet (**Prater**) and get 
  familiarized with the process before staking with real ETH.


The Consensus Layer is the new Proof of Stake chain. If you 
want to get further info please visit the `ethereum EF page`_

.. _ethereum EF page: https://ethereum.org/es/upgrades/

An Ethereum Consensus Layer client consists of two components, a Beacon chain and a Validator.

Beacon Chain
------------

The Beacon Chain is a bridge between the Execution Layer and the Consensus Layer clients. 
It connects the Validator to the EL so the validator can detect the 
32 ETH deposit transaction (which contains the Validator public key). In order to 
propose (create) blocks in Ethereum you need the Beacon Chain synced and  
connected to an EL client.

Validator
---------

Here is basically where the stake process happens (with the new Proof of Stake algorithm).

The validator is the client that proposes blocks and does attestations according to 
the Consensus Layer specification (proposing a block would be the equivalent to "mine" a block 
in the former Ethereum 1.0 chain).

.. warning::

  There is a chance of losing your ETH if your validator does something wrong (this is 
  called being slashed), so be extremely carefull and always follow the protocol 
  specification.

  And **never (NEVER)** run the same validator (same private keys) in two different validator nodes at the same time. 
  **You will be slashed**.

Staking Requirements
--------------------

In order to stake and run a validator you will need:

  * 32 ETH
  * An Ethereum Execution Layer client
  * An Ethereum Consensus Layer client consisting of: A Beacon Chain instance and a 
  Validator instance (with one or more validator keys)

For making the 32 ETH deposit you need to create 2 key pairs and a Json file with the 
necessary information to interact with the Eth2 mainnet contract through a transaction.

The Ethereum Foundation provides a tool (staking-deposit-cli) to create the keys and the 
deposit information (which among others contains your validator(s) public key(s)). This 
tool is already installed in your node in the new Ethereum on ARM images. If you are running an older image 
please, run:

.. prompt:: bash $

  sudo apt-get update
  sudo apt-get install staking-deposit-cli

Additionally, the Ethereum Foundation set up a web Launchpad to make the staking process 
much more easy. Here you can upload the Deposit Json file and make the 32 ETH transaction 
with your wallet or a web3 wallet (such as Metamask or Walletconnect).

Validator setup and 32 ETH deposit
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The validator setup is client agnostic so it will be valid for all CL clients.

.. note::
  At this point, you should have an Execution Layer + Consensus Layer clients combo ( both clients 
  running along one 1 on 1).
  
The first step is to visit the EF Launchpad website to start the process:

`https://launchpad.ethereum.org`_

.. _https://launchpad.ethereum.org: https://launchpad.ethereum.org

1. Click **“Get started”**

2. Read carefully and accept all warnings. 
   
3. You can skip the **Execution Client** selection as all clients are already installed and configured. click 
   "Continue"

4. Same for the **Consensus clients**. Click "Continue"

5. In the next screen, select the number of validators you want to run. Remember that you need 
   32 ETH for each.

6. Ethereum on ARM provides the Ethereum Foundation tool (staking-deposit-cli) to generate the keys, 
   so, in your device terminal and under the ethereum account, run (assuming 1 validator):

.. prompt:: bash $

    cd && deposit new-mnemonic --num_validators 1 --chain mainnet

7. Choose your mnemonic language and type a password for keeping your keys safe. Write 
down your mnemonic password, press any key and type it again as requested.

.. warning::

  **Make sure you wrote down the nnemonic on a safe place**. Without it you will NOT be
  able to withdrawn your ETH in the future.

  **Again, please, make sure your mnemonic is safe!!!**

8. Now you have 2 Json files under the ``validator_keys`` directory:

  * A deposit data file for making the 32 ETH transaction to the mainnet (which contains 
    your validator public key as well).
  * A keystore file with your validator keys that will be used by your Consensus Layer 
    client.

9. Back to the Launchpad website, check **"I am keeping my keys safe and have written down 
my mnemonic phrase"** and click **"Continue"**.

.. warning::

  At this point, **make sure you have both an Execution Layer client + a Consensus Layer client synced, 
  running along and properly configured**.

10. It is time to send the 32 ETH deposit to the Ethereum mainnet contractg. You need the 
deposit file (located in your Raspberry Pi). You can, either copy and paste the 
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

11. Now, back to the Launchpad website, upload the ``deposit_data`` file and select 
Metamask, click continue and check all warnings. Click "Continue" and click 
**“Initiate the Transaction”**. Confirm the transaction in Metamask and wait 
for the confirmation (a notification will pop up shortly).

The Beacon Chain (which is connected to the Execution Layer client) will detect 
this deposit and the Validator will be enabled.

Congrats!, you just started your validator activation process.

Running a Consensus Layer client
------------------------------

.. warning::

  Remember that you need to run an Execution Layer along with the Consensus Layer client as well. 
  CL client is the one telling the EL how to follow the head of the chain, so, without it, EL would 
  be lost and it could not start the sync.

  **You need a synced Consensus Client for the Execution Client sync to start. As we are using Checkpoint 
  Sync, CL client should be in sync in a few minutes.**


Supported clients
~~~~~~~~~~~~~~~~~

Ethereum on ARM supports the main Consensus Layer clients available.

.. csv-table::
   :header: Client, Official Binary, Language, Home

   `Lighthouse`, `Yes`, `Rust`, lighthouse-book.sigmaprime.io_
   `Prysm`, `Yes`, `Go`, docs.prylabs.network_
   `Nimbus`,`Yes`, `Nim`, nimbus.team_
   `Teku`, `Yes`, `Java`, consensys.net_

.. _lighthouse-book.sigmaprime.io: https://lighthouse-book.sigmaprime.io
.. _docs.prylabs.network: https://docs.prylabs.network/docs/getting-started/
.. _nimbus.team: https://nimbus.team
.. _consensys.net: https://consensys.net/knowledge-base/ethereum-2/teku/

CheckPoint sync
~~~~~~~~~~~~~~~

You can **sync your Consensus Client in minutes** using the info provided by an already synced Beacon Node. 
All Consensus clients support this sync mode and the necessary flags are detailed on each client section.

You will need to pass a valid URL to your client from a synced client. We include now the **EthStaker** URL 
Checkpoint Sync as default. You can change it at any time by editing the CL config file.


Lighthouse
~~~~~~~~~~

:guilabel:`Lighthouse` is a full CL client written in Rust. It is very capable on
running in resource-constrained devices such as the Raspberry Pi 4.

.. csv-table::
  :header: Systemd Services, Home Directory, Config Files, Default TCP/UDP Port

  `lighthouse-beacon lighthouse-validator`, `/home/ethereum/.lighthouse`, `/etc/ethereum/lighthouse-beacon.conf /etc/ethereum/lighthouse-validator.conf`, `9000`


1.- Port forwarding

You need to open the 9000 port in your router (both UDP and TCP)

2.- Start the beacon chain

Under the ethereum account, run:

.. prompt:: bash $

  sudo systemctl enable lighthouse-beacon
  sudo systemctl start lighthouse-beacon

The Lighthouse client will start to sync the Beacon Chain. **This may take just some minutes as Checkpoint sync 
is enabled by default.**

3.- Start de validator

We need to import the previously generated validator keys and set the set Fee Recipient flag. Run under the ethereum account:

.. prompt:: bash $

  lighthouse account validator import --directory=/home/ethereum/validator_keys

Then, type your previously defined password

Now, copy your Ethereum Address for receiving tips and set the set the fee recipient flag:

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS' /etc/ethereum/lighthouse-validator.conf

  For instance:

.. prompt:: bash $

  sudo sed -i 's/changeme/0xddd33DF1c333ad7CB5716B666cA26BC24569ee22/' /etc/ethereum/lighthouse-validator.conf

.. prompt:: bash $

  sudo systemctl start lighthouse-validator

The Lighthouse beacon chain and validator are now started.

Prysm
~~~~~

:guilabel:`Prysm` is a full Consensus Layer client written in Go.

.. csv-table::
  :header: Systemd Services, Home Directory, Config Files, Default TCP/UDP Port

  `prysm-beacon prysm-validator`, `/home/ethereum/.eth2`, `/etc/ethereum/prysm-beacon.conf /etc/ethereum/prysm-validator.conf`, `13000 12000`

1.- Port forwarding

You need to open the 13000 (TCP) and 12000 (UDP) ports in your router/firewall

2.- Start the beacon chain

Under the ethereum account, run:

.. prompt:: bash $

  sudo systemctl enable prysm-beacon
  sudo systemctl start prysm-beacon

This will start to sync the Beacon Chain. **This may take just some minutes as Checkpoint sync 
is enabled by default.**

3.- Start de validator

We need to import the validator keys. Run under the ethereum account:

.. prompt:: bash $

  validator accounts import --keys-dir=/home/ethereum/validator_keys

Accept the default wallet path and enter a password for your wallet. Now enter 
the password previously defined.

Now, copy your Ethereum Address for receiving tips and set the set the fee recipient flag:

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS' /etc/ethereum/prysm-validator.conf

  For instance, your command should look like this::

.. prompt:: bash $

  sudo sed -i 's/changeme/0xddd33DF1c333ad7CB5716B666cA26BC24569ee22/' /etc/ethereum/prysm-validator.conf

Lastly, set up your password and start the client:

.. prompt:: bash $

  echo "$YOUR_PASSWORD" > /home/ethereum/validator_keys/prysm-password.txt
  sudo systemctl start prysm-validator

The Prysm beacon chain and the validator are now enabled.

Teku
~~~~

:guilabel:`Teku` is a full Consensus Layer client written in Java.

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `teku`, `/home/ethereum/.teku/data_teku`, `/etc/ethereum/teku.conf`, `9151`

1.- Port forwarding

You need to open the 9000 port (both UDP and TCP)

2.- Start the Beacon Chain and the Validator

Copy your Ethereum Address for receiving tips and set the set the fee recipient flag:

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS' /etc/ethereum/teku.conf

  For instance, your command should look like this:

.. prompt:: bash $

  sudo sed -i 's/changeme/0xddd33DF1c333ad7CB5716B666cA26BC24569ee22/' /etc/ethereum/teku.conf

Now, let's create a password file with the same name as the json one in the validator_keys directory:

You can see the keystore name by running:

.. prompt:: bash $

  ls /home/ethereum/validator_keys

Create a txt file with the same name of the json one and write the filestore password (replace 
$KEYSTORE_NAME for your file name and $YOUR_PASSWORD with a strong password generated by you):

.. prompt:: bash $

  touch validator_keys/$KEYSTORE_NAME.txt
  echo "$YOUR_PASSWORD" > validator_keys/$KEYSTORE_NAME.txt

now, you should see something like this in your validator_keys directory:

.. prompt:: bash $

  keystore-m_12381_3600_0_0_0-1661710189.json
  keystore-m_12381_3600_0_0_0-1661710189.txt

Start the beacon chain and the validator:

.. prompt:: bash $

  sudo systemctl start teku

The Teku beacon chain and validator are now enabled. the Beacon Chain will sync in just 
a few minutes as **Checkpoint sync is enabled by default.** 

Nimbus
~~~~~~

:guilabel:`Nimbus` is a full Consensus Layer client written in Nim.

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `nimbus`, `/home/ethereum/.nimbus`, `/etc/ethereum/nimbus.conf`, `9000`

1.- Port forwarding

You need to open the 9000 port (both UDP and TCP)

2.- Start the Beacon Chain and the Validator

We need to import the validator keys. Run under the ethereum account:

.. prompt:: bash $

  nimbus_beacon_node deposits import /home/ethereum/validator_keys --data-dir=/home/ethereum/.nimbus --log-file=/home/ethereum/.nimbus/nimbus.log

Enter the password previously defined.

Now, copy your Ethereum Address for receiving tips and set the set the fee recipient flag:

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS' /etc/ethereum/nimbus.conf

  For instance:

.. prompt:: bash $

  sudo sed -i 's/changeme/0xddd33DF1c333ad7CB5716B666cA26BC24569ee22/' /etc/ethereum/nimbus.conf

Now, in order to enable the **Checkpoint Sync** run the following command:

.. prompt:: bash $

  nimbus_beacon_node trustedNodeSync --network=mainnet --data-dir=/home/ethereum/.nimbus --trusted-node-url=https://beaconstate.ethstaker.cc --backfill=false

Wait for the command to finish and start the Nimbus service:

.. prompt:: bash $

  sudo systemctl start nimbus

The Nimbus beacon chain and validator are now enabled.