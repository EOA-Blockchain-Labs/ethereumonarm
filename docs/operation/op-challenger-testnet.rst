Testnet Guide: Multi-Machine Setup
==================================

This guide walks you through testing the Optimism Fault Proof Challenger on the **Sepolia testnet** using a multi-machine setup connected via PiVPN/WireGuard.

.. important::
   This guide is for **testing purposes only**. For mainnet operation, see :doc:`optimism-challenger`.

Prerequisites
-------------

This guide assumes you have:

- **3 ARM devices** running Ethereum on ARM (Rock 5B, Orange Pi 5 Plus, NanoPC-T6, etc.)
- **PiVPN/WireGuard configured** per :doc:`/system/network-vpn` (10.1.25.0/24 subnet)
- L1 clients pre-installed (Nethermind, Lighthouse come with the image)

Architecture Overview
---------------------

We use 3 machines connected via WireGuard VPN:

.. code-block:: text

   ┌─────────────────────────────────────────────────────────────────────────┐
   │                        WireGuard VPN (10.1.25.0/24)                     │
   └─────────────────────────────────────────────────────────────────────────┘
            │                         │                         │
            ▼                         ▼                         ▼
   ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
   │   Machine 1     │     │   Machine 2     │     │   Machine 3     │
   │   L1 NODE       │     │   L2 NODE       │     │   CHALLENGER    │
   │  10.1.25.11     │     │  10.1.25.9      │     │  10.1.25.10     │
   ├─────────────────┤     ├─────────────────┤     ├─────────────────┤
   │ • Nethermind    │     │ • op-geth       │     │ • op-challenger │
   │   (EL :8545)    │     │   (EL :9545)    │     │ • cannon        │
   │ • Lighthouse    │     │ • op-node       │     │ • op-program    │
   │   (CL :5052)    │     │   (RPC :8545)   │     │                 │
   └─────────────────┘     └─────────────────┘     └─────────────────┘
            │                         │
            └─────────────────────────┘
                    Ethereum Sepolia

Available Packages
------------------

The following Optimism packages are available:

.. list-table::
   :header-rows: 1
   :widths: 25 25 50

   * - Binary
     - Package
     - Purpose
   * - ``cannon``
     - ``optimism-cannon``
     - MIPS Fault Proof VM
   * - ``op-program``
     - ``optimism-op-program``
     - On-chain program for fault proofs
   * - ``op-challenger``
     - ``optimism-op-challenger``
     - Fault Proof Challenger
   * - ``op-geth``
     - ``optimism-op-geth``
     - L2 Execution Layer
   * - ``op-node``
     - ``optimism-op-node``
     - L2 Rollup/Consensus Node
   * - ``op-proposer``
     - ``optimism-op-proposer``
     - L2 Output Proposer
   * - ``op-reth``
     - ``optimism-op-reth``
     - L2 Execution Layer (Reth alternative)

Machine 1: L1 Node (10.1.25.11)
-------------------------------

This machine runs the Ethereum L1 clients (Nethermind + Lighthouse) for Sepolia.

L1 clients are pre-installed on the Ethereum on ARM image.

Configure Nethermind
--------------------

Edit ``/etc/ethereum/nethermind-sepolia.conf`` to bind to VPN interface:

.. code-block:: bash

   ARGS="--config sepolia \
       --loggerConfigSource /opt/nethermind/NLog.config \
       -dd /home/ethereum/.nethermind-sepolia \
       --JsonRpc.JwtSecretFile /etc/ethereum/jwtsecret \
       --JsonRpc.Enabled true \
       --JsonRpc.Host 0.0.0.0 \
       --JsonRpc.Port 8545 \
       --Metrics.Enabled true \
       --Metrics.ExposePort 7070"

Configure Lighthouse
--------------------

Edit ``/etc/ethereum/lighthouse-beacon-sepolia.conf``:

.. code-block:: bash

   ARGS="--network sepolia \
       beacon \
       --http \
       --http-address 0.0.0.0 \
       --http-port 5052 \
       --execution-endpoint http://127.0.0.1:8551 \
       --execution-jwt /etc/ethereum/jwtsecret \
       --metrics \
       --checkpoint-sync-url https://sepolia.beaconstate.info \
       --prune-payloads false"

