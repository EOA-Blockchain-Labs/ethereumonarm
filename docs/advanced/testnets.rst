.. _running-testnets:

Running on Testnets
===================

Ethereum on ARM supports running clients on various testnets, allowing users to test setups, develop applications, or participate as validators without risking real funds.

Supported Testnets
------------------

The currently supported testnets across most clients are:

*   **Sepolia**: The recommended default testnet for application development.
*   **Hoodi**: The recommended testnet for staking and validator setups (replacing Holesky).

Service Naming Convention
-------------------------

To run a client on a specific testnet, Ethereum on ARM uses a simple service naming convention. Instead of the mainnet service name (e.g., ``geth``), you append the testnet name to the service.

**Format**: ``<client>-<network>``

Examples:
*   ``geth-sepolia``
*   ``lighthouse-beacon-hoodi``
*   ``prysm-validator-sepolia``

Supported Clients and Networks
------------------------------

The following table lists the availability of systemd services for each client and network.

Execution Layer Clients
~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header: Client, Sepolia Service, Hoodi Service
   :widths: 20, 25, 25

   `Geth`, `geth-sepolia`, `geth-hoodi`
   `Nethermind`, `nethermind-sepolia`, `nethermind-hoodi`
   `Besu`, `besu-sepolia`, `besu-hoodi`
   `Erigon`, `erigon-sepolia`, `erigon-hoodi`
   `Reth`, `reth-sepolia`, `reth-hoodi`
   `EthRex`, `ethrex-sepolia`, `ethrex-hoodi`

Consensus Layer Clients
~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header: Client, Sepolia Services, Hoodi Services
   :widths: 20, 25, 25

   `Lighthouse`, `lighthouse-beacon-sepolia`, `lighthouse-beacon-hoodi`
   `Prysm`, `prysm-beacon-sepolia`, `prysm-beacon-hoodi`
   `Nimbus`, `nimbus-beacon-sepolia`, `nimbus-beacon-hoodi`
   `Teku`, `teku-beacon-sepolia`, `teku-beacon-hoodi`
   `Grandine`, `grandine-beacon-sepolia`, `grandine-beacon-hoodi`
   `Lodestar`, `lodestar-beacon-sepolia`, `lodestar-beacon-hoodi`

.. note::
   Validator services follow the same pattern (e.g., ``lighthouse-validator-sepolia``). MEV-enabled services also exist (e.g., ``lighthouse-beacon-sepolia-mev``).

How to Run
----------

Running a client on a testnet is as simple as starting the corresponding systemd service.

**Example: Running Geth on Sepolia**

.. prompt:: bash $

  sudo systemctl start geth-sepolia

**Example: Running Lighthouse Beacon on Hoodi**

.. prompt:: bash $

  sudo systemctl start lighthouse-beacon-hoodi

Always check the logs to ensure the client is syncing correctly:

.. prompt:: bash $

  sudo journalctl -u geth-sepolia -f
