Lido Liquid Staking
===================

.. meta::
   :description lang=en: Lido Community Staking Module on ARM. Run a CSM operator with 1.5 ETH bond on NanoPC T6 or Rock 5B. Permissionless Ethereum staking.
   :keywords: Lido CSM, Community Staking Module, permissionless staking, Lido ARM, staking with less ETH

**Liquid Staking** refers to a decentralized protocol that allows users to stake their ETH, while simultaneously receiving 
a liquid token representing their staked assets.

When you stake **ETH** with Lido, **you receive a token called stETH, a liquid representation of your staked ETH**. The key 
innovation here is **liquidity—stETH tokens can be freely traded, utilized in DeFi applications, or held in wallets**, 
unlike traditionally locked staking that prevents users from accessing their funds until the lock-up period ends.

Lido Community Staking Module
-----------------------------

The Community Staking Module (CSM) is the Lido on Ethereum protocol's first module with **permissionless entry**, 
allowing any node operator and especially community stakers, from solo stakers, to groups of friends, to 
amateur operators to operate validators by providing an ETH-based safety deposit.

.. note::
  Lido **CSM allows any user to become a Home Staker with a fraction of ETH** necessary for a Vanilla validator (32 ETH), **contribute to the 
  network decentralization** and **receive a Liquid staking token** to use in Defi applications.

CSM v2 and Identified Community Stakers (ICS)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

With the launch of **CSM v2 in October 2025**, Lido introduced the **Identified Community Stakers (ICS)** program, 
which offers reduced bond requirements for verified community members. The stake share limit was also increased 
to 5%, improving validator activation times.

.. csv-table:: Bond Requirements
   :header: "Operator Type", "First Validator", "Additional Validators"
   :widths: 40, 30, 30

   "**ICS (Identified Community Stakers)**", "1.5 ETH", "1.3 ETH"
   "**General Operators**", "2.4 ETH", "1.3 ETH"

First step is to take a look to CSM, what it is and what we can expect from it:

`LIDO-CSM`_

.. _LIDO-CSM: https://operatorportal.lido.fi/modules/community-staking-module?pk_vid=dfd844e8ac98a6ab1744384064237bde#block-4a646a8613264067b77ea0a309c1e7c3

We prepared the clients with the appropiate config to make it easier to run a Lido Validator, 
but it is important for you to take a look at the Lido Portal, particularly, the **"Intro"** and **"Quick Start sections"** and 
make sure you understand how it works.

.. note::

  With CSM v2, the stake share limit has been increased to 5%. While validator activation times have improved, 
  there may still be delays during high-demand periods. Check the CSM portal for current queue status.

----

Staking Workflow
----------------

The Lido CSM staking process follows these steps:

1. **🖥️ Sync Full Node** - Run Ethereum EL+CL clients with MEV support
2. **🔑 Generate Keys** - Create validator keys with Lido withdrawal address
3. **📥 Import Keys** - Import keys to your validator client
4. **💰 Create Operator** - Register on CSM portal and deposit bond
5. **▶️ Start Validator** - Enable and monitor validator service

----

Critical Addresses
------------------

.. warning::

   **Setting the correct addresses is critical.** Incorrect configuration will result in penalties. 
   The Ethereum on ARM ``ls-lido`` package pre-configures these addresses, but you should verify them.

.. csv-table:: Mainnet Addresses
   :header: "Purpose", "Address"
   :widths: 30, 70

   "**Withdrawal Address**", "``0xB9D7934878B5FB9610B3fE8A5e441e8fad7E293f``"
   "**Fee Recipient**", "``0x388C818CA8B9251b393131C08a736A67ccB19297``"

.. csv-table:: Hoodi Testnet Addresses
   :header: "Purpose", "Address"
   :widths: 30, 70

   "**Withdrawal Address**", "``0x4473dCDDbf77679A643BdB654dbd86D67F8d32f2``"
   "**Fee Recipient**", "``0x9b108015fe433F173696Af3Aa0CF7CDb3E104258``"

These addresses are configured in the Lido-specific validator services (e.g., ``lighthouse-validator-lido``). 
If you're setting up manually or verifying configuration, ensure the addresses match.

----

Prerequisites
-------------

Before starting, ensure you have:

* A Full/Archive **Ethereum node synced** with MEV support
* A **MEV server** compatible with Lido
* A Lido Community Staking Module **(CSM) Operator**
* At least 1 CSM **validator key**
* A running **Validator Client** with Lido configuration
* Ethereum on ARM :guilabel:`ls-lido` package

