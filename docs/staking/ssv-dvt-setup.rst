SSV DVT Setup Guide
====================

.. meta::
   :description lang=en: SSV DVT setup on ARM. Run distributed validators with SSV Network for fault-tolerant staking. Operator and staker guides for NanoPC T6 and Rock 5B.
   :keywords: SSV DVT, Secret Shared Validators, distributed validator, fault tolerant staking, SSV Network, operator node

This guide explains how to set up and run an SSV (Secret Shared Validators) node on Ethereum on ARM, enabling distributed validator technology for enhanced resilience and security.

.. note::

   Distributed Validator Technology (DVT) allows multiple operators to run a single validator together,
   eliminating single points of failure and reducing slashing risk.

Overview
--------

SSV Network enables you to split your validator key among multiple operators. Each operator holds an encrypted key share, and a threshold of operators must agree to sign any validator duty. This provides:

- **Fault Tolerance**: Validators continue operating if some operators go offline
- **Slashing Protection**: No single operator can sign conflicting messages
- **Decentralization**: Distribute trust across multiple parties
- **MEV Integration**: Full support for MEV-boost and block builders

Prerequisites
-------------

Before starting, ensure you have:

- **Hardware**: ARM64 device running Ethereum on ARM (NanoPC T6, Rock 5B, etc.)
- **Full Ethereum Node**: Running execution layer + consensus layer clients
- **Network Ports**:
  - 12001 UDP: SSV P2P discovery
  - 13001 TCP: SSV P2P communication
  - 15000 TCP: Metrics (optional, local only)
  - 16000 TCP: Health API (optional, local only)
- **Storage**: Additional ~2GB for SSV data
- **SSV Tokens**: Required for operator registration and cluster fees

Install the ``dvt-ssv`` package:

.. prompt:: bash $

   sudo apt-get update && sudo apt-get install dvt-ssv

For package details, installation paths, and service names, see :doc:`/packages/dvt/ssv-node`.

Understanding SSV Roles
-----------------------

The SSV Network has two main participant roles:

**Operators**
   Run SSV nodes that manage validators on behalf of stakers. Operators register on the network, set fees, and earn rewards for performing validator duties.

**Stakers**
   Own the ETH and validator keys. Stakers split their keys among chosen operators and pay ongoing fees for the service.

This guide covers both roles, but focuses primarily on operator setup since stakers typically use the SSV WebApp.

SSV Architecture
----------------

The SSV node sits alongside your execution and consensus clients, communicating with the SSV Network to coordinate validator duties:

.. code-block:: text

    +------------------+       +------------------+
    |    SSV Node      | <---> |   Beacon Node    |
    +------------------+       +------------------+
            |                          |
            v                          v
    +------------------+       +------------------+
    |  SSV P2P Network | <---> | Execution Client |
    +------------------+       +------------------+

Key components:

- **SSV Node (ssvnode)**: Core daemon that manages validators and communicates with other operators
- **SSV Keys (ssv-keys)**: Tool for splitting validator keys into shares
- **SSV WebApp**: Browser interface for registration and cluster management

Part 1: Operator Setup
----------------------

Step 1: Generate Operator Keys
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Generate an encrypted keypair for your operator identity:

.. prompt:: bash $

   ssv-keys generate-operator-keys

Follow the prompts to:

1. Enter a password for key encryption
2. Save the generated files securely

This creates:

- ``encrypted_private_key.json``: Your encrypted operator private key
- ``password.txt``: Your password file (create this manually if not auto-generated)

Move these to the SSV data directory:

