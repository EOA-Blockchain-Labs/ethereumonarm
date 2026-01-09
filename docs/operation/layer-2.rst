Running Layer 2 nodes
=====================

As explained in the Node Types section there are various L2 technologies to 
scale the Ethereum blockchain and lower the transaction fees.

It is important to keep both L1 and L2 nodes as decentralized as possible and that basically 
means run nodes.

.. important::
   Unless otherwise specified, all commands should be run under the ``ethereum`` user account.

Quick Navigation
----------------

- **Fuel Network** - Modular execution layer with optimistic rollups (see fuel-network_)
- **Arbitrum** - Optimistic rollup with high throughput (see arbitrum_)
- **Optimism** - Optimistic rollup scaling solution (see optimism_)
- **Starknet** - ZK-rollup with validity proofs (see starknet_)
- **EthRex L2** - Minimalist Rust-based L2 (see ethrex-l2_)

Hardware Requirements
~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :align: left
   :header: L2 Solution, Minimum Storage, Recommended Storage, Special Notes

   Fuel Network, 500 GB, 1 TB, Requires synced L1 node
   Arbitrum, 1 TB, 2 TB, Requires L1 node access
   Optimism/Base, 1 TB, 2 TB, Requires L1 node access
   Starknet, 500 GB, 1 TB, Standalone operation
   EthRex L2, 500 GB, 1 TB, Requires L1 node access

.. note::
  If you have an Ethereum on ARM image installed prior to June 2023 you need to install the clients manually. Otherwise 
  you can skip this step

.. prompt:: bash $

  sudo apt-get update
  sudo apt-get install arbitrum-nitro starknet-juno optimism-op-geth optimism-op-node fuel-network


.. _fuel-network:

Fuel Network :bdg-success:`Production Ready` :bdg-info:`Rust`
-------------------------------------------------------------

**Official Site:** https://fuel.network/

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

.. _ethrex-l2:

EthRex L2 :bdg-danger:`Alpha` :bdg-info:`Rust`
----------------------------------------------

**Official Site:** https://github.com/lambdaclass/ethrex

**EthRex** is a minimalist, modular execution layer written in Rust. It is designed to be highly 
performant and easy to modify.

1. Installation

Run the apt command:

.. prompt:: bash $

  sudo apt-get update && sudo apt-get install ethrex-l2

2. Configuration

The main configuration file is located at ``/etc/ethereum/ethrex-l2.conf``.
You should edit this file to configure your L1 connection and other parameters:

.. code-block:: bash

   ARG="--eth.rpc-url https://sepolia.infura.io/v3/<YOUR_INFURA_KEY>
   --l1.on-chain-proposer-address 0x1111111111111111111111111111111111111111
   --l1.bridge-address 0x2222222222222222222222222222222222222222
   --committer.l1-private-key 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
   --proof-coordinator.l1-private-key 0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
   --block-producer.coinbase-address 0x3333333333333333333333333333333333333333
   --http.addr 0.0.0.0
   --http.port 1729
   --metrics
   --metrics.port 9092
   --datadir /home/ethereum/.ethrex-l2"

3. Setup Note

Ensure you have a valid L1 RPC URL (Sepolia is used in this example) and the correct contract addresses.


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


.. _arbitrum:

Arbitrum :bdg-success:`Production Ready` :bdg-info:`Go`
-------------------------------------------------------

**Official Site:** https://arbitrum.io/

**Arbitrum** uses a technology called Optimistic Rollups to bundle multiple transactions into a single proof 
that is submitted to the Ethereum mainnet (Layer 1). By moving much of the transaction processing and 
computation off-chain, Arbitrum reduces congestion and gas fees on the Ethereum network, 
while maintaining a high level of security and decentralization.

The Arbitrum :guilabel:`Nitro` client is available.

.. note::
  You need a L1 node to connect to in order to run an Arbitrum node.

First step is to set the IP for your L1 Ethereum node:

.. prompt:: bash $

  sudo sed -i "s/setip/192.168.0.10/" /etc/ethereum/nitro.conf

Replace ``192.168.0.10`` with your actual L1 node IP address.