.. note::
  These are instructions for mainnet but **you can test the Lido setup on hoodi testnet** by starting the corresponding 
  services and accessing the CSM testnet portal. Refer to the bottom of this page for more details.

  **We strongly recommend first running the CSM Lido setup on the hoodi testnet.** 

----

Step 1: Running a Full Ethereum Node
------------------------------------

.. warning::

  Remember, this setup requires an ARM64 device with the Ethereum on ARM image already installed.

Let's make sure the :guilabel:`ls-lido` is installed. Run on your node:

.. prompt:: bash $

  sudo apt-get update && sudo apt-get install ls-lido

First step is to **run a Full/Archive Ethereum node** (Full node is enough). This is the same process as running a vanilla node, the 
only difference is that we need to enable :guilabel:`MEV Boost` in the beacon chain and start a :guilabel:`MEV Boost`
server compatible with Lido.

**1.1** Choose a **Consensus Client** and an **Execution Client** and start both services. For instance:

.. prompt:: bash $

  sudo systemctl start nethermind
  sudo systemctl start lighthouse-beacon-mev

.. warning::

  Note that the Beacon Chain service includes the mev argument. Use it with any client, for instance 
  prysm-beacon-mev, teku-beacon-mev... This is necessary to enable MEV for running Lido.


**1.2** Start the MEV service:

.. prompt:: bash $

  sudo systemctl start mev-boost

----

Step 2: Creating Validator Keys
-------------------------------

Time to create the validator keys that will be used by your client to stake.

The ICS program, introduced with CSM v2, offers reduced bonds for verified community members. Check the CSM portal 
for eligibility requirements. Depending on your available ETH (and how much you are willing to stake), you can 
calculate how many validator keys you can create.

You have 2 main options for creating the validator keys:

Option A: Wagyu Key Generator (GUI)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use the **Wagyu key generator by Ethstaker** (which includes a GUI). Go to:

https://wagyu.gg

Download the appropiate binary for your desktop and follow the instructions.

.. warning::

   **CRITICAL**: Set the Lido withdrawal address: ``0xB9D7934878B5FB9610B3fE8A5e441e8fad7E293f``
   
   Do not forget to include the Lido withdrawal address as this is necessary to set up the Lido CSM properly. 
   Additionally, try to generate the keys offline by removing all network communications.

Option B: Command Line Deposit Tool
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can do it directly in your node and run deposit tool command (it is already installed), as ``ethereum`` user, run:

.. prompt:: bash $

  deposit new-mnemonic --num_validators $YOUR_NUMBER_VALIDATORS --chain mainnet --eth1_withdrawal_address 0xB9D7934878B5FB9610B3fE8A5e441e8fad7E293f

A ``validator_keys`` folder will be created containing all necessary files. Here you will need to copy and paste the ``deposit_data`` 
file content to your desktop in order to submit this data to the CSM Lido portal.

Alternatively, download the deposit tool to your desktop and run it there:

`ethstaker-deposit-cli`_

.. _ethstaker-deposit-cli: https://github.com/eth-educators/ethstaker-deposit-cli/releases

Follow the screen instructions and **make sure you write down the 12 words password**.

.. warning::

  **Make sure you write down the passphrase as this are your validators private keys and set the withdrawal address**.

Understanding Generated Files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The tools will create two file types:

.. csv-table::
   :header: "File", "Purpose"
   :widths: 30, 70

   "``keystore(s)``", "For importing your validator keys in your Validator client"
   "``deposit_data``", "For uploading the keys into the CSM module and making the deposit"

For more info regarding validator keys generation visit: `homestaker-validator-key-generation`_

.. _homestaker-validator-key-generation: https://dvt-homestaker.stakesaurus.com/keystore-generation-and-mev-boost/validator-key-generation

----

Step 3: Importing Keys and Starting the Validator
-------------------------------------------------

.. note::
  Before going forward, we recommend to take a look at our section **"Running a Validator Client"** for more info 
  about importing the validator keys on each client:

:ref:`running-validator-client-internal-alt`

Once we have our private keys, we can import them into our validator client and start it.

You need to log into your node and run the import command, depending on your client. For instance:

.. prompt:: bash $

  lighthouse account validator import --directory=/home/ethereum/validator_keys

Note that we assume that the ``keystore`` and ``deposit_data`` files are in the ``/home/ethereum/validator_keys`` directory. If 
you generated the keys in your desktop, you will need to copy them into your node.

Now it is time to start the validator. Make sure you add the argument ``lido`` in the validator service, for instance:

.. prompt:: bash $

  sudo systemctl start lighthouse-validator-lido

.. warning::

  **Don't forget to add the lido argument as it contains the specific config for Lido CSM**.

----

