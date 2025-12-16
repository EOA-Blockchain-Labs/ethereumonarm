**Gnosis Chain** is one of the first Ethereum sidechains and stays true to the values of decentralized web3 ecosystem. It is an EVM-compatible execution-layer blockchain designed for low-cost, high-speed transactions, using **xDAI** (a stablecoin pegged to USD) for gas fees.

The network is secured by over 100,000 validators on the **Gnosis Beacon Chain**, making it one of the most decentralized and resilient networks. It mirrors Ethereum's architecture to ensure credible neutrality and robust security, governed by GnosisDAO.

Ethereum on ARM provides support for Gnosis Chain, allowing you to run your own node on ARM devices.

Quick Start Guide
-----------------

Setting up a Gnosis Chain node on Ethereum on ARM is straightforward. Since our images come with pre-installed clients, you only need to select and enable the Gnosis-specific services.

1. Install the OS
~~~~~~~~~~~~~~~~~

Follow our :doc:`Installation Guide </getting-started/installation>` to flash the Ethereum on ARM image to your device and perform the initial boot.

2. Select Your Clients
~~~~~~~~~~~~~~~~~~~~~~

Choose an Execution Client and a Consensus Client from the supported list below.

**Execution Layer**

*   **Erigon**: ``erigon-gnosis.service``
*   **Geth**: ``geth-gnosis.service``
*   **Nethermind**: ``nethermind-gnosis.service``
*   **Reth**: ``reth-gnosis.service``

**Consensus Layer**

*   **Lighthouse**: ``lighthouse-beacon-gnosis.service`` / ``lighthouse-validator-gnosis.service``
*   **Lodestar**: ``lodestar-beacon-gnosis.service`` / ``lodestar-validator-gnosis.service``
*   **Nimbus**: ``nimbus-beacon-gnosis.service`` / ``nimbus-validator-gnosis.service``
*   **Prysm**: ``prysm-beacon-gnosis.service`` / ``prysm-validator-gnosis.service``
*   **Teku**: ``teku-beacon-gnosis.service`` / ``teku-validator-gnosis.service``

3. Enable Services
~~~~~~~~~~~~~~~~~~

Enable and start the systemd services for your chosen client pair. This will automatically start the node and begin syncing the Gnosis Chain.

For example, to run **Nethermind** and **Lighthouse**:

.. code-block:: bash

    # Stop any default mainnet services if running (e.g., Geth)
    sudo systemctl stop geth lighthouse-beacon

    # Enable and start Gnosis services
    sudo systemctl enable --now nethermind-gnosis
    sudo systemctl enable --now lighthouse-beacon-gnosis

For more information on monitoring and managing these services, refer to the :doc:`Managing Clients </operation/managing-clients>` guide.

Configuration
-------------

The configuration files are located in ``/etc/ethereum/`` and differ from the mainnet configurations. They include the necessary bootnodes, network IDs, and check-point sync URLs specific to Gnosis Chain.

**Checkpoint Sync:**
Our packages are pre-configured with a default checkpoint sync URL. However, if you need to use a different endpoint, please use one of the following official endpoints:

*   **Gnosis Chain**: ``https://checkpoint.gnosischain.com``
*   **Chiado Testnet**: ``https://checkpoint.chiadochain.net``

For example:
*   **Erigon**: ``/etc/ethereum/erigon-gnosis.conf``
*   **Lighthouse**: ``/etc/ethereum/lighthouse-beacon-gnosis.conf``

4. Validator Setup (Optional)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you intend to run a validator, you must generate your validator keys and deposit GNO.

1.  **Generate Keys**: You can use the ``ethstaker-deposit-cli`` tool (available in our repositories) or follow the official Gnosis instructions.
2.  **Import Keys**: Import your validator keys into your Consensus Client (Lighthouse, Lodestar, etc.).
3.  **Deposit GNO**: Use the official Gnosis Deposit UI.

For detailed instructions on generating keys and making the deposit, please refer to the official Gnosis documentation:
`Gnosis Chain Validator Deposit <https://docs.gnosischain.com/node/manual/validator/deposit>`_

5. Chiado Testnet
~~~~~~~~~~~~~~~~~~~

Ethereum on ARM also allows you to run a node on the **Chiado Testnet**, the official testnet for Gnosis Chain. To do this, you need to modify the configuration files of your chosen clients.

**General Steps:**

1.  **Modify Network Flag**: Change the network flag in the configuration file from ``gnosis`` to ``chiado``.
    *    **Erigon / Reth**: Change ``--chain=gnosis`` to ``--chain=chiado``.
    *    **Nethermind**: Change to ``--config=chiado``.
    *    **Consensus Clients (Lighthouse, Lodestar, Teku, etc.)**: Change ``--network=gnosis`` to ``--network=chiado``.

2.  **Update Data Directory**: **Crucial Step**. You *must* change the data directory path to avoid corrupting your mainnet database.
    *   Change: ``--datadir /home/ethereum/.erigon-gnosis``
    *   To: ``--datadir /home/ethereum/.erigon-chiado``

3.  **Update Checkpoint Sync** (Consensus Layer): Change the checkpoint sync URL to a Chiado-compatible endpoint.
    *   Example: ``https://checkpoint.chiadochain.net``

**Example: Modifying Erigon for Chiado**

Open ``/etc/ethereum/erigon-gnosis.conf`` and update the lines:

.. code-block:: bash

    ARGS="--chain=chiado \
    --datadir=/home/ethereum/.erigon-chiado \
    ...

Then restart the service:

.. code-block:: bash

    sudo systemctl restart erigon-gnosis

You can do the same for your consensus client (e.g., ``lighthouse-beacon-gnosis.conf``).

Official Documentation
~~~~~~~~~~~~~~~~~~~~~~

For more in-depth information, architectural details, and advanced configurations, please verify the official Gnosis Chain documentation:
`Gnosis Chain Node Documentation <https://docs.gnosischain.com/node/>`_
