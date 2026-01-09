Running Layer 1 nodes
=====================

In order to run an Ethereum node you will need to run 2 different clients at the same time: 
**one Consensus Layer Client (Beacon Chain) and one Execution Layer Client**.

.. important::
   Unless otherwise specified, all commands should be run under the ``ethereum`` user account.

Quick Navigation
----------------

- **Consensus Layer** - Learn about Beacon Chain clients and checkpoint sync → `Consensus Layer Nodes`_
- **Execution Layer** - Explore execution clients and sync strategies → `Execution Layer nodes`_
- **Staking** - Set up validators and start staking → `Staking`_
- **Client Comparison** - Compare sync times and client features → `Syncing Strategies and Times`_

Hardware Requirements
~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :align: left
   :header: Component, Minimum, Recommended

   RAM, 8 GB, 16 GB
   Storage, 2 TB SSD, 4 TB NVMe SSD
   Network, 10 Mbps, 25+ Mbps
   CPU, 4 cores ARM64, 8 cores ARM64

Getting Started
---------------

1. **Run and sync a Consensus Client (Beacon chain)** using Checkpoint sync (it syncs in a few minutes).
2. **Wait** for the Beacon Chain to get in sync.
3. **Run and sync an Execution Client**.

.. important::
   :guilabel:`Erigon` is the only Execution Layer client that includes a Light Consensus Layer Client (Caplin). You can 
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

**You need a synced Beacon Chain Client for the Execution Client sync to start. As we configured Checkpoint Sync by default in all clients, the Beacon Chain should be in sync in a few minutes.**

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

.. tab-set::

   .. tab-item:: All Clients

      .. csv-table::
         :header: Client, Official Binary, Language, Home

         `Lighthouse`, `Yes`, `Rust`, lighthouse-book.sigmaprime.io_
         `Prysm`, `Yes`, `Go`, docs.prylabs.network_
         `Nimbus`,`Yes`, `Nim`, nimbus.team_
         `Teku`, `Yes`, `Java`, consensys.net_
         `Lodestar`, `Yes`, `Typescript`, lodestar.chainsafe.io_
         `Grandine`, `Yes`, `Rust`, grandine.io_
         `Vouch`, `Yes`, `Go`, vouch.io_

   .. tab-item:: By Language

      **Rust-based:**
      
      - Lighthouse :bdg-success:`Production Ready`
      - Grandine :bdg-success:`Production Ready`
      
      **Go-based:**
      
      - Prysm :bdg-success:`Production Ready`
      - Vouch :bdg-success:`Production Ready` :bdg-info:`Multi-node`
      
      **Other Languages:**
      
      - Nimbus (Nim) :bdg-success:`Production Ready`
      - Teku (Java) :bdg-success:`Production Ready`
      - Lodestar (TypeScript) :bdg-success:`Production Ready`

.. _lighthouse-book.sigmaprime.io: https://lighthouse-book.sigmaprime.io
.. _docs.prylabs.network: https://docs.prylabs.network/docs/getting-started/
.. _nimbus.team: https://nimbus.team
.. _consensys.net: https://consensys.net/knowledge-base/ethereum-2/teku/
.. _lodestar.chainsafe.io: https://lodestar.chainsafe.io/
.. _grandine.io: https://grandine.io/
.. _vouch.io: https://vouch.io/


.. _lighthouse-beacon-setup:

Lighthouse :bdg-success:`Production Ready` :bdg-info:`Rust`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:guilabel:`Lighthouse` is a full CL client written in Rust.

.. csv-table::
   :align: left
  :header: Systemd Services, Home Directory, Config Files, Ports

  `lighthouse-beacon lighthouse-validator`, `/home/ethereum/.lighthouse`, `/etc/ethereum/lighthouse-beacon.conf /etc/ethereum/lighthouse-validator.conf`, `TCP/UDP: 9000`


1.- Port forwarding

You need to open the 9000 port in your router (both UDP and TCP)

2.- Start the beacon chain

Under the ethereum account, run:

.. prompt:: bash $

  sudo systemctl start lighthouse-beacon

The Lighthouse client will start to sync the Beacon Chain. **This may take just some minutes as Checkpoint sync 
is enabled by default.**

