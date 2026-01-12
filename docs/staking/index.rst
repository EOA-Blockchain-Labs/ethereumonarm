.. _staking-guide:

.. meta::
   :description lang=en: Ethereum staking on ARM hardware. Solo staking with 32 ETH, Lido CSM, Obol DVT, and validator migration guides for home validators.
   :keywords: Ethereum staking, solo staking, home validator, 32 ETH deposit, proof of stake rewards

Staking Guide
=============

Run a validator and earn rewards by securing the Ethereum network.

.. warning::
   Staking involves real financial risk. You can lose ETH through slashing if you run the same keys on multiple machines or behave maliciously.

.. grid:: 1 2 2 2
   :gutter: 3

   .. grid-item-card:: 🔒 Solo Staking
      :link: /staking/solo-staking
      :link-type: doc
      :class-card: sd-border-primary

      Run your own validator with 32 ETH.
      
      +++
      :bdg-success:`Recommended`

   .. grid-item-card:: 🌊 Lido CSM
      :link: /staking/lido
      :link-type: doc
      :class-card: sd-border-info

      Community Staking Module for smaller stakers.

   .. grid-item-card:: 🔗 Obol DVT
      :link: /staking/obol-dvt-setup
      :link-type: doc
      :class-card: sd-border-warning

      Distributed Validator Technology for fault tolerance.
      
      +++
      :bdg-info:`Advanced`

   .. grid-item-card:: 🔄 Migrate Validator
      :link: /staking/migrate-validator
      :link-type: doc
      :class-card: sd-border-secondary

      Move your validator to a new machine safely.

Staking Overview
----------------

**Solo staking** is the gold standard for Ethereum decentralization. By running your own validator, you:

- 💰 Earn ~4-5% APY on your staked ETH
- 🏛️ Contribute to network security and decentralization
- 🔐 Maintain full control of your keys
- 🚫 Avoid third-party custody risks

Requirements
~~~~~~~~~~~~

.. csv-table::
   :align: left
   :header: Requirement, Details

   ETH, 32 ETH per validator
   Hardware, 16GB RAM ARM board + 2TB NVMe
   Network, 24/7 stable internet connection
   Knowledge, Basic Linux and command line skills

Staking Workflow
----------------

.. code-block:: text

   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
   │  Generate   │ →  │  Deposit    │ →  │   Import    │ →  │   Start     │
   │    Keys     │    │   32 ETH    │    │    Keys     │    │  Validator  │
   └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘

1. **Generate Keys** - Use ethstaker-deposit-cli
2. **Deposit 32 ETH** - Via Ethereum Launchpad
3. **Import Keys** - To your validator client
4. **Start Validator** - Enable systemd service

.. tip::
   **Test first!** Practice on the Hoodi testnet before staking real ETH.
   
   :doc:`Testnet guide → </running-a-node/testnets>`

Alternative Staking Options
---------------------------

.. dropdown:: Lido Community Staking Module (CSM)
   :icon: people

   Stake with less than 32 ETH by joining the Lido CSM:

   - Lower capital requirement (1.5 ETH bond)
   - Share in protocol rewards
   - Community-operated

   :doc:`Lido CSM guide → </staking/lido>`

.. dropdown:: Distributed Validator Technology (DVT)
   :icon: share

   Split your validator across multiple machines for:

   - Fault tolerance (survive hardware failures)
   - Increased uptime
   - Distributed trust

   :doc:`Obol DVT guide → </staking/obol-dvt-setup>`

.. seealso::

   - :doc:`/running-a-node/layer-1` - L1 node setup
   - :doc:`/advanced/mev-boost` - Maximize validator rewards
   - :doc:`/system/backup-restore` - Protect your keys
