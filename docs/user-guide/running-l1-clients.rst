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
   `Lodestar`, `Yes`, `Typescript`, lodestar.chainsafe.io_
   `Grandine`, `Yes`, `Rust`, grandine.io_
   `Vouch`, `Yes`, `Go`, vouch.io_

.. _lighthouse-book.sigmaprime.io: https://lighthouse-book.sigmaprime.io
.. _docs.prylabs.network: https://docs.prylabs.network/docs/getting-started/
.. _nimbus.team: https://nimbus.team
.. _consensys.net: https://consensys.net/knowledge-base/ethereum-2/teku/
.. _lodestar.chainsafe.io: https://lodestar.chainsafe.io/
.. _grandine.io: https://grandine.io/
.. _vouch.io: https://vouch.io/


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

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS/' /etc/ethereum/nimbus-validator.conf

3. Enable Checkpoint Sync. 

We need to run a command manually before the **Checkpoint Sync** gets started:

.. prompt:: bash $

  nimbus_beacon_node trustedNodeSync --network=mainnet --data-dir=/home/ethereum/.nimbus-beacon --trusted-node-url=https://beaconstate.ethstaker.cc --backfill=false

Wait for the command to finish.

4. Start the Nimbus Beacon Chain service:

.. prompt:: bash $

  sudo systemctl start nimbus-beacon

The Nimbus Beacon Chain is now started. Wait for it to get in sync. Choose an Execution Layer client and start it.

Lodestar
~~~~~~~~

:guilabel:`Lodestar` is a full Consensus Layer client written in Type Script.

.. csv-table::
  :header: Systemd Services , Home Directory, Config File, Default TCP/UDP Port

  `lodestar-beacon lodestar-validator`, `/home/ethereum/.lodestar`, `/etc/ethereum/lodestar-beacon.conf /etc/ethereum/lodestar-validator.conf`, `9000`

1.- Port forwarding

You need to open the 9000 port (both UDP and TCP)

2.- Start the beacon chain

Under the ethereum account, run:

.. prompt:: bash $

  sudo systemctl start lodestar-beacon

The Lodestar beacon chain is now started. Wait for it to get in sync. Choose an Execution Layer client and start it.

Grandine
~~~~~~~~

:guilabel:`Grandine` is a full Consensus Layer client written in Rust.

.. csv-table::
  :header: Systemd Services, Home Directory, Config Files, Default TCP/UDP Port

  `grandine-beacon grandine-validator`, `/home/ethereum/.grandine`, `/etc/ethereum/grandine-beacon.conf /etc/ethereum/grandine-validator.conf`, `9000`

1.- Port forwarding

You need to open the 9000 (TCP/UDP) ports in your router/firewall

.. warning::

  Currently, :guilabel:`Grandine` runs in one instance, so if you want to stake you will need to 
  configure the **Validator** file config and run the **grandine-validator** service that will start both 
  Beacon and Validator processes,. 

2.- Start the beacon chain (if you want to run a validator, skip this step and go to staking section)

Under the ethereum account, run:

.. prompt:: bash $

  sudo systemctl start grandine-beacon

This will start to sync the Beacon Chain. **This may take just some minutes as Checkpoint sync 
is enabled by default.**


The Grandine beacon chain is now started. Wait for it to get in sync. Choose an Execution Layer client and start it.

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
   `Erigon`, `Yes`, `Go`, `github.com/ledgerwatch/erigon`_
   `Hyperledger Besu`, `Yes`, `Java`, hyperledger.org_
   `EthRex`, `Yes`, `Rust`, ethrex.xyz_
   `Reth`, `Yes`, `Rust`, paradigmxyz.github.io_


.. _geth.ethereum.org: https://geth.ethereum.org
.. _nethermind.io: https://nethermind.io
.. _github.com/ledgerwatch/erigon: https://github.com/ledgerwatch/erigon
.. _hyperledger.org: https://hyperledger.org/use/besu
.. _ethrex.io: https://ethrex.xyz/
.. _paradigmxyz.github.io: https://paradigmxyz.github.io/reth/

Syncing Strategies and Times
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