The Lighthouse beacon chain is now started. Wait for it to get in sync. Choose an Execution Layer client and start it.

.. _prysm-beacon-setup:

Prysm :bdg-success:`Production Ready` :bdg-info:`Go`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:guilabel:`Prysm` is a full Consensus Layer client written in Go.

.. csv-table::
   :align: left
  :header: Systemd Services, Home Directory, Config Files, Ports

  ``prysm-beacon prysm-validator``, ``/home/ethereum/.eth2``, ``/etc/ethereum/prysm-beacon.conf /etc/ethereum/prysm-validator.conf``, ``TCP: 13000, UDP: 12000``

1.- Port forwarding

You need to open the 13000 (TCP) and 12000 (UDP) ports in your router/firewall

2.- Start the beacon chain

Under the ethereum account, run:

.. prompt:: bash $

  sudo systemctl start prysm-beacon

This will start to sync the Beacon Chain. **This may take just some minutes as Checkpoint sync 
is enabled by default.**


The Prysm beacon chain is now started. Wait for it to get in sync. Choose an Execution Layer client and start it.

.. _teku-beacon-setup:

Teku :bdg-success:`Production Ready` :bdg-info:`Java`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:guilabel:`Teku` is a full Consensus Layer client written in Java.

.. csv-table::
   :align: left
  :header: Systemd Services, Home Directory, Config File, Ports

  `teku-beacon teku-validator`, `/home/ethereum/.teku/beacon /home/ethereum/.teku/validator`, `/etc/ethereum/teku-beacon.conf /etc/ethereum/teku-validator.conf`, `TCP/UDP: 9000`

1.- Port forwarding

You need to open the 9000 port (both UDP and TCP)

2.- Start the beacon chain

Under the ethereum account, run:

.. prompt:: bash $

  sudo systemctl start teku-beacon

The Teku beacon chain is now started. Wait for it to get in sync. Choose an Execution Layer client and start it.

.. _nimbus-beacon-setup:

Nimbus :bdg-success:`Production Ready` :bdg-info:`Nim`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. warning::

  From version 23.1.0, we upgraded :guilabel:`Nimbus` to run as 2 independent processes, 
  1 binary for the Beacon Chain and 1 binary for the validator (so 2 different services). 

  If you are using a prior release please upgrade and take into account that you need to 
  run 2 Systemd services.

  **You need to stop the nimbus service before upgrading to 23.1.0**
  
:guilabel:`Nimbus` is a full Consensus Layer client written in Nim.

.. csv-table::
   :align: left
  :header: Systemd Service, Home Directory, Config File, Ports

  `nimbus`, `/home/ethereum/.nimbus-beacon /home/ethereum/.nimbus-validator`, `/etc/ethereum/nimbus-beacon.conf /etc/ethereum/nimbus-validator.conf`, `TCP/UDP: 9000`

1.- Port forwarding

You need to open the 9000 port (both UDP and TCP)

2. Copy and paste your Ethereum Address for 
receiving tips and set the fee recipient flag:

.. prompt:: bash $

  sudo sed -i 's/changeme/0x1234567890abcdef1234567890abcdef12345678/' /etc/ethereum/nimbus-validator.conf

Replace ``0x1234567890abcdef1234567890abcdef12345678`` with your actual Ethereum address.

3. Enable Checkpoint Sync. 

We need to run a command manually before the **Checkpoint Sync** gets started:

.. prompt:: bash $

  nimbus_beacon_node trustedNodeSync --network=mainnet --data-dir=/home/ethereum/.nimbus-beacon --trusted-node-url=https://sync-mainnet.beaconcha.in --backfill=false

Wait for the command to finish.

4. Start the Nimbus Beacon Chain service:

.. prompt:: bash $

  sudo systemctl start nimbus-beacon

The Nimbus Beacon Chain is now started. Wait for it to get in sync. Choose an Execution Layer client and start it.

.. _lodestar-beacon-setup:

Lodestar :bdg-success:`Production Ready` :bdg-info:`TypeScript`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:guilabel:`Lodestar` is a full Consensus Layer client written in Type Script.

.. csv-table::
   :align: left
  :header: Systemd Services, Home Directory, Config File, Ports

  `lodestar-beacon lodestar-validator`, `/home/ethereum/.lodestar`, `/etc/ethereum/lodestar-beacon.conf /etc/ethereum/lodestar-validator.conf`, `TCP/UDP: 9000`