Start L1 Services
~~~~~~~~~~~~~~~~~

.. prompt:: bash $

   sudo systemctl enable --now nethermind-sepolia lighthouse-beacon-sepolia

Wait for L1 to sync (can take several hours). Check progress:

.. prompt:: bash $

   sudo journalctl -fu nethermind-sepolia
   sudo journalctl -fu lighthouse-beacon-sepolia

Machine 2: L2 Node (10.1.25.9)
-----------------------------

This machine runs the Optimism L2 clients (op-geth + op-node).

Install L2 Packages
-------------------

.. prompt:: bash $

   sudo apt-get update
   sudo apt-get install optimism-op-geth optimism-op-node

Create a JWT secret for L2:

.. prompt:: bash $

   sudo openssl rand -hex 32 | sudo tee /etc/ethereum/jwtsecret-l2
   sudo chmod 644 /etc/ethereum/jwtsecret-l2

Configure Op-Geth
-----------------

Edit ``/etc/ethereum/op-geth.conf``:

.. code-block:: bash

   ARGS="--datadir=/home/ethereum/.op-geth-sepolia \
       --verbosity=3 \
       --op-network=op-sepolia \
       --http --http.port=9545 --http.addr=0.0.0.0 \
       --authrpc.addr=127.0.0.1 \
       --authrpc.jwtsecret=/etc/ethereum/jwtsecret-l2 \
       --authrpc.port=8555 \
       --rollup.sequencerhttp=https://sepolia-sequencer.optimism.io \
       --syncmode=snap \
       --metrics=true --metrics.addr=0.0.0.0 --metrics.port=7301"

Configure Op-Node
-----------------

Edit ``/etc/ethereum/op-node.conf`` (note: L1 endpoints point to Machine 1):

.. code-block:: bash

   ARGS="--l1=http://10.1.25.11:8545 \
       --l1.beacon=http://10.1.25.11:5052 \
       --l2=http://127.0.0.1:8555 \
       --network=op-sepolia \
       --rpc.addr=0.0.0.0 \
       --rpc.port=8545 \
       --l2.jwt-secret=/etc/ethereum/jwtsecret-l2 \
       --metrics.enabled \
       --metrics.addr=0.0.0.0 \
       --metrics.port=7300 \
       --syncmode=execution-layer"

Start L2 Services
-----------------

After L1 is synced on Machine 1:

.. prompt:: bash $

   sudo systemctl enable --now op-geth op-node

Machine 3: Challenger (10.1.25.10)
----------------------------------

This machine runs the op-challenger (with cannon and op-program).

Install Challenger Packages
---------------------------

.. prompt:: bash $

   sudo apt-get update
   sudo apt-get install optimism-op-challenger

This automatically installs ``optimism-cannon`` and ``optimism-op-program`` as dependencies.

Create Challenger Wallet
------------------------

The challenger needs a funded wallet to submit challenge transactions.

.. prompt:: bash $

   # Generate a new private key
   openssl rand -hex 32 > /home/ethereum/challenger-testnet.key
   chown ethereum:ethereum /home/ethereum/challenger-testnet.key
   chmod 600 /home/ethereum/challenger-testnet.key

   # Get the public address (requires cast from Foundry)
   cast wallet address --private-key $(cat /home/ethereum/challenger-testnet.key)

Fund the Wallet
---------------

You need **Sepolia ETH** (for L1 transactions). Use one of these faucets:

.. list-table::
   :header-rows: 1
   :widths: 30 20 50

   * - Faucet
     - Daily Limit
     - Requirements
   * - `Chainlink Faucet <https://faucets.chain.link/sepolia>`_
     - 0.1 ETH
     - Connect wallet
   * - `QuickNode Faucet <https://faucet.quicknode.com/ethereum/sepolia>`_
     - 0.05 ETH
     - 0.001 ETH mainnet balance
   * - `Alchemy Faucet <https://www.alchemy.com/faucets/ethereum-sepolia>`_
     - 0.5 ETH
     - Alchemy account

.. tip::
   Request funds daily over several days. You'll need at least **0.1 ETH** for testing.

Configure Op-Challenger
-----------------------

Edit ``/etc/ethereum/op-challenger.conf`` (note: L1/L2 endpoints point to other machines):

