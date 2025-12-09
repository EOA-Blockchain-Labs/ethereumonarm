.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Introduction
============

**Ethereum on ARM** provides custom Linux images for ARM boards (like the Rock 5B or NanoPC T6). These images make it easy for anyone to run a full, archive, or staking Ethereum node on affordable, low-power hardware.

Our Mission: Decentralization for Everyone
------------------------------------------

The health and safety of the Ethereum network depend on having many different nodes running around the world. Today, many nodes run on centralized cloud services or expensive computers. This creates risks for the network.

As stated in *Mastering Ethereum* by Andreas Antonopoulos and Gavin Wood:

   *"The health, resilience, and censorship resistance of blockchains depend on having many independently operated and geographically dispersed full nodes. Each full node can help other new nodes obtain the block data to bootstrap their operation, as well as offer the operator an authoritative and independent verification of all transactions and contracts."*

**Ethereum on ARM** helps solve this by:

*   **Making it Easy**: We provide a "Plug & Play" experience. You do not need to deal with complex installation or configuration.
*   **Lowering Costs**: You can build a complete node for much less money (often under $300) compared to a traditional server.
*   **Saving Energy**: ARM boards use very little electricity (about 10W). This makes it sustainable to run them at home 24/7.

What We Offer
-------------

We provide a ready-to-use operating system based on **Ubuntu 24.04 LTS**, designed specifically for Ethereum performance. 

Key features include:

*   **Optimized OS**: The system settings are tuned to handle blockchain data efficiently.
*   **Complete Software Stack**: Comes with all major Execution Clients (Besu, Erigon, EthRex, Geth, Nethermind, Nimbus, Reth) and Consensus Clients (Grandine, Lighthouse, Lodestar, Nimbus, Prysm, Teku).
*   **Layer 2 Support**: Native support for running nodes on Arbitrum, EthRex L2, Fuel, Optimism (Base), and Starknet.
*   **Easy Management**: Services run automatically. We provide a custom repository for easy updates and built-in dashboards (Grafana/Prometheus) to monitor your node.
*   **Ready for Staking**: Includes tools to generate keys and manage validators, compatible with technologies like DVT and Liquid Staking (Lido).

Why Run on ARM?
---------------

Running an Ethereum node on an ARM board offers clear benefits:

*   **Energy Efficient**: Uses a fraction of the power of a standard PC.
*   **Quiet**: Most boards have no fans or are very quiet, perfect for home use.
*   **Cost-Effective**: Low hardware and electricity costs.
*   **Compact**: The devices are small and take up very little space.

By running your own node on ARM, you help secure the Ethereum network and keep full control of your data.
