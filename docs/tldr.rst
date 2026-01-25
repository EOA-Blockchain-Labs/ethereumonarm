.. meta::
   :description lang=en: Quick summary of Ethereum on ARM. Learn the basics in 5 minutes.
   :keywords: tldr, quick start, ethereum node, arm, summary

TL;DR - Quick Summary
=====================

This page gives you a **fast overview** of Ethereum on ARM. Read this first if you want to understand what the project does and how to get started quickly.

What is Ethereum on ARM?
------------------------

Ethereum on ARM is a project that helps you run an **Ethereum node** on a small, cheap computer. These computers are called ARM boards (like Raspberry Pi or Rock 5B).

**In simple words:**

- We give you a ready-to-use operating system (based on Ubuntu)
- You flash it to a memory card
- You plug it into your ARM board
- Your node starts automatically

Why run your own node?
----------------------

Running your own Ethereum node:

- **Helps the network** - More nodes make Ethereum stronger
- **Gives you control** - You don't need to trust others
- **Saves money** - No cloud server fees
- **Uses little power** - ARM boards use 5-15 watts (like a light bulb)

What do you need?
-----------------

To run a node, you need:

1. **An ARM board** with 16GB of RAM

   - Rock 5B (recommended)
   - NanoPC T6 (recommended)
   - Orange Pi 5 Plus
   - Raspberry Pi 5

2. **A fast SSD** - 2TB NVMe drive (for storing blockchain data)

3. **A MicroSD card** - 16GB or more (for the operating system)

4. **Ethernet cable** - Wi-Fi is not recommended

5. **Power supply** - Check your board's requirements

How to get started?
-------------------

**Step 1: Download the image**

Go to our `releases page <https://github.com/EOA-Blockchain-Labs/ethereumonarm/releases>`_ and download the image for your board.

**Step 2: Flash the image**

Use a tool like `balenaEtcher <https://www.balena.io/etcher/>`_ to write the image to your MicroSD card.

**Step 3: Connect everything**

- Put the MicroSD card in your board
- Connect the NVMe SSD
- Connect the Ethernet cable
- Connect the power

**Step 4: Wait**

The first boot takes 10-15 minutes. The system will:

- Format your SSD
- Install all the software
- Set up your user account

**Step 5: Log in**

Find your board's IP address on your router. Then connect with SSH:

.. code-block:: bash

   ssh ethereum@<your-board-ip>
   # Default password: ethereum

**Step 6: Start your node**

Start an Execution Layer client (like Geth):

.. code-block:: bash

   sudo systemctl start geth

Start a Consensus Layer client (like Lighthouse):

.. code-block:: bash

   sudo systemctl start lighthouse

That's it! Your node is now running.

What clients can I use?
-----------------------

**Execution Layer** (choose one):

- Geth
- Nethermind
- Reth
- Erigon
- Besu

**Consensus Layer** (choose one):

- Lighthouse
- Prysm
- Teku
- Nimbus
- Lodestar
- Grandine

We recommend using **minority clients** to help decentralization.

How do I check if it works?
---------------------------

Check your client status:

.. code-block:: bash

   sudo systemctl status geth
   sudo systemctl status lighthouse

View the logs:

.. code-block:: bash

   sudo journalctl -u geth -f
   sudo journalctl -u lighthouse -f

Common questions
----------------

**How long does sync take?**

- Snap sync clients (Geth, Nethermind, Besu): 12-24 hours
- Execution sync clients (Reth, Erigon): 3-6 days
- Archive node: Several days to weeks

**Can I stake?**

Yes! See our :doc:`staking guide </staking/index>`.

**Something is not working. What do I do?**

See our :doc:`troubleshooting guide </system/troubleshooting>`.

**Where can I get help?**

- `Discord <https://discord.gg/ve2Z8fxz5N>`_ - Ask questions
- `GitHub <https://github.com/EOA-Blockchain-Labs/ethereumonarm/issues>`_ - Report bugs

Next steps
----------

Now that you understand the basics:

1. :doc:`Read the full installation guide </getting-started/installation>`
2. :doc:`Learn about managing clients </running-a-node/managing-clients>`
3. :doc:`Explore Layer 2 options </running-a-node/layer-2>`
4. :doc:`Set up monitoring </staking/index>`