We need to download and decompress the initial snapshot in order to initialize the database. Run:

.. prompt:: bash $

  nitro-snapshot

Once finished, start the :guilabel:`Nitro` client service and wait for the client to get in sync:

.. prompt:: bash $

  sudo systemctl start nitro
  sudo journalctl -u nitro -f

The Arbitrum node is up and running.

.. _starknet:

Starknet :bdg-success:`Production Ready` :bdg-info:`Rust`
---------------------------------------------------------

**Official Site:** https://www.starknet.io/

StarkNet is a Layer 2 scaling solution for the Ethereum blockchain, designed to improve scalability, 
transaction throughput, and efficiency using a technology called Zero-Knowledge (ZK) Rollups.  
This approach allows StarkNet to bundle multiple transactions together, process them off-chain, and 
then submit a proof of their validity to the Ethereum mainnet (Layer 1).

Available Clients
~~~~~~~~~~~~~~~~~

There are 2 production-ready clients available for running a Starknet node:

**Juno** - Golang implementation
  A full Starknet node implementation written in Go by Nethermind. Juno is known for its stability, 
  performance, and lower resource requirements. It's the recommended choice for most users.

**Madara** - Substrate-based sequencer
  A high-performance Starknet sequencer built on Substrate framework by the Madara Alliance. 
  Madara is designed for advanced use cases and can be configured as both a full node and a sequencer.

Juno
~~~~

:guilabel:`Juno` is a Golang Starknet full-node implementation by Nethermind.

**Features:**
- Full node synchronization
- Lower resource requirements
- Stable and well-tested
- Active development and support

**Installation and Setup:**

Start the Juno client:

.. prompt:: bash $

  sudo systemctl start juno
  sudo journalctl -u juno -f

Juno will sync with the Starknet network and provide RPC access once synchronized.

Madara
~~~~~~

:guilabel:`Madara` is a high-performance Starknet sequencer built on Substrate.

**Features:**
- Substrate-based architecture
- Can run as full node or sequencer
- High performance and scalability
- Modular design for customization

**Installation and Setup:**

Start the Madara client:

.. prompt:: bash $

  sudo systemctl start madara
  sudo journalctl -u madara -f

Configuration
^^^^^^^^^^^^^

The default configuration file is located at ``/etc/ethereum/madara.conf``. You can edit this file to change the default parameters.

.. code-block:: bash

  # /etc/ethereum/madara.conf
  MADARA_OPTS="--base-path /var/lib/madara --rpc-port 9944"

After changing the configuration, restart the service:

.. prompt:: bash $

  sudo systemctl restart madara

Client Comparison
~~~~~~~~~~~~~~~~~

.. csv-table::
   :align: left
   :header: Feature, Juno, Madara

   Language, Go, Rust (Substrate)
   Resource Usage, Lower, Moderate
   Use Case, Full node, Full node / Sequencer
   Maturity, Stable, Production Ready
   Recommended For, Most users, Advanced setups

.. _optimism:

Optimism / Base :bdg-success:`Production Ready` :bdg-info:`Go`
--------------------------------------------------------------

**Official Sites:** https://www.optimism.io/ | https://base.org/

Optimism is a Layer 2 scaling solution for Ethereum that uses Optimistic Rollups to increase scalability. 
**Base** (developed by Coinbase) is built on the same Optimism stack.

Architecture
~~~~~~~~~~~~

An Optimism/Base node consists of two components:

1. **Execution Client** - Processes transactions (op-geth or op-reth)
2. **Consensus Client** - Op-Node (rollup node that derives L2 chain from L1)

.. important::
   You need access to a **synced Ethereum L1 node** (both Execution and Consensus layers).

Quick Start
~~~~~~~~~~~

**Installation:**

.. prompt:: bash $

  sudo apt-get update
  sudo apt-get install optimism-op-geth optimism-op-node

**Configure L1 connection** in ``/etc/ethereum/op-node.conf``:

.. code-block:: bash

  ARGS="--l1=http://YOUR_L1_IP:8545 \
      --l1.beacon=http://YOUR_L1_IP:5052 \
      ..."

**Start the services:**

.. prompt:: bash $

  sudo systemctl start op-geth
  sudo systemctl start op-node

