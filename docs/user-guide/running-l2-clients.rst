Running Layer 2 nodes
=====================

You can choose several Layer 2 solutions to run an Ethereum L2 node:

* Fuel_
* Polygon_
* Arbitrum_
* Optimism_
* Starknet_
* Gnosis_
* Ethrex_

.. _Fuel: https://fuel.network/
.. _Polygon: https://polygon.technology/
.. _Arbitrum: https://arbitrum.io/
.. _Optimism: https://www.optimism.io/
.. _Starknet: https://www.starknet.io/
.. _Gnosis: https://www.gnosis.io/
.. _EthRex: https://ethrex.xyz

As explained in the Node Types section there are various L2 technologies to 
scale the Ethereum blockchain and lower the transaction fees.

It is important to keep both L1 and L2 nodes as decentralized as possible and that basically 
means run nodes.

.. note::
  If you have an Ethereum on ARM image installed prior to June 2023 you need to install the clients manually. Otherwise 
  you can skip this step

.. prompt:: bash $

  sudo apt-get update
  sudo apt-get install polygon-bor polygon-heimdall arbitrum-nitro starknet-juno
  optimism-op-geth optimism-op-node fuel-network


Fuel Network
------------

**Fuel Network** is a modular execution layer designed to provide high-performance, scalable smart 
contract execution for blockchain applications. It leverages advanced technologies like optimistic rollups 
and UTXO-based design to achieve low fees, fast transactions, and secure interoperability 
with Ethereum.

In order to run a Fuel node you need to:

1. Run and sync and Ethereum mainnet node
2. Install the fuel-network package
3. Start the Fuel Systemd Service

1. Sync an Ethereum node.

You can choose from any Consensus and Execution clients available. See our section "Running L1 Clients" 

.. note::
  The **Fuel** package **is configured to run with a local L1 node running and synced**. So first, you need to run and sync an Ethereum Node.
  In case you want to run a Fuel node alone you need to configure the flag ``--relayer`` in ``/etc/ethereum/fuel/fuel.conf`` file.

2. Installation

 Run the apt command:

 .. prompt:: bash $

  sudo apt-get update && sudo apt-get install fuel-network

3. Start the :guilabel:`Fuel Core` Service

 .. prompt:: bash $

  sudo systemctl start fuel

You can check out the logs by running:

 .. prompt:: bash $

  sudo journalctl -u fuel -f


Ethrex
------

Ethrex is a minimalist, modular, and high-performance implementation of the Ethereum protocol developed by LambdaClass. 
It supports both Layer 1 and Layer 2 operation modes, enabling developers and node operators to deploy their own rollups, 
sequencers, and provers on affordable ARM hardware.

Ethrex L2 focuses on simplicity and speed while maintaining full compatibility with the Ethereum stack, offering native 
support for snap-sync, metrics, auth-RPC, and proof coordination.

In order to run an Ethrex L2 node you need to:

1. Run and sync an Ethereum mainnet or testnet node
2. Install the ethrex-l2 package
3. Start the Ethrex L2 Sequencer and Prover systemd services


1. Sync an Ethereum L1 node.


As with all rollups, an Ethrex L2 node requires access to a synced Ethereum Layer 1 node (Execution + Consensus). 
You can run any L1 combination available in the Running L1 Clients section — for example Geth + Nimbus or Ethrex + Prysm.

.. note::
   The Ethrex L2 client is configured by default to connect to a local L1 node through the HTTP RPC and Beacon API.
   If your L1 node runs on a different machine, update its IP and ports in /etc/ethereum/ethrex-l2.conf.


2. Installation


Install the ethrex-l2 package from the Ethereum on ARM repositories:

.. prompt:: bash $

   sudo apt-get update && sudo apt-get install ethrex-l2

This package installs:

- The Ethrex L2 binary (/usr/bin/ethrex-l2)
- Two systemd services:
  - ethrex-l2.service → Sequencer
  - ethrex-l2-prover.service → Prover
