.. _running-testnets:

Running on Testnets
===================

Ethereum on ARM supports running clients on various testnets, allowing users to test setups, develop applications, or participate as validators without risking real funds.

Supported Testnets
------------------

The currently supported testnets across most clients are:

*   **Sepolia**: The recommended default testnet for application development.
*   **Hoodi**: The recommended testnet for staking and validator setups (replacing Holesky).
*   **Holesky**: **Deprecated**. Previous testnet for staking (sunset in Sep 2025).

.. warning::
   **Holesky is deprecated**. We recommend new users to choose **Hoodi** for any validator or staking testing.

Service Naming Convention
-------------------------

To run a client on a specific testnet, Ethereum on ARM uses a simple service naming convention. Instead of the mainnet service name (e.g., ``geth``), you append the testnet name to the service.

**Format**: ``<client>-<network>``

Examples:
*   ``geth-sepolia``
*   ``lighthouse-beacon-holesky``
*   ``prysm-validator-sepolia``

Supported Clients and Networks
------------------------------

The following table lists the availability of systemd services for each client and network.

Execution Layer Clients
~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header: Client, Sepolia Service, Holesky Service, Hoodi Service
   :widths: 20, 25, 25, 25

   `Geth`, `geth-sepolia`, `geth-holesky`, `geth-hoodi`
   `Nethermind`, `nethermind-sepolia`, `nethermind-holesky`, `nethermind-hoodi`
   `Besu`, `besu-sepolia`, `besu-holesky`, `besu-hoodi`
   `Erigon`, `erigon-sepolia`, `erigon-holesky`, `erigon-hoodi`
   `Reth`, `reth-sepolia`, `reth-holesky`, `reth-hoodi`
   `EthRex`, `ethrex-sepolia`, `ethrex-holesky`, `ethrex-hoodi`

Consensus Layer Clients
~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header: Client, Sepolia Services, Holesky Services, Hoodi Services

   `Lighthouse`, `lighthouse-beacon-sepolia`, `lighthouse-beacon-holesky`, `lighthouse-beacon-hoodi`
   `Prysm`, `prysm-beacon-sepolia`, `prysm-beacon-holesky`, `prysm-beacon-hoodi`
   `Nimbus`, `nimbus-beacon-sepolia`, `nimbus-beacon-holesky`, `nimbus-beacon-hoodi`
   `Teku`, `teku-beacon-sepolia`, `teku-beacon-holesky`, `teku-beacon-hoodi`
   `Grandine`, `grandine-beacon-sepolia`, `grandine-beacon-holesky`, `grandine-beacon-hoodi`
   `Lodestar`, `lodestar-beacon-sepolia`, `lodestar-beacon-holesky`, `lodestar-beacon-hoodi`

.. note::
   Validator services follow the same pattern (e.g., ``lighthouse-validator-sepolia``). MEV-enabled services also exist (e.g., ``lighthouse-beacon-sepolia-mev``).

How to Run
----------

Running a client on a testnet is as simple as starting the corresponding systemd service.

**Example: Running Geth on Sepolia**

.. prompt:: bash $

  sudo systemctl start geth-sepolia

**Example: Running Lighthouse Beacon on Holesky**

.. prompt:: bash $

  sudo systemctl start lighthouse-beacon-holesky

Always check the logs to ensure the client is syncing correctly:

.. prompt:: bash $

  sudo journalctl -u geth-sepolia -f