.. seealso::
   
   **Complete Setup Guide**
   
   For detailed instructions including hardware requirements, all client options (Op-Geth, Op-Reth), 
   Base configuration, and running a full Supernode (L1+L2 on same hardware), see:
   
   - :doc:`Running an Optimism Supernode <optimism/supernode>` - Comprehensive 32GB RAM setup
   - :doc:`Running a Guardian Node (Challenger) <optimism/challenger>` - Secure the network

Troubleshooting
---------------

.. dropdown:: L2 node won't sync
   :icon: question

   **Possible causes:**
   
   - L1 node not synced or not accessible
   - Incorrect L1 RPC endpoint configuration
   - Network connectivity issues
   - Insufficient disk space
   
   **Solutions:**
   
   - Verify L1 node is fully synced: ``curl http://localhost:8545 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'``
   - Check L2 client logs: ``sudo journalctl -u [service-name] -f``
   - Verify L1 endpoint in config files
   - Check disk space: ``df -h``
   - Ensure firewall allows connections to L1 node

.. dropdown:: Snapshot download is very slow or fails
   :icon: question

   **Applies to:** Arbitrum
   
   **Possible causes:**
   
   - Large snapshot size (can be 2+ TB)
   - Network bandwidth limitations
   - Snapshot server issues
   
   **Solutions:**
   
   - Use ``screen`` or ``tmux`` to prevent disconnection
   - Check available disk space before starting
   - Consider using a faster internet connection
   - Try alternative snapshot providers if available
   - Monitor download progress: check logs in screen session

.. dropdown:: L2 client shows "waiting for L1" or similar message
   :icon: question

   **Cause:** L1 node is not fully synced or not accessible
   
   **Solutions:**
   
   - Wait for L1 node to complete sync (check L1 client logs)
   - Verify L1 RPC endpoint is correct in L2 config
   - Test L1 connection: ``curl http://YOUR_L1_IP:8545``
   - Check JWT secret is correctly configured (if required)

.. dropdown:: High memory or CPU usage
   :icon: question

   **Cause:** Some L2 clients require significant resources, especially during initial sync
   
   **Solutions:**
   
   - Ensure you meet minimum hardware requirements
   - Ensure you meet minimum hardware requirements (16GB RAM recommended)
   - Monitor resources: ``htop`` or ``free -h``
   - Consider using lighter L2 solutions if hardware is limited
   - Restart services if memory leak suspected

.. dropdown:: Optimism/Base: "missing trie node" or database errors
   :icon: question

   **Possible causes:**
   
   - Corrupted database
   - Incomplete snapshot
   - Disk issues
   
   **Solutions:**
   
   - Stop the service: ``sudo systemctl stop op-geth`` or ``sudo systemctl stop nethermind-op``
   - Remove database and resync from snapshot
   - Check disk health: ``sudo smartctl -a /dev/sdX``
   - Ensure sufficient disk space for growth

.. dropdown:: Starknet: Juno or Madara won't start
   :icon: question

   **Solutions:**
   
   - Check service status: ``sudo systemctl status juno`` or ``sudo systemctl status madara``
   - Review logs: ``sudo journalctl -u juno -n 100`` or ``sudo journalctl -u madara -n 100``
   - Verify configuration file syntax
   - Ensure data directory permissions are correct: ``ls -la /home/ethereum/.juno`` or ``ls -la /var/lib/madara``
   - Check if ports are already in use: ``sudo netstat -tulpn | grep 9944``

.. dropdown:: EthRex L2: Prover not generating proofs
   :icon: question

   **Possible causes:**
   
   - Sequencer not running or not producing blocks
   - Proof coordinator connection issues
   - Backend configuration issues
   
   **Solutions:**
   
   - Verify sequencer is running: ``sudo systemctl status ethrex-l2``
   - Check prover logs: ``sudo journalctl -u ethrex-l2-prover -f``
   - Verify proof coordinator endpoint in ``/etc/ethereum/ethrex-l2-prover.conf``
   - Ensure backend (exec/SP1/RISC0) is properly configured
   - Check network connectivity between prover and coordinator