1.- Port forwarding

You need to open the 9000 port (both UDP and TCP)

2.- Start the beacon chain

Under the ethereum account, run:

.. prompt:: bash $

  sudo systemctl start lodestar-beacon

The Lodestar beacon chain is now started. Wait for it to get in sync. Choose an Execution Layer client and start it.

.. _grandine-beacon-setup:

Grandine :bdg-success:`Production Ready` :bdg-info:`Rust`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:guilabel:`Grandine` is a full Consensus Layer client written in Rust.

.. csv-table::
   :align: left
  :header: Systemd Services, Home Directory, Config Files, Ports

  `grandine-beacon grandine-validator`, `/home/ethereum/.grandine`, `/etc/ethereum/grandine-beacon.conf /etc/ethereum/grandine-validator.conf`, `TCP/UDP: 9000`

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

.. tab-set::

   .. tab-item:: All Clients

      .. csv-table:: Execution Layer Supported Clients
         :header: Client, Official Binary, Language, Home

         `Geth`, `Yes`, `Go`, geth.ethereum.org_
         `Nethermind`, `Yes`, `.NET`, nethermind.io_
         `Erigon`, `Yes`, `Go`, `github.com/ledgerwatch/erigon`_
         `Hyperledger Besu`, `Yes`, `Java`, hyperledger.org_
         `EthRex`, `Yes`, `Rust`, ethrex.io_
         `Reth`, `Yes`, `Rust`, paradigmxyz.github.io_

   .. tab-item:: By Sync Type

      **Snap Sync (Fast):**
      
      - Geth :bdg-success:`Production Ready` :bdg-info:`12-18h sync`
      - Nethermind :bdg-success:`Production Ready` :bdg-info:`12-18h sync`
      - Hyperledger Besu :bdg-success:`Production Ready` :bdg-info:`18-24h sync`
      - EthRex :bdg-warning:`Testing` :bdg-info:`12-18h sync`
      
      **Execution Sync (Slower, Archive-capable):**
      
      - Reth :bdg-success:`Production Ready` :bdg-info:`3-5 days sync`
      - Erigon :bdg-success:`Production Ready` :bdg-info:`4-6 days sync` :bdg-primary:`Built-in CL`


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
   :align: left
   :header: Client, Sync Type, Approx. Sync Time, Archive Node?
   :widths: 18, 20, 20, 15

   `Geth`, `Snap Sync`, `12–18 Hours`, `No (Full Pruned)`
   `Nethermind`, `Snap Sync`, `12–18 Hours`, `No (Full Pruned)`
   `Hyperledger Besu`, `Fast / Snap Sync`, `18–24 Hours`, `No (Full Pruned)`
   `Reth`, `Execution / Pipeline`, `3–5 Days`, `No (Full Pruned)`
   `Erigon`, `Execution / Staged`, `4–6 Days`, `No (Full Pruned)`
   `EthRex`, `Snap Sync`, `12–18 Hours`, `No (Full Pruned)`

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

.. _geth-setup:

Geth :bdg-success:`Production Ready` :bdg-info:`Go`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:guilabel:`Geth` is the most used EL client. It is developed by the Ethereum Foundation team
and the performance on ARM64 devices is outstanding. It is capable of syncing the whole blockchain 
in less than 1 day on a **Raspberry Pi 5 with 16 GB RAM** and in less that 1 day on the 
**Radxa Rock 5B**.

.. csv-table::
   :align: left
  :header: Systemd Service, Home Directory, Config File, Ports

  `geth`, `/home/ethereum/.geth`, `/etc/ethereum/geth.conf`, `TCP/UDP: 30303`

You can start the client by running:

.. prompt:: bash $

  sudo systemctl start geth

For further info of how the node is doing you can use Systemd journal:

.. prompt:: bash $

  sudo journalctl -u geth -f

.. _nethermind-setup:

Nethermind :bdg-success:`Production Ready` :bdg-info:`.NET`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:guilabel:`Nethermind` is a .NET enterprise-friendly full Execution Layer client.