One of the most frequently asked questions is: **"How long does it take to sync?"**. The answer depends heavily on the client you choose, specifically because different clients use different syncing technologies.

.. csv-table:: Execution Layer (L1) Clients — Sync Types & Times (approx. on Rock 5B / RPi5)
   :header: Client, Sync Type, Approx. Sync Time, Archive Node?
   :widths: 18, 20, 20, 15

   `Geth`, `Snap Sync`, `12–18 Hours`, `No (Full Pruned)`
   `Nethermind`, `Snap Sync`, `12–18 Hours`, `No (Full Pruned)`
   `Hyperledger Besu`, `Fast / Snap Sync`, `18–24 Hours`, `No (Full Pruned)`
   `Reth`, `Execution / Pipeline`, `3–5 Days`, `No (Full Pruned)`
   `Erigon`, `Execution / Staged`, `4–6 Days`, `No (Full Pruned)`
   `EthRex`, `Execution / Modular`, `12–18 Hours`, `No (Full Pruned)`

.. note::
   The comparison above assumes all clients are configured as **Full Nodes** (pruned state).

**Why are Reth and Erigon "slower" to sync?**

It comes down to **Snap Sync** vs **Execution Sync**:

*   **Snap Sync (Geth, Nethermind, Besu)**: The client downloads the latest "snapshot" of the blockchain state directly from peers. It trusts the Proof-of-Stake consensus to verify the chain head and then just fills in the data. This avoids re-calculating the entire history of the chain, making it significantly faster and less CPU intensive initially.

*   **Execution Sync (Reth, Erigon)**: These clients download the raw block data and **re-execute** every single transaction from the Genesis block (or a check point) to the current head. This requires massive CPU computation and I/O operations because your little ARM board is effectively re-playing the entire history of Ethereum.

**The Benefit**: While slower to sync, **Reth/Erigon** result in a highly optimized database structure that is often faster for RPC queries and, importantly, they run as **Archive Nodes** by default (keeping all historical data) with very efficient disk usage compared to a Geth Archive node.


.. warning::

  Remember that you need to run a synced Consensus Layer client before starting the Execution Layer client (unless you 
  use :guilabel:`Erigon` and you are not going to stake)

Geth
~~~~

:guilabel:`Geth` is the most used EL client. It is developed by the Ethereum Foundation team
and the performance on ARM64 devices is outstanding. It is capable of syncing the whole blockchain 
in less than 1 day on a **Raspberry Pi 5 with 16 GB RAM** and in less that 1 day on the 
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

EthRex
~~~~~~

:guilabel:`EthRex` is a lightweight, performant, and modular Ethereum execution client powering next-gen L1 and L2 solutions.

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `ethrex`, `/home/ethereum/.ethrex`, `/etc/ethereum/ethrex.conf`, `30303`

In order to start the client run:

.. prompt:: bash $

  sudo systemctl start ethrex

.. note::
   :guilabel:`EthRex` is new in Ethereum on ARM ecosystem, and still under testing 

Reth
~~~~

:guilabel:`Reth` (Rust Ethereum) is an Ethereum execution client implementation that focuses on friendliness, modularity, and speed.

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `reth`, `/home/ethereum/.reth`, `/etc/ethereum/reth.conf`, `30303`

In order to start the client run:

.. prompt:: bash $

  sudo systemctl start reth

**Full vs Archive Node**

By default, :guilabel:`Reth` runs as an **Archive Node**, storing all historical states. This requires significantly more disk space.

If you wish to run a **Full Node** (pruned state) to save disk space, you must enable the full node mode.

To do this, edit the configuration file for your network (e.g., ``/etc/ethereum/reth.conf`` for Mainnet) and add the ``--full`` flag to the ``ARGS`` variable.

Example:

.. code-block:: bash

   ARGS="node ... --full"

After saving the file, restart the service:

.. prompt:: bash $

  sudo systemctl restart reth

Erigon
~~~~~~

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `erigon`, `/home/ethereum/.erigon`, `/etc/ethereum/erigon.conf`, `30303`

In order to start the client run:

.. prompt:: bash $

  sudo systemctl start erigon