Step 4: Create and Activate the CSM Operator
--------------------------------------------

Now it is time to visit the CSM Lido portal:

https://csm.lido.fi

Follow these steps:

1. Click **"Become a Node Operator"**
   
   - ICS participants: minimum **1.5 ETH**
   - General operators: minimum **2.4 ETH**

2. **Accept the terms** and **choose your wallet** that will create the Operator and make the deposit

3. Click **"Create node operator"**

4. Paste the ``deposit_data`` file content into **"Upload deposit data"** form

5. **Confirm** and click **"Create Node Operator"**

6. **Confirm the transaction** in your wallet

Done! You are now running a CSM Lido Validator. Now, you need to wait for the Validator to get enabled.

.. note::

  With CSM v2, the stake share limit is now 5%. Activation times have improved, but check the CSM portal for current queue status.

----

Running CSM on Hoodi Testnet
----------------------------

Running CSM on ``hoodi`` is pretty much the same process but you need to make some adjustments.

**Step 1: Start Full Node**

Add the ``hoodi`` network on EL+CL client services:

.. prompt:: bash $

  sudo systemctl start nethermind-hoodi
  sudo systemctl start lighthouse-beacon-hoodi-mev

**Step 2: MEV Boost Service**

.. prompt:: bash $

  sudo systemctl start mev-boost-hoodi

**Step 3: Key Generation**

**Wagyu** tool supports ``hoodi`` so make sure you select this network.

For ``deposit`` command line, replace ``mainnet`` with ``hoodi``:

.. csv-table:: Hoodi Addresses
   :header: "Purpose", "Address"
   :widths: 30, 70

   "**Withdrawal Address**", "``0x4473dCDDbf77679A643BdB654dbd86D67F8d32f2``"
   "**Fee Recipient**", "``0x9b108015fe433F173696Af3Aa0CF7CDb3E104258``"

.. warning::

  **Be careful**: Lido withdrawal address for Hoodi is ``0x4473dCDDbf77679A643BdB654dbd86D67F8d32f2``

**Step 4: Key Import and Validator Start**

You will need to add the ``hoodi`` flag to target the correct network:

.. prompt:: bash $

  lighthouse account validator --network hoodi import --directory=/home/ethereum/validator_keys
  sudo systemctl start lighthouse-validator-hoodi-lido

Client-Specific Import Commands
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header: "Client", "Import Command"
   :widths: 20, 80

   "**Lighthouse**", "``lighthouse account validator --network hoodi import --directory=/home/ethereum/validator_keys``"
   "**Prysm**", "``validator accounts import --keys-dir=/home/ethereum/validator_keys --hoodi``"
   "**Teku**", "No need to specify the network as keys are not imported directly"
   "**Nimbus**", "``nimbus_beacon_node deposits import /home/ethereum/validator_keys --data-dir=/home/ethereum/.nimbus-validator``"

**Step 5: Lido Operator Portal**

Lido Operator Portal for Hoodi is:

https://csm.testnet.fi

----

Running CSM with Distributed Validators (DVT)
---------------------------------------------

For enhanced resilience and fault tolerance, you can run your Lido CSM validators using **Obol Distributed Validator Technology (DVT)**.

.. note::

   DVT allows multiple operators to run a single validator together, eliminating single points of failure.
   This is ideal for home stakers who want extra protection against downtime.

To run Lido CSM with Obol DVT:

1. **Set up your DVT cluster** following our :doc:`/staking/obol-dvt-setup` guide

2. **Use Lido withdrawal address** during DKG:

   .. csv-table::
      :header: "Network", "Withdrawal Address"
      :widths: 20, 80

      "Mainnet", "``0xB9D7934878B5FB9610B3fE8A5e441e8fad7E293f``"
      "Hoodi", "``0x4473dCDDbf77679A643BdB654dbd86D67F8d32f2``"

3. **Use Lido-specific DVT services** instead of regular DVT services:

.. prompt:: bash $

   sudo systemctl enable --now charon.service
   sudo systemctl enable --now lighthouse-validator-obol-lido.service

Available Lido DVT Validator Services
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header: "Service", "Description"
   :widths: 50, 50

   "``lighthouse-validator-obol-lido.service``", "Lighthouse with Lido + DVT"
   "``prysm-validator-obol-lido.service``", "Prysm with Lido + DVT"
   "``nimbus-validator-obol-lido.service``", "Nimbus with Lido + DVT"
   "``grandine-validator-obol-lido.service``", "Grandine with Lido + DVT"

These services are pre-configured with the Lido fee recipient address.

See :doc:`/staking/obol-dvt-setup` for complete DVT cluster setup instructions.