.. csv-table::
   :align: left
  :header: Systemd Service, Home Directory, Config File, Ports

  `nethermind`, `/home/ethereum/.nethermind`, `/opt/nethermind/configs/mainnet.json`, `TCP/UDP: 30303`

In order to start the client run:

.. prompt:: bash $

  sudo systemctl start nethermind  

.. _besu-setup:

Hyperledger Besu :bdg-success:`Production Ready` :bdg-info:`Java`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :align: left
  :header: Systemd Service, Home Directory, Config File, Ports

  `besu`, `/home/ethereum/.besu`, `/etc/ethereum/besu.conf`, `TCP/UDP: 30303`

In order to start the client run:

.. prompt:: bash $

  sudo systemctl start besu

.. _ethrex-setup:

EthRex :bdg-warning:`Testing` :bdg-info:`Rust`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:guilabel:`EthRex` is a lightweight, performant, and modular Ethereum execution client powering next-gen L1 and L2 solutions.

.. csv-table::
   :align: left
  :header: Systemd Service, Home Directory, Config File, Ports

  `ethrex`, `/home/ethereum/.ethrex`, `/etc/ethereum/ethrex.conf`, `TCP/UDP: 30303`

In order to start the client run:

.. prompt:: bash $

  sudo systemctl start ethrex

.. note::
   :guilabel:`EthRex` is new in Ethereum on ARM ecosystem, and still under testing 

.. _reth-setup:

Reth :bdg-success:`Production Ready` :bdg-info:`Rust`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:guilabel:`Reth` (Rust Ethereum) is an Ethereum execution client implementation that focuses on friendliness, modularity, and speed.

.. csv-table::
   :align: left
  :header: Systemd Service, Home Directory, Config File, Ports

  `reth`, `/home/ethereum/.reth`, `/etc/ethereum/reth.conf`, `TCP/UDP: 30303`

In order to start the client run:

.. prompt:: bash $

  sudo systemctl start reth

.. dropdown:: Advanced: Full vs Archive Node Configuration
   :icon: gear

   By default, :guilabel:`Reth` runs as an **Archive Node**, storing all historical states. This requires significantly more disk space.

   If you wish to run a **Full Node** (pruned state) to save disk space, you must enable the full node mode.

   To do this, edit the configuration file for your network (e.g., ``/etc/ethereum/reth.conf`` for Mainnet) and add the ``--full`` flag to the ``ARGS`` variable.

   Example:

   .. code-block:: bash

      ARGS="node ... --full"

   After saving the file, restart the service:

   .. prompt:: bash $

     sudo systemctl restart reth

.. _erigon-setup:

Erigon :bdg-success:`Production Ready` :bdg-info:`Go` :bdg-primary:`Built-in CL`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :align: left
  :header: Systemd Service, Home Directory, Config File, Ports

  `erigon`, `/home/ethereum/.erigon`, `/etc/ethereum/erigon.conf`, `TCP/UDP: 30303`

.. note::
   **Erigon Setup Options**
   
   Erigon 3 includes **Caplin**, its own consensus layer. Choose your setup:
   
   **🎯 Simple Setup (Recommended)**
   
   - Use built-in Caplin consensus layer
   - **Service:** ``erigon``
   - **Use when:** Running a full node without external CL client
   - **Advantages:** Single service, simpler configuration
   
   **🔧 Advanced Setup**
   
   - Use external consensus layer client
   - **Service:** ``erigon-externalcl``
   - **Use when:** You need compatibility with external CL clients
   - **Advantages:** More flexibility, can use any CL client

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

Staking Workflow
~~~~~~~~~~~~~~~~

The staking process follows these steps:

1. **🔑 Generate Keys** - Use ethstaker-deposit-cli to create validator keys
2. **💰 Deposit 32 ETH** - Submit deposit via Ethereum Launchpad
3. **📥 Import Keys** - Import keys to your validator client
4. **▶️ Start Validator** - Enable and monitor validator service

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

The community provides a tool (ethstaker-deposit-cli) to create the keys and the 
deposit information (which among others contains your validator(s) public key(s)). This 
tool is already installed in your Ethereum on ARM node. If you are running an older image 
please, run:

.. prompt:: bash $

  sudo apt-get update
  sudo apt-get install ethstaker-deposit-cli

