Running a Guardian Node (Optimism Challenger)
=============================================

.. important::
   This feature supports the decentralization of the Optimism Superchain by allowing independent operators to challenge invalid state transitions.

The **Fault Proof Challenger** (officially ``op-challenger``) is a critical component of the Optimism security model. It continuously monitors the dispute game contracts on L1 (Ethereum) and the L2 chain (Optimism). If it detects a dishonest proposal, it challenges it to ensure the integrity of the network.

By running a Challenger, you become a "Guardian" of the network, securing it against invalid state transitions without needing to trust a centralized entity.

Prerequisites
-------------

To run a Challenger efficiently, you should ideally have:

*   **A fully synced L1 Node** (Execution + Consensus)
*   **A fully synced L2 Node** (Optimism/Base Supernode)
*   **Hardware:** Recent ARM64 board (Rock 5B / Orange Pi 5 Plus) with 16GB+ RAM.

.. note::
   While it is possible to use remote RPCs, running local nodes significantly reduces latency and improves the reliability of your challenges.

Installation
------------

We provide a pre-compiled package for ARM64 systems. This package will automatically install the strict dependencies: ``optimism-cannon`` and ``optimism-op-program``.

.. prompt:: bash $

    sudo apt-get update
    sudo apt-get install optimism-op-challenger

Expected Output:

.. code-block:: text

    The following additional packages will be installed:
      optimism-cannon optimism-op-program
    The following NEW packages will be installed:
      optimism-cannon optimism-op-challenger optimism-op-program
    ...
    Setting up optimism-cannon (1.7.0-0) ...
    Setting up optimism-op-program (1.7.0-0) ...
    Setting up optimism-op-challenger (1.7.0-0) ...
    Created symlink /etc/systemd/system/multi-user.target.wants/op-challenger.service → /lib/systemd/system/op-challenger.service.
    ✅ Installation Complete!
    Guardian Node (Fault Proof Challenger) is now installed.

Configuration
-------------

The configuration is managed via ``/etc/ethereum/op-challenger.conf``.

1. **Acquire Configuration Files**

   The challenger requires network-specific files to operate.

   *   **genesis.json (L2 Genesis) & rollup.json**: Obtain these from the `Optimism Superchain Registry <https://github.com/ethereum-optimism/superchain-registry>`_ for official networks, or from your deployment artifacts.

   *   **prestate.bin.gz (Absolute Prestate)**: This represents the initial state of the Fault Proof VM (Cannon). It must generated to match the `op-program` binary you are using:

       .. code-block:: bash

           # Generate the prestate file
           /usr/bin/cannon load-elf --path=/usr/bin/op-program --out=/home/ethereum/prestate.bin.gz --meta=""
           
           # Ensure correct permissions
           chown ethereum:ethereum /home/ethereum/prestate.bin.gz

2. **Generate a Private Key**

You need a dedicated wallet for the Challenger. It needs a small amount of ETH on L1 (Sepolia/Mainnet) to pay for challenge transactions.

.. prompt:: bash $

    # Generate a new key (store this safely!)
    openssl rand -hex 32 > /home/ethereum/challenger.key
    chown ethereum:ethereum /home/ethereum/challenger.key
    chmod 600 /home/ethereum/challenger.key

3. **Edit Configuration**

Open the config file:

.. prompt:: bash $

    sudo nano /etc/ethereum/op-challenger.conf

Update the configuration variables with your details (ensure these match your network):

.. code-block:: bash

    # RPC Endpoints
    L1_ETH_RPC="http://localhost:8545"
    L1_BEACON_RPC="http://localhost:5052"
    ROLLUP_RPC="http://localhost:8547"
    L2_ETH_RPC="http://localhost:9545"

    # Game Configuration (Check Optimism docs for your network)
    GAME_FACTORY_ADDRESS="0x..."
    TRACE_TYPE="cannon,permissioned"

    # Signer
    PRIVATE_KEY="/home/ethereum/challenger.key"

    # Cannon Configuration
    CANNON_PRESTATE="/home/ethereum/prestate.bin.gz"
    CANNON_ROLLUP_CONFIG="/path/to/rollup.json"
    CANNON_L2_GENESIS="/path/to/genesis.json"
    CANNON_BIN="/usr/bin/cannon"
    CANNON_SERVER="/usr/bin/op-program"

    DATADIR="/home/ethereum/.op-challenger"

.. tip:: 
   For Mainnet/Sepolia network addresses and Genesis files, refer to the `Optimism Networks Repository <https://github.com/ethereum-optimism/ethereum-optimism.github.io>`_.

Running the Guardian
--------------------

Start the service:

.. prompt:: bash $

    sudo systemctl enable --now op-challenger

Check the status:

.. prompt:: bash $

    sudo systemctl status op-challenger
    sudo journalctl -u op-challenger -f

Verification
------------

For a detailed guide on verifying the correct operation of your Challenger, including log analysis and service checks, please refer to :doc:`optimism-challenger-verification`.

Monitoring
----------

The Challenger exposes metrics that can be scraped by Prometheus.

*   **Metrics Port:** 7300 (default)
*   **Grafana Dashboard:** We provide a "Guardian Dashboard" in our Grafana package to visualize:
    *   Active Games
    *   Claims Resolved
    *   L1/L2 Latency

Troubleshooting
---------------

**"Failed to fetch game"**
   Ensure your L1 node is fully synced and the RPC URL is correct.

**"Gas estimation failed"**
   Ensure your challenger wallet has enough ETH (on L1) to post bonds and challenges.

Running an L2 Output Proposer (Optional)
========================================

If you are a chain operator or testing L2 output submission, you may also want to run the **L2 Output Proposer** (``op-proposer``). This component is responsible for submitting L2 state roots to L1.

.. warning::
   **For standard Guardian/Challenger nodes on Mainnet/Sepolia, you typically do NOT run this.** This is primarily for chain operators.

Installation
------------

.. prompt:: bash $

    sudo apt-get install optimism-op-proposer

Configuration
-------------

Edit ``/etc/ethereum/op-proposer.conf``:

1.  **Configure RPCs:** Set ``L1_ETH_RPC`` and ``ROLLUP_RPC``.
2.  **Set Game Factory:** Set ``GAME_FACTORY_ADDRESS`` to your network's ``DisputeGameFactoryProxy``.
    
    .. note::
       Since June 2024, Optimism Mainnet and Sepolia use the **DisputeGameFactory** for permissionless fault proofs. The legacy ``L2OutputOracle`` is deprecated for these networks.

3.  **Set Signer:** Provide a ``PRIVATE_KEY`` or ``MNEMONIC`` funded on L1.

Running the Service
-------------------

.. prompt:: bash $

    sudo systemctl enable --now op-proposer
    sudo journalctl -u op-proposer -f