- Default configuration files under /etc/ethereum/:
  - /etc/ethereum/ethrex-l2.conf
  - /etc/ethereum/ethrex-l2-prover.conf


3. Configure


Edit /etc/ethereum/ethrex-l2.conf and make sure the following parameters are correctly set:

.. code-block:: bash

   --eth.rpc-url https://sepolia.infura.io/v3/<YOUR_INFURA_KEY>
   --l1.on-chain-proposer-address 0x1111111111111111111111111111111111111111
   --l1.bridge-address 0x2222222222222222222222222222222222222222
   --committer.l1-private-key 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
   --proof-coordinator.l1-private-key 0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
   --block-producer.coinbase-address 0x3333333333333333333333333333333333333333
   --http.addr 0.0.0.0
   --http.port 1729
   --metrics
   --metrics.port 9092
   --datadir /home/ethereum/.ethrex-l2

4. Start the Sequencer

Once configured, start the Ethrex L2 Sequencer service:

.. prompt:: bash $

   sudo systemctl start ethrex-l2
   sudo journalctl -u ethrex-l2 -f

Example output:

.. code-block:: text

   INFO ethrex_l2::sequencer: Connected to L1 RPC https://sepolia.infura.io/v3/...
   INFO ethrex_l2::p2p: Connected peers: 45
   INFO ethrex_l2::commit: New batch committed to L1 block #XXXXXXX
   INFO ethrex_l2::sequencer: Block 0xabc123… produced (gas_used=8,100,000)


5. Start the Prover

The Ethrex L2 Prover generates and submits validity proofs for each batch committed by the sequencer.

.. prompt:: bash $

   sudo systemctl start ethrex-l2-prover
   sudo journalctl -u ethrex-l2-prover -f