.. prompt:: bash $

   sudo mv encrypted_private_key.json /home/ethereum/.ssv/
   sudo mv password.txt /home/ethereum/.ssv/
   sudo chown ethereum:ethereum /home/ethereum/.ssv/*
   sudo chmod 600 /home/ethereum/.ssv/*

.. warning::

   Back up your operator keys immediately! Loss of these keys means loss of your operator identity and any associated validators.

Step 2: Configure SSV Node
~~~~~~~~~~~~~~~~~~~~~~~~~~

Edit the main configuration file:

.. prompt:: bash $

   sudo nano /etc/ethereum/ssv-config.yaml

Key configuration options:

.. code-block:: yaml

   global:
     LogLevel: info
     LogFileBackups: 10

   db:
     Path: /home/ethereum/.ssv

   ssv:
     # Network: mainnet, hoodi, or sepolia
     Network: mainnet

   eth2:
     # Your Beacon node endpoint
     BeaconNodeAddr: http://localhost:5052
     # Enable for multi-beacon-node setups
     WithWeightedAttestationData: false
     WithParallelSubmissions: false

   eth1:
     # Your Execution node WebSocket endpoint
     ETH1Addr: ws://localhost:8546/ws

   p2p:
     # Optional: Set external IP if behind NAT
     # HostAddress: YOUR_EXTERNAL_IP
     # TcpPort: 13001
     # UdpPort: 12001

   KeyStore:
     PrivateKeyFile: /home/ethereum/.ssv/encrypted_private_key.json
     PasswordFile: /home/ethereum/.ssv/password.txt

   # Enable for slashing protection
   EnableDoppelgangerProtection: true

   # Monitoring endpoints
   MetricsAPIPort: 15000
   SSVAPIPort: 16000

.. important::

   Ensure your Beacon and Execution nodes are fully synced before starting the SSV node.

Step 3: Configure Network Ports
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Open the required ports for SSV P2P communication:

.. prompt:: bash $

   sudo ufw allow 12001/udp comment "SSV P2P UDP"
   sudo ufw allow 13001/tcp comment "SSV P2P TCP"

If behind a NAT/router, configure port forwarding for these ports and set ``HostAddress`` in the configuration.

Step 4: Start the SSV Node
~~~~~~~~~~~~~~~~~~~~~~~~~~

Enable and start the SSV service:

.. prompt:: bash $

   sudo systemctl enable --now ssv.service

Verify the node is running:

.. prompt:: bash $

   sudo journalctl -u ssv -f

Look for successful startup messages:

.. code-block:: text

   successfully setup operator keys
   p2p: started peer discovery
   node is ready

Step 5: Register as Operator
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Once your node is running, register on the SSV Network:

1. Visit the `SSV WebApp <https://app.ssv.network>`_
2. Connect your wallet
3. Select "Join as Operator"
4. Enter your **public key** (from key generation)
5. Set your operator fee (annual, in SSV tokens)
6. Confirm the registration transaction

After registration, your operator will appear in the SSV explorer and stakers can select you for their clusters.

Step 6: Verify Health
~~~~~~~~~~~~~~~~~~~~~

Check node health via the API:

.. prompt:: bash $

   curl http://localhost:16000/v1/node/health

Expected response:

.. code-block:: json

   {"status":"healthy"}

Check connected peers:

.. prompt:: bash $

   curl http://localhost:15000/metrics | grep p2p_peers

Part 2: MEV Configuration
-------------------------

SSV supports MEV-boost for enhanced block rewards. MEV is managed by your Beacon client, not the SSV node directly.

Step 1: Install MEV-boost
~~~~~~~~~~~~~~~~~~~~~~~~~

.. prompt:: bash $

   sudo apt-get install mev-boost

Step 2: Configure MEV-boost
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Edit the MEV-boost configuration:

.. prompt:: bash $

   sudo nano /etc/ethereum/mev-boost.conf

Add your preferred relays:

.. code-block:: bash

   ARGS="-mainnet \
         -relay-check \
         -relay https://0xac6067d594...@boost-relay.flashbots.net \
         -relay https://0xa15b52...@bloxroute.max-profit.blxrbdn.com"

Step 3: Enable MEV in Beacon Client
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Configure your consensus client to use MEV-boost. Example for Lighthouse:

.. prompt:: bash $

   sudo nano /etc/ethereum/lighthouse-beacon.conf

Add the builder flag:

.. code-block:: bash

   ARGS="... --builder http://127.0.0.1:18550"

Restart services:

.. prompt:: bash $

   sudo systemctl restart mev-boost.service
   sudo systemctl restart lighthouse-beacon.service

.. note::

   SSV operators should communicate their MEV relay preferences to stakers. The SSV WebApp allows operators to specify supported relays in their metadata.

Part 3: Staker Guide (Key Splitting)
------------------------------------

As a staker, you can split your validator keys and distribute them to SSV operators.

Step 1: Choose Operators
~~~~~~~~~~~~~~~~~~~~~~~~

Select 4 operators from the `SSV Explorer <https://explorer.ssv.network>`_. Consider:

- **Performance**: Historical attestation effectiveness
- **Fees**: Annual cost in SSV tokens
- **Infrastructure**: Geographic and client diversity
- **MEV Support**: Compatible relay configurations

Step 2: Split Validator Keys
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use the SSV Keys tool to split your existing validator keystore:

.. prompt:: bash $

   ssv-keys \
     --keystore /path/to/keystore-m_12381_3600_0_0_0.json \
     --password "your-keystore-password" \
     --operator-ids 1,2,3,4 \
     --operator-keys "LS0tLS...,LS0tLS...,LS0tLS...,LS0tLS..." \
     --owner-address 0xYOUR_WALLET_ADDRESS \
     --owner-nonce 0

This generates:

- ``keyshares-*.json``: Encrypted key shares for each operator

Step 3: Register Cluster
~~~~~~~~~~~~~~~~~~~~~~~~

1. Visit the `SSV WebApp <https://app.ssv.network>`_
2. Connect your wallet (must match owner-address)
3. Select "Add Cluster"
4. Upload your keyshares file
5. Fund your cluster with SSV tokens
6. Confirm the registration transaction

Your validator is now distributed across the selected operators!

DKG Ceremony (Alternative)
--------------------------

Distributed Key Generation (DKG) allows creating validator keys without any single party ever possessing the full private key. This is more secure than splitting existing keys.

.. note::

   DKG requires coordination between operators. Ensure all selected operators have DKG enabled before initiating.

For DKG ceremonies, operators must run the ``ssv-dkg`` tool. See the `SSV DKG Documentation <https://docs.ssv.network/developers/tools/ssv-dkg>`_ for detailed instructions.

Monitoring
----------

SSV exposes Prometheus metrics on port 15000. Key metrics to monitor:

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - Metric
     - Description
   * - ``ssv_p2p_connections_active``
     - Active P2P connections
   * - ``ssv_validator_consensus_duration_seconds``
     - Time to reach consensus
   * - ``ssv_validator_pre_consensus_duration_seconds``
     - Pre-consensus phase timing
   * - ``ssv_event_syncer_handler_last_processed_block``
     - Last processed Ethereum block

Configure Prometheus to scrape metrics:

.. code-block:: yaml

   - job_name: 'ssv'
     static_configs:
       - targets: ['localhost:15000']

Backup Procedures
-----------------

.. warning::

   Losing your SSV data directory may result in slashing if you attempt to run validators elsewhere. Always maintain secure backups.

Critical files to backup:

- ``/home/ethereum/.ssv/encrypted_private_key.json``: Operator identity
- ``/home/ethereum/.ssv/password.txt``: Key encryption password
- ``/home/ethereum/.ssv/db/``: Node database

To manually backup:

.. prompt:: bash $

   tar -czvf ssv-backup-$(date +%Y%m%d).tar.gz /home/ethereum/.ssv

Troubleshooting
---------------

**SSV node won't start**

- Check EL/CL endpoints are accessible and synced
- Verify operator keys exist in ``/home/ethereum/.ssv/``
- Check logs: ``journalctl -u ssv -f``

**P2P connection issues**

- Verify ports 12001/UDP and 13001/TCP are open
- Check firewall/router port forwarding
- Set ``HostAddress`` if behind NAT

**Validators not attesting**

- Check node health: ``curl http://localhost:16000/v1/node/health``
- Verify all cluster operators are online
- Check beacon node sync status

**High latency/missed duties**

- Ensure execution and consensus clients are local (not remote RPCs)
- Check network latency to other operators
- Consider enabling ``WithParallelSubmissions`` for redundancy

Testnet Setup
-------------

For testing on Hoodi or Sepolia testnets:

1. Edit configuration:

   .. code-block:: yaml

      ssv:
        Network: hoodi  # or sepolia

2. Use testnet EL/CL endpoints

3. Get testnet SSV tokens from the `SSV Faucet <https://faucet.ssv.network>`_

4. Register on the testnet WebApp

Further Resources
-----------------

- `SSV Network Documentation <https://docs.ssv.network>`_
- `SSV GitHub <https://github.com/ssvlabs/ssv>`_
- `SSV Explorer <https://explorer.ssv.network>`_
- `SSV Discord <https://discord.gg/ssvnetwork>`_