.. warning::
   **Important: Tool Update**
   
   The original ``staking-deposit-cli`` from the Ethereum Foundation has been **deprecated**. 
   The official repository now recommends using ``ethstaker-deposit-cli``, which is an 
   actively maintained fork by the ETHStaker community. 
   
   See: `ethstaker-deposit-cli <https://github.com/eth-educators/ethstaker-deposit-cli>`_

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

6. Ethereum on ARM provides the ethstaker-deposit-cli tool to generate the keys and 
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

.. _running-validator-client-internal-alt:

Running Validator Client
~~~~~~~~~~~~~~~~~~~~~~~~

Once the Beacon Chain is synchronized and we have our keys and deposit created, we need to start the Validator Client. 
Choose the tab for the client you are using:

.. tab-set::

   .. tab-item:: Lighthouse

      Import the previously generated validator keys:

      .. prompt:: bash $

        lighthouse account validator import --directory=/home/ethereum/validator_keys

      Enter your password when prompted. Then set the fee recipient address:

      .. prompt:: bash $

        sudo sed -i 's/changeme/0x1234567890abcdef1234567890abcdef12345678/' /etc/ethereum/lighthouse-validator.conf

      Replace ``0x1234567890abcdef1234567890abcdef12345678`` with your actual Ethereum address.

      Start the validator service:

      .. prompt:: bash $

        sudo systemctl start lighthouse-validator

      The Lighthouse Validator is now started.

   .. tab-item:: Prysm

      Import the validator keys:

      .. prompt:: bash $

        validator accounts import --keys-dir=/home/ethereum/validator_keys

      Accept the default wallet path and enter a password for your wallet, then enter the password you defined earlier.

      Set the fee recipient address:

      .. prompt:: bash $

        sudo sed -i 's/changeme/0x1234567890abcdef1234567890abcdef12345678/' /etc/ethereum/prysm-validator.conf

      Replace ``0x1234567890abcdef1234567890abcdef12345678`` with your actual Ethereum address.

      Set up your password file and start the validator:

      .. prompt:: bash $

        echo "$YOUR_PASSWORD" > /home/ethereum/validator_keys/prysm-password.txt
        sudo systemctl start prysm-validator

      The Prysm validator is now enabled.

   .. tab-item:: Nimbus

      Import your validator keys:

      .. prompt:: bash $

        nimbus_beacon_node deposits import /home/ethereum/validator_keys --data-dir=/home/ethereum/.nimbus-validator --log-file=/home/ethereum/.nimbus-validator/nimbus.log

      Enter the password you defined earlier.

      Set the fee recipient address:

      .. prompt:: bash $

        sudo sed -i 's/changeme/0x1234567890abcdef1234567890abcdef12345678/' /etc/ethereum/nimbus-validator.conf

      Replace ``0x1234567890abcdef1234567890abcdef12345678`` with your actual Ethereum address.

      Start the Nimbus Validator:

      .. prompt:: bash $

        sudo systemctl start nimbus-validator

   .. tab-item:: Teku

      Create a password file for each validator keystore. The file must have the same name as the keystore with a ``.txt`` extension.

      View your keystore files:

      .. prompt:: bash $

        ls /home/ethereum/validator_keys

      Create password file (replace ``$KEYSTORE_NAME`` with your actual keystore filename):

      .. prompt:: bash $

        echo "$YOUR_PASSWORD" > validator_keys/$KEYSTORE_NAME.txt

      You should now have matching files like:

      .. code-block:: text

        keystore-m_12381_3600_0_0_0-1661710189.json
        keystore-m_12381_3600_0_0_0-1661710189.txt

      Set the fee recipient address:

      .. prompt:: bash $

        sudo sed -i 's/changeme/0x1234567890abcdef1234567890abcdef12345678/' /etc/ethereum/teku-validator.conf

      Replace ``0x1234567890abcdef1234567890abcdef12345678`` with your actual Ethereum address.

      Start the Teku Validator:

      .. prompt:: bash $

        sudo systemctl start teku-validator

      The Teku Validator is now enabled.

   .. tab-item:: Lodestar

      Import the validator keys:

      .. prompt:: bash $

        lodestar validator import --importKeystores /home/ethereum/validator_keys --dataDir /home/ethereum/.lodestar

      Enter the password you defined earlier.

      Set the fee recipient address:

      .. prompt:: bash $

        sudo sed -i 's/changeme/0x1234567890abcdef1234567890abcdef12345678/' /etc/ethereum/lodestar-validator.conf

      Replace ``0x1234567890abcdef1234567890abcdef12345678`` with your actual Ethereum address.

      Start the Lodestar Validator service:

      .. prompt:: bash $

        sudo systemctl start lodestar-validator

   .. tab-item:: Grandine

      .. warning::

        Make sure you are NOT running the **grandine-beacon** service before starting **grandine-validator**

      Set the fee recipient address:

      .. prompt:: bash $

        sudo sed -i 's/changeme/0x1234567890abcdef1234567890abcdef12345678/' /etc/ethereum/grandine-validator.conf

      Replace ``0x1234567890abcdef1234567890abcdef12345678`` with your actual Ethereum address.

      Set up your password file and start the validator:

      .. prompt:: bash $

        echo "$YOUR_PASSWORD" > /home/ethereum/validator_keys/grandine-password.txt
        sudo systemctl start grandine-validator

      The Grandine validator is now enabled. Wait for the Beacon Chain to sync and check the logs for further info.

   .. tab-item:: Vouch

      :guilabel:`Vouch` is a multi-node validator client written in Go.

      .. csv-table::
        :header: Systemd Services, Home Directory, Config Files, Ports

        `vouch`, `/home/ethereum/.vouch`, `/etc/ethereum/vouch.yml`, `None`

      Edit the configuration file to add your Beacon Node endpoint(s):

      .. prompt:: bash $

        sudo nano /etc/ethereum/vouch.yml

      Add your beacon node endpoints in the ``beacon-node-address`` list.

      Import the validator keys:

      .. prompt:: bash $

        /usr/local/bin/vouch account import --base-dir=/home/ethereum/.vouch --keys-dir=/home/ethereum/validator_keys

      Enter the password you defined earlier.

      Set the fee recipient in the config file:

      .. prompt:: bash $

        sudo nano /etc/ethereum/vouch.yml

      Set the ``fee-recipient`` field:

      .. code-block:: yaml

        fee-recipient: "0x1234567890abcdef1234567890abcdef12345678"

      Replace with your actual Ethereum address.

      Start the Vouch service:

      .. prompt:: bash $

        sudo systemctl start vouch

      The Vouch validator is now enabled. Check the logs for further info.

