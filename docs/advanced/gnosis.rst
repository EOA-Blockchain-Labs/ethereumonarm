Gnosis Chain
============

Gnosis Chain is one of the earliest Ethereum sidechains and remains true to the values of the decentralized Web3 ecosystem. It is an EVM-compatible execution-layer blockchain designed for low-cost, fast-finality transactions, using xDAI (a USD-pegged stablecoin) to pay for gas fees.

The network is secured by a large and highly decentralized validator set on the Gnosis Beacon Chain, making it one of the most resilient and decentralized Ethereum-aligned networks. Gnosis Chain mirrors Ethereum’s execution-layer and consensus-layer architecture to ensure credible neutrality and robust security, and it is governed by GnosisDAO.

Ethereum on ARM provides support for Gnosis Chain, allowing you to run your own node on ARM-based devices.

Gnosis Chain Support
--------------------

Setting up a Gnosis Chain node on Ethereum on ARM is straightforward. Since our images ship with pre-installed clients, you only need to select and enable the Gnosis-specific systemd services.

1. Install the OS
~~~~~~~~~~~~~~~~~

Follow the :doc:`Installation Guide </getting-started/installation>` to flash the Ethereum on ARM image to your device and complete the initial boot process.

2. Select Your Clients
~~~~~~~~~~~~~~~~~~~~~~

Choose one Execution Client and one Consensus Client from the supported list below.

Execution Layer
^^^^^^^^^^^^^^^

* Besu: ``besu-gnosis.service``
* Erigon: ``erigon-gnosis.service``
* Geth: ``geth-gnosis.service``
* Nethermind: ``nethermind-gnosis.service``
* Reth: ``reth-gnosis.service``

Consensus Layer
^^^^^^^^^^^^^^^

* Lighthouse: ``lighthouse-beacon-gnosis.service`` / ``lighthouse-validator-gnosis.service``
* Lodestar: ``lodestar-beacon-gnosis.service`` / ``lodestar-validator-gnosis.service``
* Nimbus: ``nimbus-beacon-gnosis.service`` / ``nimbus-validator-gnosis.service``
* Prysm: ``prysm-beacon-gnosis.service`` / ``prysm-validator-gnosis.service``
* Teku: ``teku-beacon-gnosis.service`` / ``teku-validator-gnosis.service``

3. Enable Services
~~~~~~~~~~~~~~~~~~

Enable and start the systemd services for your chosen client pair. This will automatically start the node and begin syncing the Gnosis Chain.

Example: Running Nethermind and Lighthouse

.. code-block:: bash

    # Stop any mainnet or Gnosis services if running
    sudo systemctl stop geth geth-gnosis lighthouse-beacon lighthouse-beacon-gnosis || true

    # Enable and start Gnosis Chain services
    sudo systemctl enable --now nethermind-gnosis
    sudo systemctl enable --now lighthouse-beacon-gnosis

For monitoring, logs, and lifecycle management, refer to the
:doc:`Managing Clients </operation/managing-clients>` guide.

Configuration
-------------

Configuration files are located in ``/etc/ethereum/`` and are separate from Ethereum mainnet configurations. They include Gnosis-specific network IDs, bootnodes, and checkpoint sync URLs.

Examples:

* Besu: ``/etc/ethereum/besu-gnosis.conf``
* Erigon: ``/etc/ethereum/erigon-gnosis.conf``
* Lighthouse: ``/etc/ethereum/lighthouse-beacon-gnosis.conf``

Checkpoint Sync
~~~~~~~~~~~~~~~

Ethereum on ARM packages include a default checkpoint sync configuration. If you need to override it, you may use the following official endpoints:

* Gnosis Chain: ``https://checkpoint.gnosischain.com``
* Chiado Testnet: ``https://checkpoint.chiadochain.net``

4. Validator Setup (Optional)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Running a validator is optional. A beacon-only node can be run without staking.

If you intend to run a validator, you must generate validator keys and deposit GNO.

1. Generate Keys  
   Use the ``ethstaker-deposit-cli`` tool (available in Ethereum on ARM repositories) or follow the official Gnosis instructions.

2. Import Keys  
   Import your validator keys into your chosen consensus client.

3. Deposit GNO  
   Make the deposit using the official Gnosis Deposit UI.

For complete instructions, refer to:
`Gnosis Chain Validator Deposit <https://docs.gnosischain.com/node/manual/validator/deposit>`_

Note:
Running a validator requires both a beacon node and a validator client to be enabled.

5. Chiado Testnet
~~~~~~~~~~~~~~~~~

Ethereum on ARM also supports Chiado, the official testnet for Gnosis Chain.

Chiado uses the same systemd services as Gnosis mainnet, but with modified configuration files and separate data directories.

General Steps
^^^^^^^^^^^^^

1. Modify Network Flag

   * Erigon / Reth: change ``--chain=gnosis`` to ``--chain=chiado``
   * Nethermind: change ``--config gnosis`` to ``--config chiado`` and ensure datadir is set (use ``-dd`` flag)
   * Consensus clients: change ``--network=gnosis`` to ``--network=chiado``

2. Update Data Directory (Crucial Step)

   You must use a different data directory to avoid corrupting your mainnet database.

   Example:

   * From: ``--datadir /home/ethereum/.erigon-gnosis``
   * To:   ``--datadir /home/ethereum/.erigon-chiado``

3. Update Checkpoint Sync (Consensus Layer)

   Use a Chiado-compatible endpoint:

   * ``https://checkpoint.chiadochain.net``

Example: Modifying Erigon for Chiado
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Edit ``/etc/ethereum/erigon-gnosis.conf``:

.. code-block:: bash

    ARGS="--chain=chiado \
    --datadir=/home/ethereum/.erigon-chiado \
    ..."

Then restart the service:

.. code-block:: bash

    sudo systemctl restart erigon-gnosis

Repeat the same process for your consensus client configuration.

Important:
Ethereum on ARM does not provide separate systemd units for Chiado. The same
``*-gnosis`` services are reused with Chiado-specific configuration and data paths.

Official Documentation
~~~~~~~~~~~~~~~~~~~~~~

For advanced configuration and architectural details, refer to the official Gnosis Chain documentation:

`Gnosis Chain Node Documentation <https://docs.gnosischain.com/node/>`_