.. note::
   :guilabel:`Erigon` includes Caplin, its own consensus layer, and by default runs 
   as a full Ethereum node without requiring a separate consensus layer client.

.. warning::
   Erigon 3 introduces a major change to Erigon's architecture. Erigon is now configured to use 
   Caplin as its consensus layer by default.  Users who wish to use an external consensus 
   layer must explicitly configure Erigon to do so using the `erigon-externalcl` service. 
   This is a breaking change and requires manual configuration.

**Caplin Consensus Layer**

Erigon has integrated Caplin, its own consensus layer, directly into the client. 
This means that for most users, running a full Ethereum node is as simple as starting the `erigon` service. 
The need for a separate beacon node client is eliminated in the default configuration.

**`erigon-externalcl` Service**

For advanced use cases or when compatibility with external consensus layer clients is required, 
EoA provides the `erigon-externalcl` service. This service allows Erigon to operate with a separate consensus client.

**Upgrade Notes**

Due to the significant changes to Erigon's architecture, a manual upgrade process is necessary. 
You can use the new provided config or update yours according to the Erigon documentation.

**Further Information**

For complete details on Erigon configuration, usage, and troubleshooting, please refer to the official Erigon documentation: [https://docs.erigon.tech]


Staking
-------

.. warning::

  **DISCLAIMER**: Ethereum is an experimental technology. **Running the Ethereum on ARM image as
  a Consensus Layer validator node can lead you to ETH loss**. This is a risky operation and you
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
  called being slashed), so be extremely careful and always follow the protocol 
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
address you are setting. Otherwise you won't be able to withdraw your ETH and the staked ETH.**

Choose your mnemonic language and type a password for keeping your keys safe.

.. warning::

  Now, **Make sure you wrote down the mnemonic in a safe place**. Without it you will NOT be
  able to withdraw your ETH in the future.

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

10. It is time to send the 32 ETH deposit to the Ethereum mainnet contract. You need the 
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

Once the Beacon Chain is synchronized and we have our keys and deposit created, we need to start the Validator Client. These 
are the instructions for each client, pick the one that are already running the Beacon Chain.

**LIGHTHOUSE**

First, we need to import the previously generated validator keys and set the set Fee Recipient flag. Run under the ethereum account:

.. prompt:: bash $

  lighthouse account validator import --directory=/home/ethereum/validator_keys

Then, type your previously defined password and copy and paste your Ethereum Address for receiving tips and set the set the fee recipient flag:

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS' /etc/ethereum/lighthouse-validator.conf

  For instance:

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS/' /etc/ethereum/lighthouse-validator.conf

.. prompt:: bash $

  sudo systemctl start lighthouse-validator

The Lighthouse Validator is now started.

**PRYSM**

Import the validator keys. Run under the ethereum account:

.. prompt:: bash $

  validator accounts import --keys-dir=/home/ethereum/validator_keys

Accept the default wallet path and enter a password for your wallet. Now enter 
the password previously defined.

Now, copy and paste your Ethereum Address for receiving tips and set the fee recipient flag:

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS' /etc/ethereum/prysm-validator.conf

  For instance, your command should look like this::

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS/' /etc/ethereum/prysm-validator.conf

Lastly, set up your password and start the client:

.. prompt:: bash $

  echo "$YOUR_PASSWORD" > /home/ethereum/validator_keys/prysm-password.txt
  sudo systemctl start prysm-validator

The Prysm  validator is now enabled.

**NIMBUS**

We need to import your validator keys. Run under the ethereum account:

.. prompt:: bash $

  nimbus_beacon_node deposits import /home/ethereum/validator_keys --data-dir=/home/ethereum/.nimbus-validator --log-file=/home/ethereum/.nimbus-validator/nimbus.log

Enter the password previously defined.

Now, copy and paste your Ethereum Address for receiving tips and set the set the fee recipient flag:

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS' /etc/ethereum/nimbus-validator.conf

  For instance, your command should look like this::

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS/' /etc/ethereum/nimbus-validator.conf

Start the Nimbus Validator:

.. prompt:: bash $

  sudo systemctl start nimbus-validator

**TEKU**

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

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS/' /etc/ethereum/teku-validator.conf

Start the Teku Validator:

.. prompt:: bash $

  sudo systemctl start teku-validator

The Teku Validator is now enabled.

**LODESTAR**

We need to import the validator keys. Run under the ethereum account:

.. prompt:: bash $

  lodestar validator import --importKeystores /home/ethereum/validator_keys --dataDir /home/ethereum/.lodestar

Enter the password previously defined.

Now, copy and paste your Ethereum Address for receiving tips and set the set the fee recipient flag:

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS' /etc/ethereum/lodestar-validator.conf

  For instance, your command should look like this::

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS/' /etc/ethereum/lodestar-validator.conf

Start the Lodestar Validator service:

.. prompt:: bash $

  sudo systemctl start lodestar-validator


**GRANDINE**

.. warning::

  Make sure you are NOT running the **grandine-beacon** service before starting **grandine-validator** 

First, copy and paste your Ethereum Address for receiving tips and set the fee recipient flag:

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS' /etc/ethereum/grandine-validator.conf

  For instance, your command should look like this::

.. prompt:: bash $

  sudo sed -i 's/changeme/$YOUR_ETH_ADDRESS/' /etc/ethereum/grandine-validator.conf

Lastly, set up your password and start the client:

.. prompt:: bash $

  echo "$YOUR_PASSWORD" > /home/ethereum/validator_keys/grandine-password.txt
  sudo systemctl start grandine-validator

The **Grandine validator** is now enabled. Wait for the **Beacon Chain** to sync and check the logs for further info.

**VOUCH**

:guilabel:`Vouch` is a multi-node validator client written in Go.

.. csv-table::
  :header: Systemd Services, Home Directory, Config Files, Default TCP/UDP Port

  `vouch`, `/home/ethereum/.vouch`, `/etc/ethereum/vouch.yml`, `None`

First, you need to edit the configuration file to add your Beacon Node(s) endpoint(s).

.. prompt:: bash $

  sudo nano /etc/ethereum/vouch.yml

Add your beacon node endpoints in the `beacon-node-address` list.

We need to import the validator keys. Run under the ethereum account:

.. prompt:: bash $

  /usr/local/bin/vouch account import --base-dir=/home/ethereum/.vouch --keys-dir=/home/ethereum/validator_keys

Enter the password previously defined.

Now, copy and paste your Ethereum Address for receiving tips and set the fee recipient flag.
Edit the config file:

.. prompt:: bash $

  sudo nano /etc/ethereum/vouch.yml

And set the `fee-recipient` field:

.. code-block:: yaml

  fee-recipient: "0xYOUR_ETH_ADDRESS"

Start the Vouch service:

.. prompt:: bash $

  sudo systemctl start vouch

The **Vouch validator** is now enabled. Check the logs for further info.

Lido Liquid Staking
~~~~~~~~~~~~~~~~~~~

**Liquid Staking** refers to a decentralized protocol that allows users to stake their ETH, while simultaneously receiving 
a liquid token representing their staked assets.

When you stake **ETH** with Lido, **you receive a token called stETH, a liquid representation of your staked ETH**. The key 
innovation here is **liquidity—stETH tokens can be freely traded, utilized in DeFi applications, or held in wallets**, 
unlike traditionally locked staking that prevents users from accessing their funds until the lock-up period ends.

**Lido Community Staking Module**

The Community Staking Module (CSM) is the Lido on Ethereum protocol's first module with **permissionless entry**, 
allowing any node operator — and especially community stakers, from solo stakers, to groups of friends, to 
amateur operators — to operate validators by providing an ETH-based safety deposit.

.. note::
  Lido **CSM allows any user to become a Home Staker with a fraction of ETH** necessary for a Vanilla validator (2.3), **contribute to the 
  network decentralization** and **receive a Liquid staking token** to use in Defi applications.

Lido CSM
""""""""
First step is to take a look to CSM, what it is and what we can expect from it:

`LIDO-CSM`_

.. _LIDO-CSM: https://operatorportal.lido.fi/modules/community-staking-module?pk_vid=dfd844e8ac98a6ab1744384064237bde#block-4a646a8613264067b77ea0a309c1e7c3

