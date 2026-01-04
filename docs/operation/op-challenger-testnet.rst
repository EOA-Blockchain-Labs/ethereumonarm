Testing Op-Challenger on Sepolia Testnet
=========================================

This guide walks you through testing the Optimism Fault Proof Challenger on the **Sepolia testnet** from scratch, including setting up L1 and L2 nodes, creating a wallet, and funding it via faucets.

.. important::
   This guide is for **testing purposes only**. For mainnet operation, see :doc:`optimism-challenger`.

Architecture Overview
---------------------

The op-challenger requires a complete L1 + L2 stack:

.. code-block:: text

   ┌─────────────────────────────────────────────────────────────┐
   │                    Op-Challenger                            │
   │            (Monitors & Challenges Invalid Proofs)           │
   └─────────────────────────────────────────────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
   ┌───────────┐       ┌───────────┐        ┌───────────┐
   │ L1 EL RPC │       │ L1 Beacon │        │  L2 RPCs  │
   │(Nethermind)│       │(Lighthouse)│        │(op-node)  │
   └───────────┘       └───────────┘        └───────────┘
         │                    │                    │
         └────────────────────┼────────────────────┘
                              ▼
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

Step 1: Install L2 Packages
----------------------------

The Ethereum on ARM image already includes L1 clients (Nethermind, Lighthouse, etc.). You only need to install the L2/Optimism packages:

.. prompt:: bash $

   # L2 Clients (op-challenger pulls cannon and op-program as dependencies)
   sudo apt-get update
   sudo apt-get install optimism-op-geth optimism-op-node optimism-op-challenger

Step 2: Configure L1 Layer (Sepolia)
------------------------------------

Nethermind (Execution Layer)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Edit ``/etc/ethereum/nethermind-sepolia.conf``:

.. code-block:: bash

   ARGS="--config sepolia \
       --loggerConfigSource /opt/nethermind/NLog.config \
       -dd /home/ethereum/.nethermind-sepolia \
       --JsonRpc.JwtSecretFile /etc/ethereum/jwtsecret \
       --JsonRpc.Enabled true \
       --JsonRpc.Host 127.0.0.1 \
       --JsonRpc.Port 8545 \
       --Metrics.Enabled true \
       --Metrics.ExposePort 7070"

Lighthouse (Consensus Layer)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Edit ``/etc/ethereum/lighthouse-beacon-sepolia.conf``:

.. code-block:: bash

   ARGS="--network sepolia \
       beacon \
       --eth1 \
       --http \
       --http-address 127.0.0.1 \
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

Step 3: Configure L2 Layer (OP-Sepolia)
---------------------------------------

Create a separate JWT secret for L2:

.. prompt:: bash $

   sudo openssl rand -hex 32 | sudo tee /etc/ethereum/jwtsecret-l2
   sudo chmod 644 /etc/ethereum/jwtsecret-l2

Op-Geth (L2 Execution)
~~~~~~~~~~~~~~~~~~~~~~

Create ``/etc/ethereum/op-geth-sepolia.conf``:

.. code-block:: bash

   ARGS="--datadir=/home/ethereum/.op-geth-sepolia \
       --verbosity=3 \
       --op-network=op-sepolia \
       --http --http.port=31303 --http.addr=127.0.0.1 \
       --authrpc.addr=127.0.0.1 \
       --authrpc.jwtsecret=/etc/ethereum/jwtsecret-l2 \
       --authrpc.port=8555 \
       --rollup.sequencerhttp=https://sepolia-sequencer.optimism.io \
       --syncmode=snap \
       --metrics=true --metrics.addr=0.0.0.0 --metrics.port=7301"

Op-Node (L2 Rollup)
~~~~~~~~~~~~~~~~~~~

Create ``/etc/ethereum/op-node-sepolia.conf``:

.. code-block:: bash

   ARGS="--l1=http://127.0.0.1:8545 \
       --l1.beacon=http://127.0.0.1:5052 \
       --l2=http://127.0.0.1:8555 \
       --network=op-sepolia \
       --rpc.addr=127.0.0.1 \
       --rpc.port=9545 \
       --l2.jwt-secret=/etc/ethereum/jwtsecret-l2 \
       --metrics.enabled \
       --metrics.addr=0.0.0.0 \
       --metrics.port=7300 \
       --syncmode=execution-layer"

Start L2 Services
~~~~~~~~~~~~~~~~~

After L1 is synced:

.. prompt:: bash $

   sudo systemctl enable --now op-geth op-node

Step 4: Create a Challenger Wallet
----------------------------------

The challenger needs a funded wallet to submit challenge transactions.

