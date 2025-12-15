Gnosis Chain Support
====================

**Gnosis Chain** is an EVM-compatible execution-layer blockchain designed to address Ethereum's scaling challenges. It functions as a sidechain that offers low-cost, high-speed transactions using **xDAI** (a stablecoin pegged to USD) for gas fees.

The network is secured by the **Gnosis Beacon Chain**, a Proof-of-Stake (PoS) consensus layer that mirrors Ethereum's architecture, ensuring robust security and credible neutrality. Gnosis Chain is governed by GnosisDAO, emphasizing community ownership and resilience.

Ethereum on ARM provides support for Gnosis Chain, allowing you to run your own node on ARM devices.

Supported Clients
-----------------

We support the following clients for Gnosis Chain on ARM:

Execution Layer
~~~~~~~~~~~~~~~

*   **Besu**: ``besu-gnosis.service``
*   **Geth**: ``geth-gnosis.service``
*   **Nethermind**: ``nethermind-gnosis.service``

Consensus Layer
~~~~~~~~~~~~~~~

*   **Lighthouse**: ``lighthouse-beacon-gnosis.service`` / ``lighthouse-validator-gnosis.service``
*   **Nimbus**: ``nimbus-beacon-gnosis.service`` / ``nimbus-validator-gnosis.service``
*   **Prysm**: ``prysm-beacon-gnosis.service`` / ``prysm-validator-gnosis.service``
*   **Teku**: ``teku-beacon-gnosis.service`` / ``teku-validator-gnosis.service``

Configuration
-------------

All our Gnosis packages come pre-configured for the Gnosis Chain. You generally do not need to modify the configuration files manually to connect to the network.

The configuration files are located in ``/etc/ethereum/`` and differ from the mainnet configurations. They include the necessary bootnodes, network IDs, and check-point sync URLs specific to Gnosis Chain.

For example:
*   **Geth**: ``/etc/ethereum/geth-gnosis.conf``
*   **Lighthouse**: ``/etc/ethereum/lighthouse-beacon-gnosis.conf``

You can check the specific configuration for your client by inspecting its corresponding file in that directory.