.. code-block:: bash

   # Challenger Data Directory
   DATADIR="/home/ethereum/.op-challenger"
   NUM_CONFIRMATIONS=1

   # L1 RPCs (Machine 1: 10.1.25.11)
   L1_ETH_RPC="http://10.1.25.11:8545"
   L1_BEACON_RPC="http://10.1.25.11:5052"

   # L2 RPCs (Machine 2: 10.1.25.9)
   ROLLUP_RPC="http://10.1.25.9:8545"
   L2_ETH_RPC="http://10.1.25.9:9545"

   # Network (automatically sets correct DisputeGameFactory address)
   NETWORK="op-sepolia"
   TRACE_TYPE="cannon"

   # Cannon Configuration
   CANNON_BIN="/usr/bin/cannon"
   CANNON_SERVER="/usr/bin/op-program"
   CANNON_PRESTATES_URL="https://storage.googleapis.com/optimism/cannon-prestates/"

   # Signer (use your testnet key)
   PRIVATE_KEY="/home/ethereum/challenger-testnet.key"

   # Build the command arguments
   ARGS="--datadir=$DATADIR \
         --num-confirmations=$NUM_CONFIRMATIONS \
         --l1-eth-rpc=$L1_ETH_RPC \
         --l1-beacon=$L1_BEACON_RPC \
         --rollup-rpc=$ROLLUP_RPC \
         --l2-eth-rpc=$L2_ETH_RPC \
         --network=$NETWORK \
         --trace-type=$TRACE_TYPE \
         --cannon-bin=$CANNON_BIN \
         --cannon-server=$CANNON_SERVER \
         --cannon-prestates-url=$CANNON_PRESTATES_URL \
         --private-key=$PRIVATE_KEY"

Create the data directory:

.. prompt:: bash $

   sudo mkdir -p /home/ethereum/.op-challenger
   sudo chown ethereum:ethereum /home/ethereum/.op-challenger

Start the Challenger
--------------------

After L2 is synced on Machine 2:

.. prompt:: bash $

   sudo systemctl enable --now op-challenger

Check the logs:

.. prompt:: bash $

   sudo journalctl -fu op-challenger

Verification
------------

**Signs of a healthy challenger:**

1. **Game Detection:** You should see logs about tracking games:

   .. code-block:: text

      INFO [01-04|12:00:00] Monitoring games    count=5 type=FaultDisputeGame

2. **No Connection Errors:** Ensure no L1/L2 connection errors.

3. **Metrics Available:** Check metrics at ``http://10.1.25.10:7300/metrics``

Service Summary
---------------

.. list-table::
   :header-rows: 1
   :widths: 15 25 20 15 25

   * - Machine
     - Service
     - VPN IP
     - Port
     - Purpose
   * - 1
     - ``nethermind-sepolia``
     - 10.1.25.11
     - 8545
     - L1 Execution
   * - 1
     - ``lighthouse-beacon-sepolia``
     - 10.1.25.11
     - 5052
     - L1 Consensus
   * - 2
     - ``op-geth``
     - 10.1.25.9
     - 9545
     - L2 Execution
   * - 2
     - ``op-node``
     - 10.1.25.9
     - 8545
     - L2 Rollup RPC
   * - 3
     - ``op-challenger``
     - 10.1.25.10
     - 7300
     - Challenger

Troubleshooting
---------------

**"Failed to connect to L1"**
   - Check VPN connectivity: ``ping 10.1.25.11``
   - Verify Nethermind is bound to ``0.0.0.0``

**"L1 beacon client not available"**
   - Check VPN connectivity: ``ping 10.1.25.11``
   - Verify Lighthouse is bound to ``0.0.0.0``

**"Failed to connect to L2"**
   - Check VPN connectivity: ``ping 10.1.25.9``
   - Verify op-node/op-geth are bound to ``0.0.0.0``

**"Insufficient funds"**
   - Your challenger wallet needs more Sepolia ETH
   - Use faucets to request additional funds

See Also
--------

- :doc:`/system/network-vpn` - PiVPN/WireGuard setup guide
- :doc:`optimism-challenger` - Production setup guide
- :doc:`optimism-challenger-verification` - Verification procedures
