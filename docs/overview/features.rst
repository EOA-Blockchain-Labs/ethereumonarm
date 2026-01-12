.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

.. meta::
   :description lang=en: Ethereum on ARM features. 33 packages, 6 execution clients, 6 consensus clients, Layer 2 support, Grafana monitoring, and APT repository.
   :keywords: Ethereum client software, Geth Nethermind ARM, Lighthouse Prysm validator, Layer 2 ARM, blockchain monitoring

Main Features
=============

Ethereum on ARM provides a complete, production-ready platform for running Ethereum nodes on ARM hardware. Our images transform simple ARM boards into powerful Ethereum infrastructure with enterprise-grade features and ease of use.

.. grid:: 1 2 2 3
   :gutter: 3

   .. grid-item-card:: 📦 33 Packages
      :text-align: center
      :class-card: sd-border-primary
      
      Actively maintained
      
   .. grid-item-card:: ✅ 97% Up-to-date
      :text-align: center
      :class-card: sd-border-success
      
      Latest upstream versions
      
   .. grid-item-card:: 🔄 APT Repository
      :text-align: center
      :class-card: sd-border-info
      
      Easy updates & management

Optimized System Foundation
----------------------------

**Base Operating System**

* **Ubuntu 24.04 LTS (Noble Numbat)** for ARM64 - Long-term stability and security
* **Custom kernel configuration** - Optimized for Ethereum node performance
* **Superior to stock OS** - Better than default Armbian or vanilla Ubuntu settings

**Storage & Memory**

* **Automatic NVMe partitioning** - Optimized for blockchain I/O requirements
* **Smart swap configuration** - Prevents OOM kills under heavy load
* **Filesystem tuning** - High-throughput settings for chain data

**Network & Security**

* **Automatic network setup** - Works out of the box
* **UFW firewall** - Pre-configured (disabled by default for custom policies)
* **Secure defaults** - Production-ready security settings

Comprehensive Client Support
-----------------------------

.. tab-set::

   .. tab-item:: ⚡ Execution Layer (6 Clients)
      
      All clients managed via systemd services with configuration in ``/etc/ethereum/``
      
      * **Geth** - Official Go implementation
      * **Nethermind** - High-performance .NET client
      * **Besu** - Enterprise Java client
      * **Reth** - Rust-based, modular client
      * **Erigon** - Efficiency-focused Go client
      * **EthRex** - Minimalist Rust implementation

   .. tab-item:: 🔮 Consensus Layer (6 Clients)
      
      Full validator support with beacon and validator services
      
      * **Lighthouse** - Rust, security-focused
      * **Prysm** - Go, feature-rich
      * **Nimbus** - Nim, resource-efficient
      * **Teku** - Java, enterprise-grade
      * **Lodestar** - TypeScript, developer-friendly
      * **Grandine** - Rust, high-performance

   .. tab-item:: 🌐 Layer 2 Solutions
      
      **Optimism/Base**
      
      * op-geth, op-node, op-reth
      
      **Arbitrum**
      
      * Nitro
      
      **Starknet**
      
      * Juno, Madara, Pathfinder
      
      **Fuel Network**
      
      * fuel-core
      
      See :doc:`../running-a-node/layer-2` for setup guides.

Package Management System
--------------------------

**Dedicated APT Repository**

* **Repository**: ``repo.ethereumonarm.com``
* **33 packages** actively maintained
* **97% up-to-date** with upstream releases
* **Automatic updates** via standard APT commands

**Easy Installation & Updates**

.. code-block:: bash

   sudo apt update
   sudo apt install geth lighthouse-beacon
   sudo systemctl start geth lighthouse-beacon

**Version Management**

* Install latest versions automatically
* Downgrade to specific versions when needed
* Browse packages at `apt.ethereumonarm.com/pool/main <https://apt.ethereumonarm.com/pool/main/>`_

See :doc:`../running-a-node/managing-clients` for detailed package management.

Service Management & Automation
--------------------------------

**Systemd Integration**

All clients run as systemd services with:

* **Automatic restart** on failure
* **Boot-time activation** (when enabled)
* **Centralized logging** via journalctl
* **Resource management** and limits

**Configuration Management**

* **Centralized configs**: ``/etc/ethereum/`` directory
* **Easy parameter changes**: Edit config files and restart
* **No manual service creation**: Everything pre-configured
* **Consistent structure**: Same pattern across all clients

**Example Operations**

.. code-block:: bash

   # Enable and start a client
   sudo systemctl enable geth
   sudo systemctl start geth
   
   # View logs
   sudo journalctl -u geth -f
   
   # Modify configuration
   sudo nano /etc/ethereum/geth.conf
   sudo systemctl restart geth

Advanced Monitoring & Metrics
------------------------------

**Grafana Dashboards**

* **Pre-configured dashboards** for all clients
* **Web interface**: ``http://your-ip:3000``
* **Default credentials**: admin / ethereum
* **Real-time metrics**: CPU, memory, disk, network
* **Client-specific metrics**: Peers, sync status, block height

**Prometheus Integration**

* **Automatic metrics collection** from all clients
* **Historical data** for trend analysis
* **Custom alerting** capabilities
* **Exporters included**: ethereum-metrics-exporter, validator-metrics-exporter

**Validator Monitoring**

* **Beaconcha.in integration** for validator tracking
* **Balance monitoring** and attestation performance
* **Status alerts** and effectiveness metrics
* **Easy setup** with API key configuration

See :doc:`../running-a-node/managing-clients` for monitoring setup.

Advanced Features
-----------------

**Distributed Validator Technology (DVT)**

* **Obol Charon** - Distributed validator middleware
* **SSV Network** - Secret Shared Validator infrastructure
* Enhance resilience and decentralization

**MEV Infrastructure**

* **MEV-Boost** - Proposer-builder separation
* **Commit-Boost** - Modular sidecar for commitments
* Maximize validator rewards

**Staking Tools**

* **EthStaker Deposit CLI** - Validator key generation
* **StakeWise Operator** - Liquid staking infrastructure  
* **Vero** - Remote signing for validators
* **Vouch** - Multi-node validator client

**Web3 Stack**

* **IPFS (Kubo)** - Decentralized storage
* **Swarm (Bee)** - Distributed storage and communication

**Testnet Support**

* **Sepolia** - Primary Ethereum testnet
* **Hoodi** - Pectra upgrade testnet
* **Ephemery** - Auto-resetting testnet
* Full client support for all testnets

Client Diversity
----------------

We actively promote **client diversity** to strengthen the Ethereum network:

* **Multiple implementations** in different languages
* **Easy switching** between clients
* **Minority client support** to prevent single-client dominance
* **Documentation** for all client combinations

See our :doc:`../running-a-node/layer-1` guide for client selection recommendations.

Community & Support
-------------------

* **Active Discord** community for help and discussion
* **Comprehensive documentation** with step-by-step guides
* **Regular updates** to keep pace with Ethereum development
* **Open source** - Contribute on GitHub
