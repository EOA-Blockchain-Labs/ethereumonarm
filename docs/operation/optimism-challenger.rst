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

1. **Generate a Private Key**

You need a dedicated wallet for the Challenger. It needs a small amount of ETH on L1 (Sepolia/Mainnet) to pay for challenge transactions.

.. prompt:: bash $

    # Generate a new key (store this safely!)
    openssl rand -hex 32 > /home/ethereum/challenger.key
    chown ethereum:ethereum /home/ethereum/challenger.key
    chmod 600 /home/ethereum/challenger.key

2. **Edit Configuration**

Open the config file:

.. prompt:: bash $

    sudo nano /etc/ethereum/op-challenger.conf

Update the ``ARGS`` variable with your details:

.. code-block:: bash

    ARGS="--l1-eth-rpc=http://localhost:8545 \
          --l1-beacon=http://localhost:5052 \
          --rollup-rpc=http://localhost:8547 \
          --private-key=/home/ethereum/challenger.key \
          --cannon-l2-genesis=/path/to/genesis.json \
          --cannon-bin=/usr/bin/op-program \
          --cannon-server=/usr/bin/cannon \
          --datadir=/home/ethereum/.op-challenger"

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