Option 1: Using OpenSSL
~~~~~~~~~~~~~~~~~~~~~~~

.. prompt:: bash $

   # Generate a new private key
   openssl rand -hex 32 > /home/ethereum/challenger-testnet.key
   chown ethereum:ethereum /home/ethereum/challenger-testnet.key
   chmod 600 /home/ethereum/challenger-testnet.key

   # Get the public address (requires cast from Foundry)
   cast wallet address --private-key $(cat /home/ethereum/challenger-testnet.key)

Option 2: Using Foundry Cast
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. prompt:: bash $

   # Install Foundry if not already installed
   curl -L https://foundry.paradigm.xyz | bash
   foundryup

   # Create a new encrypted keystore
   cast wallet new /home/ethereum/keystore challenger-testnet

Step 5: Fund the Wallet
-----------------------

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
   Request funds daily over several days to accumulate enough for testing. You'll need at least **0.1 ETH** for basic testing.

Step 6: Configure Op-Challenger
-------------------------------

Create ``/etc/ethereum/op-challenger-sepolia.conf``:

.. code-block:: bash

   # Challenger Data Directory
   DATADIR="/home/ethereum/.op-challenger-sepolia"
   NUM_CONFIRMATIONS=1

   # L1 RPCs (Nethermind + Lighthouse)
   L1_ETH_RPC="http://127.0.0.1:8545"
   L1_BEACON_RPC="http://127.0.0.1:5052"

   # L2 RPCs (op-node + op-geth)
   ROLLUP_RPC="http://127.0.0.1:9545"
   L2_ETH_RPC="http://127.0.0.1:31303"

   # Network (automatically sets correct DisputeGameFactory address)
   NETWORK="op-sepolia"
   TRACE_TYPE="cannon"

   # Cannon Configuration
   CANNON_BIN="/usr/bin/cannon"
   CANNON_SERVER="/usr/bin/op-program"
   CANNON_PRESTATES_URL="https://storage.googleapis.com/optimism-cannon-prestates/sepolia/"

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

   sudo mkdir -p /home/ethereum/.op-challenger-sepolia
   sudo chown ethereum:ethereum /home/ethereum/.op-challenger-sepolia

Step 7: Start the Challenger
----------------------------

After L2 is synced:

.. prompt:: bash $

   sudo systemctl enable --now op-challenger

Check the logs:

.. prompt:: bash $

   sudo journalctl -fu op-challenger

Step 8: Verify Operation
------------------------

**Signs of a healthy challenger:**

1. **Game Detection:** You should see logs about tracking games:

   .. code-block:: text

      INFO [01-04|12:00:00] Monitoring games    count=5 type=FaultDisputeGame

2. **No Connection Errors:** Ensure no repeated L1/L2 connection errors.

3. **Metrics Available:** Check metrics at ``http://localhost:7300/metrics``

Service Summary
---------------

.. list-table::
   :header-rows: 1
   :widths: 25 25 25 25

   * - Service
     - Config File
     - Port
     - Purpose
   * - ``nethermind-sepolia``
     - ``nethermind-sepolia.conf``
     - 8545 (RPC), 8551 (Auth)
     - L1 Execution
   * - ``lighthouse-beacon-sepolia``
     - ``lighthouse-beacon-sepolia.conf``
     - 5052 (HTTP)
     - L1 Consensus
   * - ``op-geth``
     - ``op-geth-sepolia.conf``
     - 31303 (RPC), 8555 (Auth)
     - L2 Execution
   * - ``op-node``
     - ``op-node-sepolia.conf``
     - 9545 (RPC)
     - L2 Rollup
   * - ``op-challenger``
     - ``op-challenger-sepolia.conf``
     - 7300 (Metrics)
     - Challenger

Troubleshooting
---------------

**"Failed to connect to L1"**
   - Verify Nethermind is running and synced
   - Check ``L1_ETH_RPC`` points to correct port (8545)

**"L1 beacon client not available"**
   - Verify Lighthouse is running
   - Check ``L1_BEACON_RPC`` points to correct port (5052)

**"Failed to fetch game"**
   - Verify L2 is synced (``op-node`` and ``op-geth``)
   - Check ``GAME_FACTORY_ADDRESS`` is correct for OP-Sepolia

**"Insufficient funds"**
   - Your challenger wallet needs more Sepolia ETH
   - Use faucets to request additional funds

See Also
--------

- :doc:`optimism-challenger` - Production setup guide
- :doc:`optimism-challenger-verification` - Verification procedures
- :doc:`optimism-l2` - Full Optimism L2 node setup
