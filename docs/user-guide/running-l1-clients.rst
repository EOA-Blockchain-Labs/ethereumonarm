.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Running Layer 1 nodes
=====================

In order to run an Ethereum node you will need to run 2 different clients at the same time: 
**one Consensus Layer Client (Beacon Chain) and one Execution Layer Client**.

Very briefly, you have to:

1. **Run and sync a Consensus Client (Beacon chain)** using Checkpoint sync (it syncs in a few minutes).
2. **Wait** for the Beacon Chain to get in sync.
3. **Run and sync an Execution Client**.

.. note::
  :guilabel:`Erigon` is the only Execution Layer client that includes a Light Consensus Layer Client. You can 
  run a full Ethereum node just by starting the Erigon service.

See below for further details.

Consensus Layer Nodes
---------------------

The Consensus Layer node consists of two separate clients:

* The Beacon Chain client
* The Validator client

As stated above, for running a full Ethereum node you will need to start a Beacon Chain client 
and an Execution Layer client. The Beacon Chain is the one telling the Execution Layer client how to follow the head 
of the chain, so, without it, the Execution Client would be lost and it could not start the sync.

**You need a synced Beacon Chain Client for the Execution Client sync to start. As we configured Checkpoint 
  Sync by default in all clients, the Beacon Chain should be in sync in a few minutes.**

.. note::
  **REMEMBER: Staking is NOT necessary for running a full Ethereum node**. For this, you just need 
  a synced Execution Client running along with a synced Consensus Layer Beacon Chain.

Beacon Chain
~~~~~~~~~~~~

The Beacon Chain is a bridge between the Execution Layer and the Consensus Layer clients. 
It connects the Validator to the Execution Layer so the Validator can detect the 
32 ETH deposit transaction (which contains the Validator public key).

The Beacon Chain also guides the Execution Client on how to follow the chain head.

In order to propose (create) blocks in Ethereum you need an Execution Client in sync running along 
with a Beacon Chain in sync and a Validator (the Beacon chain and the Validator are both 
part of the Consensus Layer Client).

