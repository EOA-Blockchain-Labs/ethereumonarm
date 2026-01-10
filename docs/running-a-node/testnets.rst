.. _running-testnets:

Running on Testnets
===================

Ethereum on ARM supports running clients on various testnets, allowing users to test setups, develop applications, or participate as validators without risking real funds.

Supported Testnets
------------------

The currently supported testnets across most clients are:

Sepolia
~~~~~~~

Sepolia is the recommended default testnet for application development. The Sepolia network uses a permissioned validator set controlled by client & testing teams.

**Why use Sepolia?**

*   Stable environment for contract and application developers.
*   Permissioned validator set ensures finality and reliability.

**Resources**

*   `Website <https://sepolia.otterscan.io/>`__
*   `GitHub <https://github.com/eth-clients/sepolia>`__
*   `Otterscan <https://sepolia.otterscan.io/>`__
*   `Etherscan <https://sepolia.etherscan.io/>`__
*   `Blockscout <https://eth-sepolia.blockscout.com/>`_

**Faucets**

*   `Alchemy Sepolia Faucet <https://sepoliafaucet.com/>`_
*   `Infura Sepolia Faucet <https://www.infura.io/faucet/sepolia>`_
*   `QuickNode Sepolia Faucet <https://faucet.quicknode.com/ethereum/sepolia>`_
*   `Google Cloud Web3 Sepolia Faucet <https://cloud.google.com/application/web3/faucet/ethereum/sepolia>`_
*   `PoW Faucet <https://sepolia-faucet.pk910.de/>`__

Hoodi
~~~~~

Hoodi is a testnet for testing validating and staking. The Hoodi network is open for users wanting to run a testnet validator. Stakers wanting to test protocol upgrades before they are deployed to mainnet should therefore use Hoodi.

**Why use Hoodi?**

*   **Open validator set**: Stakers can test running validators and network upgrades.
*   **Large state**: Useful for testing complex smart contract interactions.
*   **Realistic environment**: Mimics mainnet conditions, taking longer to sync and requiring more storage.

**Resources**

*   `Website <https://hoodi.ethpandaops.io/>`__
*   `GitHub <https://github.com/eth-clients/hoodi>`__
*   `Explorer <https://hoodi.beaconcha.in/>`_
*   `Checkpoint Sync <https://checkpoint-sync.hoodi.ethpandaops.io/>`_
*   `Otterscan <https://hoodi.otterscan.io/>`__
*   `Etherscan <https://hoodi.etherscan.io/>`__

**Faucets**

*   `Hoodi Faucet <https://faucet.hoodi.ethpandaops.io/>`_
*   `PoW Faucet <https://hoodi-faucet.pk910.de/>`__

Ephemery
~~~~~~~~

Ephemery is a unique kind of testnet that fully resets every month. The execution and consensus state reverts back to genesis every 28 days, which means anything that happens on the testnet is ephemeral.

**Why use Ephemery?**

*   **Always fresh state**: Ideal for short term testing, fast node bootstrap.
*   **Low resource requirements**: <5GB storage on average, quickest sync.
*   **Training ground**: Perfect for 'hello world' applications and practicing validator setups without long-term commitment.

.. note::
   Ethereum on ARM currenty does not provide pre-packaged services for Ephemery, but you can configure it manually using the generic client binaries.

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
   :align: left

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
   :align: left

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