By default it connects to the local proof coordinator (tcp://127.0.0.1:3900) and uses the exec backend. 
For production, you can switch to SP1 or RISC0 backends in /etc/ethereum/ethrex-l2-prover.conf.


6. Verify that everything is running

Check the sequencer RPC:

.. prompt:: bash $

   curl http://localhost:1729 \
        -H 'content-type: application/json' \
        -d '{"jsonrpc":"2.0","method":"eth_blockNumber","id":"1","params":[]}'

Expected result:

.. code-block:: json

   {"id":"1","jsonrpc":"2.0","result":"0x5"}

The value should increase every few seconds as new L2 blocks are produced.


7. Manage services

.. prompt:: bash $

   sudo systemctl stop ethrex-l2
   sudo systemctl stop ethrex-l2-prover
   sudo systemctl enable ethrex-l2 ethrex-l2-prover
   sudo journalctl -u ethrex-l2* -f


Notes

- Default JWT secret path: /etc/ethereum/jwtsecret
- Validium mode (no state diffs on L1): add --validium in /etc/ethereum/ethrex-l2.conf
- Both services use the ethereum user
- Data stored at /home/ethereum/.ethrex-l2/


Quick start

.. prompt:: bash $

   sudo apt-get update && sudo apt-get install ethrex-l2
   sudo systemctl start ethrex-l2
   sudo systemctl start ethrex-l2-prover
   curl http://localhost:1729 -H 'content-type: application/json' \
        -d '{"jsonrpc":"2.0","method":"eth_blockNumber","id":"1","params":[]}'


Congrats, your Ethrex L2 Sequencer and Prover are now running on your Ethereum on ARM device.

Polygon
-------

Polygon is a L2 scaling solution for the Ethereum blockchain that provides faster and more cost-effective 
transactions by using a combination of sidechains and a proof-of-stake consensus mechanism.

.. note::
  Polygon requires a 4 TB disk to work properly.

  We will sync Polygon using Snapshots for both clients. Take into account that the :guilabel:`Bor` snapshot is huge 
  so it will take more than 10 hours to download and 5 hours to decompress (:guilabel:`Heimdall` is smaller but it will
  take a significant amount of time as well)

In order to run a Polygon node you need to:

1. Download :guilabel:`Bor` Snapshot
2. Decompress and remove the snapshot
3. Download :guilabel:`Heimdall` Snapshot
4. Decompress and remove the snapshot
5. Start and sync the :guilabel:`Heimdall` client
6. Start and sync the :guilabel:`Bor` client

Snapshots
~~~~~~~~~

We included 2 scripts that download and decompress the Polygon Snapshots automatically (for both :guilabel:`Heimdall` and 
:guilabel:`Bor` clients). The recommended steps are as follows:

Run the ``screen`` utility in order to make sure the process continues to run even if you are 
disconnected from the console (this is particularly useful if you are accessing through SSH):

.. prompt:: bash $

  screen

.. note::
  Press ``CONTROL+A  D`` to deattach the console and run the command ``screen -r`` to attach the console again

Once inside screen, run the download script as the ``ethereum`` user:

.. prompt:: bash $

  bor-snapshot

This will download the :guilabel:`Bor` snapshot. Once downloaded, it will be decompressed into the 
correct directory and removed from disk.

Run the :guilabel:`Heimdall` snapshot script:

.. prompt:: bash $

  heimdall-snapshot

This will download the :guilabel:`Heimdall` snapshot. Once downloaded it will be decompressed into the 
correct directory and removed from disk.

Clients
~~~~~~~

Start the :guilabel:`Heimdall` service and check the logs:

.. prompt:: bash $

  systemctl start bor
  journalctl -u bor -f

.. note::
  The order is importante. Please run :guilabel:`Heimdall` first, wait for it to get 
  in sync and start :guilabel:`Bor` afterwards.

Once synced start the :guilabel:`Bor` service and, again, check the logs

.. prompt:: bash $

  systemctl start heimdalld
  journalctl -u heimdalld -f

Congrats, you are running a Polygon node.

Arbitrum
--------

**Arbitrum** uses a technology called Optimistic Rollups to bundle multiple transactions into a single proof 
that is submitted to the Ethereum mainnet (Layer 1). By moving much of the transaction processing and 
computation off-chain, Arbitrum reduces congestion and gas fees on the Ethereum network, 
while maintaining a high level of security and decentralization.

The Arbitrum :guilabel:`Nitro` client is available.

.. note::
  You need a L1 node to connect to in order to run an Arbitrum node.

First step is to set the IP for your L1 Ethereum node:

.. prompt:: bash $

  sudo sed -i "s/setip/YOUR_IP/" /etc/ethereum/nitro.conf

For example:

.. prompt:: bash $

  sudo sed -i "s/setip/192.168.0.10/" /etc/ethereum/nitro.conf

We need to download and decompress the initial snapshot in order to initialize the database. Run:

.. prompt:: bash $

  nitro-snapshot

Once finished, start the :guilabel:`Nitro` client service and wait for the client to get in sync:

.. prompt:: bash $

  sudo systemctl start nitro
  sudo journalctl -u nitro -f

The Arbitrum node is up and running.

Starknet
--------

StarkNet is a Layer 2 scaling solution for the Ethereum blockchain, designed to improve scalability, 
transaction throughput, and efficiency using a technology called Zero-Knowledge (ZK) Rollups.  
This approach allows StarkNet to bundle multiple transactions together, process them off-chain, and 
then submit a proof of their validity to the Ethereum mainnet (Layer 1). 

There are 2 available clients for the Starknet Network: :guilabel:`Juno` and :guilabel:`Papyrus`. 
:guilabel:`Papyrus` is currently on Alpha so we will run :guilabel:`Juno`

You can start the client just by running the systemd service:

.. prompt:: bash $

  sudo systemctl start juno
  sudo journalctl -u juno -f

Gnosis
------

Gnosis Chain, formerly xDai, is an Ethereum-compatible sidechain that serves as a Layer 2 
scaling solution and provides a more efficient environment for Gnosis applications and other 
Ethereum-based projects.

:guilabel:`Gnosis` is already implemented in some Layer 1 clients so we can use the same client binaries but 
with different configurations.

Like the Layer 1 clients you need to run a Consensus Layer node and an Execution Layer client. Layer 1 
clients :guilabel:`Nethermind`, :guilabel:`Erigon` and :guilabel:`Lighthouse` are already configured to run a Gnosis chain node so we just need to start 
the Systemd services:

.. prompt:: bash $

  sudo systemctl start lighthouse-beacon-gnosis
  sudo journalctl -u lighthouse-beacon-gnosis -f

For the execution client one can either use :guilabel:`Nethermind` or :guilabel:`Erigon`. 
To use :guilabel:`Nethermind`:

.. prompt:: bash $

  sudo systemctl start nethermind-gnosis
  sudo journalctl -u nethermind-gnosis -f

To use :guilabel:`Erigon` instead of :guilabel:`Nethermind`:

.. prompt:: bash $

  sudo systemctl start erigon-gnosis
  sudo journalctl -u erigon-gnosis -f

Remember to forward the default ports: `9000` and `30303`

Optimism
--------

Optimism is a Layer 2 scaling solution for Ethereum that increases the network's scalability by leveraging a 
technology called Optimistic Rollups.

Optimism aims to address Ethereum's high gas costs and slow transaction speeds by moving most transactions off 
the Ethereum mainnet while still maintaining a high level of security.

Official Clients
~~~~~~~~~~~~~~~~

.. note::

  You need access to a synced Ethereum L1 node.

Let's set the Execution and Consensus APIs:

Set the synced IP L1 ethereum node (localhost if this is a super Node):

.. prompt:: bash $

  sudo sed -i "s/l1ip/$YOUR_IP/" /etc/ethereum/op-node.conf

For example:

.. prompt:: bash $

  sudo sed -i "s/l1ip/192.168.0.10/" /etc/ethereum/op-node.conf

Now, set the L1 Beacon API (again, localhost if this is a Super Node)

.. prompt:: bash $

  sudo sed -i "s/l1beaconip/$YOUR_IP/" /etc/ethereum/op-node.conf

Start the :guilabel:`Op-Geth` service and check the logs:

.. prompt:: bash $

  systemctl start op-geth
  sudo journalctl -u op-geth -f

.. note::
  The order is important. Please run :guilabel:`Op-Geth` first.

Now, start the :guilabel:`Op-Node` client:

.. prompt:: bash $

  systemctl start op-node
  sudo journalctl -u op-node -f

Congrats, you are now running an Optimism node.

Nethermind Execution Client 
~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can use the :guilabel:`Nethermind` Execution Layer implementation along with :guilabel:`Op-Node` client.

Same process than above but we switch the :guilabel:`Op-Geth` service for :guilabel:`Nethermind Optimism`

Start the :guilabel:`Nethermind Optimism` service and check the logs:

.. prompt:: bash $

  systemctl start nethermind-op

Check the logs:

.. prompt:: bash $

  sudo journalctl -u nethermind-op -f

And start the :guilabel:`Op-Node` service:

.. prompt:: bash $

  systemctl start op-node
  sudo journalctl -u op-node -f

Base
----

Base, developed by Coinbase, is a new Layer-Two (L2) blockchain built on Optimism, aimed at scaling Ethereum.
 
While initially centralized in block production, plans to leverage Optimism's "superchain" concept, 
enhancing interoperability and reducing transaction fees.

For running a Base node, follow the above instructions for **Optimism** and replace both, the **Systemd** services 
and the **config files** as follows:

- Systemd services: ``nethermind-base`` and ``op-node-base``
- Config files: ``/etc/ethereum/nethermind-base.conf`` and ``/etc/ethereum/op-node-base.conf``

Currently (August 2025), we recommend **Nethermind Base** implementation as execution engine instead of **Optimism**
so you can sync in snap sync mode (much easier and faster). So, follow the **Nethermind** section instructions and 
replace ``nethermind-op`` for ``nethermind-base``.