Checkpoint Sync
"""""""""""""""

**All Consensus Layer clients are configured to use CheckPoint Sync by default** that will 
get the Beacon Chain synced in just a few minutes.

Supported Clients
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


Lighthouse
~~~~~~~~~~

:guilabel:`Lighthouse` is a full CL client written in Rust.

.. csv-table::
  :header: Systemd Services, Home Directory, Config Files, Default TCP/UDP Port

  `lighthouse-beacon lighthouse-validator`, `/home/ethereum/.lighthouse`, `/etc/ethereum/lighthouse-beacon.conf /etc/ethereum/lighthouse-validator.conf`, `9000`


1.- Port forwarding

You need to open the 9000 port in your router (both UDP and TCP)

2.- Start the beacon chain

Under the ethereum account, run:

.. prompt:: bash $

  sudo systemctl start lighthouse-beacon

The Lighthouse client will start to sync the Beacon Chain. **This may take just some minutes as Checkpoint sync 
is enabled by default.**

The Lighthouse beacon chain is now started. Wait for it to get in sync. Choose an Execution Layer client and start it.

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

  sudo systemctl start prysm-beacon

This will start to sync the Beacon Chain. **This may take just some minutes as Checkpoint sync 
is enabled by default.**


The Prysm beacon chain is now started. Wait for it to get in sync. Choose an Execution Layer client and start it.

Teku
~~~~

:guilabel:`Teku` is a full Consensus Layer client written in Java.

.. csv-table::
  :header: Systemd Services , Home Directory, Config File, Default TCP/UDP Port

  `teku-beacon teku-validator`, `/home/ethereum/.teku/beacon /home/ethereum/.teku/validator`, `/etc/ethereum/teku-beacon.conf /etc/ethereum/teku-validator.conf`, `9000`

1.- Port forwarding

You need to open the 9000 port (both UDP and TCP)

2.- Start the beacon chain

Under the ethereum account, run:

.. prompt:: bash $

  sudo systemctl start teku-beacon

The Teku beacon chain is now started. Wait for it to get in sync. Choose an Execution Layer client and start it.

Nimbus
~~~~~~

.. warning::

  From version 23.1.0, we upgraded :guilabel:`Nimbus` to run as 2 independent processes, 
  1 binary for the Beacon Chain and 1 binary for the validator (so 2 different services). 

  If you are using a prior release please upgrade and take into account that you need to 
  run 2 Systemd services.

  **You need to stop the nimbus service before upgrading to 23.1.0**
  
:guilabel:`Nimbus` is a full Consensus Layer client written in Nim.

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `nimbus`, `/home/ethereum/.nimbus-beacon /home/ethereum/.nimbus-validator`, `/etc/ethereum/nimbus-beacon.conf /etc/ethereum/nimbus-validator.conf`, `9000`

1.- Port forwarding

You need to open the 9000 port (both UDP and TCP)

2. Copy and paste your Ethereum Address for 
receiving tips and set the fee recipient flag:

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS' /etc/ethereum/nimbus-validator.conf

  For instance:

.. prompt:: bash $

  sudo sed -i 's/changeme/0xddd33DF1c333ad7CB5716B666cA26BC24569ee22/' /etc/ethereum/nimbus-validator.conf

3. Enable Checkpoint Sync. 

We need to run a command manually before the **Checkpoint Sync** gets started:

.. prompt:: bash $

  nimbus_beacon_node trustedNodeSync --network=mainnet --data-dir=/home/ethereum/.nimbus-beacon --trusted-node-url=https://beaconstate.ethstaker.cc --backfill=false

Wait for the command to finish.

4. Start the Nimbus Beacon Chain service:

.. prompt:: bash $

  sudo systemctl start nimbus-beacon

The Nimbus Beacon Chain is now started. Wait for it to get in sync. Choose an Execution Layer client and start it.

Execution Layer nodes
---------------------

The **Execution Clients**  are the clients responsible for 
executing transactions and storing the blockchain global state among other operations.

Supported clients
~~~~~~~~~~~~~~~~~

Ethereum on ARM supports all available Execution Layer clients.

.. csv-table:: Execution Layer Supported Clients
   :header: Client, Official Binary, Language, Home

   `Geth`, `Yes`, `Go`, geth.ethereum.org_
   `Nethermind`, `Yes`, `.NET`, nethermind.io_
   `Erigon`,`No (crosscompiled)`, `Go`, `github.com/ledgerwatch/erigon`_
   `Hyperledger Besu`, `Yes`, `Java`, hyperledger.org_

.. _geth.ethereum.org: https://geth.ethereum.org
.. _nethermind.io: https://nethermind.io
.. _github.com/ledgerwatch/erigon: https://github.com/ledgerwatch/erigon
.. _hyperledger.org: https://hyperledger.org/use/besu

.. warning::

  Remember that you need to run a synced Consensus Layer client before starting the Execution Layer client (unless you 
  use :guilabel:`Erigon` and you are not going to stake)

Geth
~~~~

:guilabel:`Geth` is the most used EL client. It is developed by the Ethereum Foundation team
and the performance on ARM64 devices is outstanding. It is capable of syncing the whole blockchain 
in 2-3 days on a **Raspberry Pi 4 with 8 GB RAM** and in less that 1 day on the 
**Radxa Rock 5B**.

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `geth`, `/home/ethereum/.geth`, `/etc/ethereum/geth.conf`, `30303`

You can start the client by running:

.. prompt:: bash $

  sudo systemctl start geth

For further info of how the node is doing you can use Systemd journal:

.. prompt:: bash $

  sudo journalctl -u geth -f

Nethermind
~~~~~~~~~~

:guilabel:`Nethermind` is a .NET enterprise-friendly full Execution Layer client.

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `nethermind`, `/home/ethereum/.nethermind`, `/opt/nethermind/configs/mainnet.json`, `30303`

In order to start the client run:

.. prompt:: bash $

  sudo systemctl start nethermind  

Hyperledger Besu
~~~~~~~~~~~~~~~~

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `besu`, `/home/ethereum/.besu`, `/etc/ethereum/besu.conf`, `30303`

In order to start the client run:

.. prompt:: bash $

  sudo systemctl start besu

Erigon
~~~~~~

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `erigon`, `/home/ethereum/.erigon`, `/etc/ethereum/erigon.conf`, `30303`

In order to start the client run:

.. prompt:: bash $

  sudo systemctl start erigon

.. note::
  :guilabel:`Erigon` is the only client that includes a Light Consensus Client. You can 
  run a full Ethereum node just by starting the Erigon service.

Staking
-------

.. warning::

  **DISCLAIMER**: Ethereum is an experimental technology. **Running the Ethereum on ARM image as 
  an a Consensus Layer validator node can lead you to ETH loss**. This is a risky operation and you 
  alone are responsible for your actions using the Ethereum software included in this image 
  or following the instructions of this guide.

  We strongly recommend to try first a Consensus Layer testnet and get 
  familiarized with the process before staking real ETH.

  **REMEMBER: Staking is NOT necessary for running a full Ethereum node**. For this, you just need a 
  synced Execution Client running along with a synced Consensus Layer Beacon Chain.

Ethereum staking is the process of participating in the proof-of-stake (PoS) consensus mechanism 
of the Ethereum network by locking up 32 ETH in the validator deposit contract. Staking serves as 
a way to secure the network, validate transactions, and create new blocks on the Ethereum blockchain, 
while also rewarding participants for their contributions.

In order to stake you need to set up a Validator Client that will propose blocks and do attestations 
according to the Consensus Layer specification (proposing a block would be the equivalent to "mine" a block 
in the former Proof of Work Ethereum chain).

The validator client is included in all Consensus Layer clients along with the Beacon Chain clients.

.. warning::

  There is a chance of losing your ETH if your validator does something wrong (this is 
  called being slashed), so be extremely carefull and always follow the protocol 
  specification.

  And **never (EVER)** run the same validator keys in two different nodes at the same time. 
  **You will be slashed**.

Staking Requirements
~~~~~~~~~~~~~~~~~~~~

In order to stake and run a validator you will need:

  * 32 ETH
  * A synced Ethereum Execution Layer client
  * A synced Ethereum Consensus Layer client consisting of: A Beacon Chain instance and a 
    Validator instance (with one or more validator keys)

Before making the 32 ETH deposit you need to create 2 key pairs and a Json file with the 
necessary information to interact with the mainnet staking contract through a transaction.

The Ethereum Foundation provides a tool (staking-deposit-cli) to create the keys and the 
deposit information (which among others contains your validator(s) public key(s)). This 
tool is already installed in your Ethereum on ARM node. If you are running an older image 
please, run:

.. prompt:: bash $

  sudo apt-get update
  sudo apt-get install staking-deposit-cli

Additionally, the Ethereum Foundation developed a web Launchpad to walk you through the staking process. 
Here you can upload the Deposit Json file and make the 32 ETH transaction 
with your wallet or a web3 wallet (such as Metamask or Wallet Connect).

Validator setup
~~~~~~~~~~~~~~~
.. note::
  Remember that you need 32 ETH for each validator you want to run.

The validator setup is client agnostic so it will be valid for all Consensus Layer clients.

.. note::
  At this point, you should have an Execution Layer + Consensus Layer clients combo in sync (both clients 
  running along one 1 on 1).
  
The first step is to visit the EF Launchpad website to start the process:

`https://launchpad.ethereum.org`_

.. _https://launchpad.ethereum.org: https://launchpad.ethereum.org

1. Click **“Become a validator”**

2. Read carefully and accept all warnings. 
   
3. You can skip the **Execution Client** selection as all clients are already installed and configured. click 
   "Continue"

4. Same for the **Consensus Clients**. Click "Continue"

5. In the next screen, select the number of validators you want to run. Remember that you need 
   32 ETH for each one.

6. Ethereum on ARM provides the Ethereum Foundation tool (staking-deposit-cli) to generate the keys and 
set the withdrawal address (where the staked ETH will be deposited periodically). so, 
**in your terminal** and under the ethereum account, run (assuming 1 validator):

.. prompt:: bash $

    cd && deposit new-mnemonic --num_validators 1 --execution_address YOUR_ETH_ADDRESS --chain mainnet

7. You will see a warning about the withdrawal address. Please, **make sure you have control over the 
address you are setting. Otherwise you won't be able to withdrawn your ETH and the staked ETH.**

Choose your mnemonic language and type a password for keeping your keys safe.

.. warning::

  Now, **Make sure you wrote down the nnemonic on a safe place**. Without it you will NOT be
  able to withdrawn your ETH in the future.

  **Again, please, make sure your mnemonic is safe!!!**

Write down your mnemonic password, press any key and type it again as requested.

8. Now you have 2 JSON files under the ``validator_keys`` directory:

  * A deposit data file for making the 32 ETH transaction to the mainnet (which contains 
    your validator public key as well).
  * A keystore file with your validator keys that will be used by your Consensus Layer 
    client.

9. Back to the Launchpad website, check **"I am keeping my keys safe and have written down 
my mnemonic phrase"** and click **"Continue"**.

.. warning::

  Again, **make sure you have both an Execution Layer client + a Consensus Layer client synced, 
  running along and properly configured**.

10. It is time to send the 32 ETH deposit to the Ethereum mainnet contractg. You need the 
deposit file (located in your Board). You can, either copy and paste the 
file content and save it as a new JSON file in your desktop computer or copy the file 
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

12. Go back to your chosen validator client, import the keys located in the ``validator_keys`` directory 
and start the service (check the specific client documentation above for further instructions).

Congrats!, you just started your validator activation process.

Running Validator Client
~~~~~~~~~~~~~~~~~~~~~~~~

Once the Beacon Change is syncronized and we have our keys and deposit created, we need to start the Validator Client. These 
are the instructions for each client, pick the one that are already running the Beacon Chain.

Lighthouse
++++++++++

First, we need to import the previously generated validator keys and set the set Fee Recipient flag. Run under the ethereum account:

.. prompt:: bash $

  lighthouse account validator import --directory=/home/ethereum/validator_keys

Then, type your previously defined password and copy and paste your Ethereum Address for receiving tips and set the set the fee recipient flag:

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS' /etc/ethereum/lighthouse-validator.conf

  For instance:

.. prompt:: bash $

  sudo sed -i 's/changeme/0xddd33DF1c333ad7CB5716B666cA26BC24569ee22/' /etc/ethereum/lighthouse-validator.conf

.. prompt:: bash $

  sudo systemctl start lighthouse-validator

The Lighthouse Validator is now started.

Prysm
+++++

Import the validator keys. Run under the ethereum account:

.. prompt:: bash $

  validator accounts import --keys-dir=/home/ethereum/validator_keys

Accept the default wallet path and enter a password for your wallet. Now enter 
the password previously defined.

Now, copy and paste your Ethereum Address for receiving tips and set the set the fee recipient flag:

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS' /etc/ethereum/prysm-validator.conf

  For instance, your command should look like this::

.. prompt:: bash $

  sudo sed -i 's/changeme/0xddd33DF1c333ad7CB5716B666cA26BC24569ee22/' /etc/ethereum/prysm-validator.conf

Lastly, set up your password and start the client:

.. prompt:: bash $

  echo "$YOUR_PASSWORD" > /home/ethereum/validator_keys/prysm-password.txt
  sudo systemctl start prysm-validator

The Prysm  validator is now enabled.

Nimbus
++++++

We need to import your validator keys. Run under the ethereum account:

.. prompt:: bash $

  nimbus_beacon_node deposits import /home/ethereum/validator_keys --data-dir=/home/ethereum/.nimbus-validator --log-file=/home/ethereum/.nimbus-validator/nimbus.log

Enter the password previously defined.

Now, copy and paste your Ethereum Address for receiving tips and set the set the fee recipient flag:

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS' /etc/ethereum/nimbus-validator.conf

  For instance, your command should look like this::

.. prompt:: bash $

  sudo sed -i 's/changeme/0xddd33DF1c333ad7CB5716B666cA26BC24569ee22/' /etc/ethereum/nimbus-validator.conf

Start the Nimbus Validator:

.. prompt:: bash $

  sudo systemctl start nimbus-validator

Teku
++++

You need to create a file for each validator. The file will have the same name as the keystore but with 
the .txt extension. Remember that the keystore json files are located in the ``/home/ethereum/validator_keys`` 
directory.

You can see your current keystore name(s) by running:

.. prompt:: bash $

  ls /home/ethereum/validator_keys

Create a txt file with the same name of the json one and write the filestore password (replace 
$KEYSTORE_NAME for your file name. $PASSWORD is the one set in the previous section) "Validator setup and 32 ETH deposit":

.. prompt:: bash $

  echo "$YOUR_PASSWORD" > validator_keys/$KEYSTORE_NAME.txt

now, you should see something like this in your validator_keys directory (for each keystore):

.. prompt:: bash $

  keystore-m_12381_3600_0_0_0-1661710189.json
  keystore-m_12381_3600_0_0_0-1661710189.txt

Copy and paste your Ethereum Address for receiving tips and set the set the fee recipient flag:

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS' /etc/ethereum/teku-validator.conf

  For instance, your command should look like this::

.. prompt:: bash $

  sudo sed -i 's/changeme/0xddd33DF1c333ad7CB5716B666cA26BC24569ee22/' /etc/ethereum/teku-validator.conf

Start the Teku Validator:

.. prompt:: bash $

  sudo systemctl start teku-validator

The Teku Validator is now enabled.