Troubleshooting
---------------

.. dropdown:: My beacon chain won't sync
   :icon: question

   **Possible causes:**
   
   - Checkpoint sync endpoint is down
   - Firewall blocking ports
   - Insufficient peers
   
   **Solutions:**
   
   - Check logs: ``sudo journalctl -u [service-name] -f``
   - Verify port forwarding is configured correctly
   - Try alternative checkpoint sync endpoint
   - Ensure system time is synchronized

.. dropdown:: Execution client stuck at "Waiting for beacon node"
   :icon: question

   **Cause:** Beacon chain is not synced yet
   
   **Solution:** Wait for beacon chain to complete checkpoint sync (usually 5-10 minutes). Check beacon chain logs to verify it's syncing.

.. dropdown:: Validator not attesting
   :icon: question

   **Possible causes:**
   
   - Validator keys not imported correctly
   - Fee recipient not set
   - Beacon chain not connected to execution client
   
   **Solutions:**
   
   - Verify keys are imported: check validator client logs
   - Confirm fee recipient is set in config file
   - Ensure both beacon chain and execution client are running and synced
   - Check JWT token is correctly configured

.. dropdown:: High memory usage
   :icon: question

   **Cause:** Some clients require significant RAM, especially during initial sync
   
   **Solutions:**
   
   - Ensure you meet minimum hardware requirements (16GB RAM recommended)
   - Consider using a lighter client combination
   - Monitor with: ``htop`` or ``free -h``
   - Restart services if memory leak suspected

.. dropdown:: Disk space running out
   :icon: question

   **Solutions:**
   
   - Check current usage: ``df -h``
   - For Reth: enable full node mode (pruned) instead of archive
   - Ensure you have at least 2TB SSD (4TB recommended)
   - Monitor growth rate and plan upgrades accordingly