We prepared the clients with the appropiate config to make it easier to run a Lido Validator, 
but it is important for you to take a look at the Lido Portal, particularly, the **"Intro"** and **"Quick Start sections"** and 
make sure you understand how it works.

.. warning::

  As of today (2Q 2025), **CSM has reached its stake share limit so your validator won't be activated until this limit is increased**. Stay 
  tuned with Lido updates. You can still upload keys, but they are very unlikely to receive deposits in the near 
  future (possibly for months).

Prerrequisites
""""""""""""""

- A Full/Archive **Ethereum node synced** with MEV support
- A **MEV server** compatible with Lido
- A Lido Community Staking Module **(CSM) Operator**
- At least 1 CSM **validator key**
- A running **Validator Client** with Lido configuration
- Ethereum on ARM :guilabel:`ls-lido` package

.. note::
  These are instructions for mainnet but **you can test the Lido setup on hoodi testnet** by starting the corresponding 
  services and accessing the CSM testnet portal. Refer to the bottom of this page for more details.

  **We strongly recommend first running the CSM Lido setup on the hoodi testnet.** 

Running a Full Ethereum node
""""""""""""""""""""""""""""

.. warning::

  Remember, this setup requires an ARM64 device with the Ethereum on ARM image already installed.

Let's make sure the :guilabel:`ls-lido` is installed. Run on your node:

.. prompt:: bash $

  sudo apt-get update && sudo apt-get install ls-lido

First step is to **run a Full/Archive Ethereum node** (Full node is enough). This is the same process as running a vanilla node, the 
only difference is that we need to enable :guilabel:`MEV Boost` in the beacon chain and start a :guilabel:`MEV Boost`
server compatible with Lido.

1. Choose a **Consensus Client** and an **Execution Client** and start both services. For instance:

.. prompt:: bash $

  sudo systemctl start nethermind
  sudo systemctl start lighthouse-beacon-mev

.. warning::

  Note that the Beacon Chain service includes the mev argument. Use it with any client, for instance 
  prysm-beacon-mev, teku-beacon-mev... This is necessary to enable MEV for running Lido.


2. Once start the MEV service:

.. prompt:: bash $

  sudo systemctl start mev-boost

Creating validator keys
"""""""""""""""""""""""

Time to create the validator keys that will be used by your client to stake.

**You will need at least 2.4 ETH for the first validator and 1.3 ETH for each Additional validator**. Depending on your available ETH 
(and how much you are willing to stake), you can calculate how many validator keys you can create.

You have 2 main options for creating the validator keys:

1. Use the **Wagyu key generator by Ethstaker** (which includes a GUI).  Go to:

https://wagyu.gg

Download the appropiate binary for your desktop and follow the instructions. 
**Remember to put here the Lido withdrawal address**: ``0xB9D7934878B5FB9610B3fE8A5e441e8fad7E293f``

.. warning::

  **Do not forget to include the Lido withdrawal address** as this is necessary to set up the Lido CMS properly. Additionally, 
  try to generate the keys offline by removing all network communications.

2. Use the command line deposit tool. 2 options here:

- You can do it directly in your node and run deposit tool command (it is already installed), as ``ethereum`` user, run:

.. prompt:: bash $

  deposit new-mnemonic --num_validators $YOUR_NUMBER_VALIDATORS --chain mainnet --eth1_withdrawal_address 0xB9D7934878B5FB9610B3fE8A5e441e8fad7E293f

A ``validator_keys`` folder will be created containing all necessary files. Here you will need to copy and paste the ``deposit_data`` 
file content to your desktop in order to submit this data to the CSM Lido portal.

- Download the deposit tool to your desktop and run it there. Same with folder and contents:

`ethstaker-deposit-cli`_

.. _ethstaker-deposit-cli: https://github.com/eth-educators/ethstaker-deposit-cli/releases

Follow the screen instructions in both cases and **make sure you write down the 12 words password**.

.. warning::

  **Make sure you write down the passphrase as this are your validators private keys and set the withdrawal address**.

Now, in any case, the tools will create two file types (a ``keystore(s)`` file(s) depending on the number of validators and a ``deposit_data`` file). 
The ``keystore(s)`` is/are for importing your validator keys in your Validator client. The ``deposit_data`` file is for uploading 
the keys into the CSM module and making the corresponding deposit.

For more info regarding validator keys generation visit this site:

`homestaker-validator-key-generation`_

.. _homestaker-validator-key-generation: https://dvt-homestaker.stakesaurus.com/keystore-generation-and-mev-boost/validator-key-generation

Importing the keys and starting the validator
"""""""""""""""""""""""""""""""""""""""""""""

.. note::
  Before going forward, we recommend to take a look at our section **"Running a Validator Client"** for more info 
  about importing the validator keys on each client:

`running-validator-client`_

.. _running-validator-client: https://ethereum-on-arm-documentation.readthedocs.io/en/latest/user-guide/running-l1-clients.html#running-validator-client

Once we have our private keys, we can import them into our validator client and start it.

You need to log into your node and run the import command, depending on your client. For instance:

.. prompt:: bash $

  lighthouse account validator import --directory=/home/ethereum/validator_keys

Note that we assume that the ``keystore`` and ``deposit_data`` files are in the ``/home/ethereum/validator_keys`` directory. If 
you generated the keys in your desktop, you will need to copy them into your node.

Now it is time to start the validator. Make sure you add the argument ``lido`` in the validator service, for instance:

.. prompt:: bash $

  sudo systemctl start lighthouse-validator-lido

.. warning::

  **Don't forget to add the lido argument as it contains the specific config for Lido CSM**.

Create and Activate the CSM operator
""""""""""""""""""""""""""""""""""""

Now it is time to visit the CSM Lido portal

https://csm.lido.fi

1. Clic in **"Become a Node Operator"**. Make sure you have at least **2.4** ETH. 

2. **Accept the terms** and **choose your wallet** that will create the Operator and make the deposit.

3. Clic **"Create node operator"**.

4. Now, paste the ``deposit_data`` file content into **"Upload deposit data"** form.

5. **Confirm** and clic **"Create Node Operator"**.

6. **Confirm the transaction** in your wallet.

Done, you are now running a CSM Lido Validator. Now, you need to wait for the Validator to get enabled. 

.. warning::

  Remember that, currently, CSM Lido has reached its stake share limit so it won't be activated unless this limits get increased.

Running CSM on Hoodi testnet
""""""""""""""""""""""""""""
Running CSM on ``hoodi`` is pretty much the same process but you need to make some adjustments.

1. For the full node, add the ``hoodi`` network on EL+CL client services, for instance:

.. prompt:: bash $

  sudo systemctl start nethermind-hoodi
  sudo systemctl start lighthouse-beacon-hoodi-mev

2. MEV boost service:

.. prompt:: bash $

  sudo systemctl start mev-boost-hoodi

3. Key generation. **Wagyu** tool supports ``hoodi`` so make sure you select this network.

Regarding ``deposit`` command line, replace ``mainnet`` for ``hoodi``. **Make sure to set this withdrawal 
address** in both cases to: ``0x4473dCDDbf77679A643BdB654dbd86D67F8d32f2``

.. warning::

  **Again, be careful, Lido withdrawal address for Hoodi is 0x4473dCDDbf77679A643BdB654dbd86D67F8d32f2**

4. Key import and validator start.

In both cases (command import and service start). You will need to add the ``hoodi`` flag to target the correct network. For instance:

.. prompt:: bash $

  lighthouse account validator --network hoodi import --directory=/home/ethereum/validator_keys
  sudo systemctl start lighthouse-validator-hoodi-lido

.. note::
  These are the commands for specifying the ``hoodi`` testnet in the validator clients:

.. prompt:: bash $

  Lighthouse: lighthouse account validator --network hoodi import --directory=/home/ethereum/validator_keys
  Prysm: validator accounts import --keys-dir=/home/ethereum/validator_keys --hoodi 
  Teku: No need to specify the network as keys are not imported directly
  Nimbus: nimbus_beacon_node deposits import /home/ethereum/validator_keys --data-dir=/home/ethereum/.nimbus-validator (no need to specify the network)

5. Lido Operator Portal for Hoodi is:

https://csm.testnet.fi

