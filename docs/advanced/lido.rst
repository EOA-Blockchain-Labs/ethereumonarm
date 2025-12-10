Lido Liquid Staking
===================

**Liquid Staking** refers to a decentralized protocol that allows users to stake their ETH, while simultaneously receiving 
a liquid token representing their staked assets.

When you stake **ETH** with Lido, **you receive a token called stETH, a liquid representation of your staked ETH**. The key 
innovation here is **liquidity—stETH tokens can be freely traded, utilized in DeFi applications, or held in wallets**, 
unlike traditionally locked staking that prevents users from accessing their funds until the lock-up period ends.

**Lido Community Staking Module**

The Community Staking Module (CSM) is the Lido on Ethereum protocol's first module with **permissionless entry**, 
allowing any node operator — and especially community stakers, from solo stakers, to groups of friends, to 
amateur operators — to operate validators by providing an ETH-based safety deposit.

.. note::
  Lido **CSM allows any user to become a Home Staker with a fraction of ETH** necessary for a Vanilla validator (2.3), **contribute to the 
  network decentralization** and **receive a Liquid staking token** to use in Defi applications.

Lido CSM
~~~~~~~~

First step is to take a look to CSM, what it is and what we can expect from it:

`LIDO-CSM`_

.. _LIDO-CSM: https://operatorportal.lido.fi/modules/community-staking-module?pk_vid=dfd844e8ac98a6ab1744384064237bde#block-4a646a8613264067b77ea0a309c1e7c3

We prepared the clients with the appropiate config to make it easier to run a Lido Validator, 
but it is important for you to take a look at the Lido Portal, particularly, the **"Intro"** and **"Quick Start sections"** and 
make sure you understand how it works.

.. warning::

  As of today (2Q 2025), **CSM has reached its stake share limit so your validator won't be activated until this limit is increased**. Stay 
  tuned with Lido updates. You can still upload keys, but they are very unlikely to receive deposits in the near 
  future (possibly for months).

Prerrequisites
~~~~~~~~~~~~~~

- A Full/Archive **Ethereum node synced** with MEV support
- A **MEV server** compatible with Lido
- A Lido Community Staking Module **(CSM) Operator**
- At least 1 CSM **validator key**
- A running **Validator Client** with Lido configuration
- Ethereum on ARM :guilabel:`ls-lido` package

.. note::
  These are instructions for mainnet but **you can test the Lido setup on hoodi testnet** by starting the corresponding 
  services and accessing the CSM testnet portal. Refer to the bottom of this page for more details.

  **We strongly recommend first running the CSM Lido setup on the hoodi testnet.** 

Running a Full Ethereum node
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. warning::

  Remember, this setup requires an ARM64 device with the Ethereum on ARM image already installed.

Let's make sure the :guilabel:`ls-lido` is installed. Run on your node:

.. prompt:: bash $

  sudo apt-get update && sudo apt-get install ls-lido

First step is to **run a Full/Archive Ethereum node** (Full node is enough). This is the same process as running a vanilla node, the 
only difference is that we need to enable :guilabel:`MEV Boost` in the beacon chain and start a :guilabel:`MEV Boost`
server compatible with Lido.

1. Choose a **Consensus Client** and an **Execution Client** and start both services. For instance:

.. prompt:: bash $

  sudo systemctl start nethermind
  sudo systemctl start lighthouse-beacon-mev

.. warning::

  Note that the Beacon Chain service includes the mev argument. Use it with any client, for instance 
  prysm-beacon-mev, teku-beacon-mev... This is necessary to enable MEV for running Lido.


2. Once start the MEV service:

.. prompt:: bash $

  sudo systemctl start mev-boost

Creating validator keys
~~~~~~~~~~~~~~~~~~~~~~~

Time to create the validator keys that will be used by your client to stake.

**You will need at least 2.4 ETH for the first validator and 1.3 ETH for each Additional validator**. Depending on your available ETH 
(and how much you are willing to stake), you can calculate how many validator keys you can create.

You have 2 main options for creating the validator keys:

1. Use the **Wagyu key generator by Ethstaker** (which includes a GUI).  Go to:

https://wagyu.gg

Download the appropiate binary for your desktop and follow the instructions. 
**Remember to put here the Lido withdrawal address**: ``0xB9D7934878B5FB9610B3fE8A5e441e8fad7E293f``

.. warning::

  **Do not forget to include the Lido withdrawal address** as this is necessary to set up the Lido CMS properly. Additionally, 
  try to generate the keys offline by removing all network communications.

2. Use the command line deposit tool. 2 options here:

- You can do it directly in your node and run deposit tool command (it is already installed), as ``ethereum`` user, run:

.. prompt:: bash $

  deposit new-mnemonic --num_validators $YOUR_NUMBER_VALIDATORS --chain mainnet --eth1_withdrawal_address 0xB9D7934878B5FB9610B3fE8A5e441e8fad7E293f

A ``validator_keys`` folder will be created containing all necessary files. Here you will need to copy and paste the ``deposit_data`` 
file content to your desktop in order to submit this data to the CSM Lido portal.

- Download the deposit tool to your desktop and run it there. Same with folder and contents:

`ethstaker-deposit-cli`_

.. _ethstaker-deposit-cli: https://github.com/eth-educators/ethstaker-deposit-cli/releases

Follow the screen instructions in both cases and **make sure you write down the 12 words password**.

.. warning::

  **Make sure you write down the passphrase as this are your validators private keys and set the withdrawal address**.

Now, in any case, the tools will create two file types (a ``keystore(s)`` file(s) depending on the number of validators and a ``deposit_data`` file). 
The ``keystore(s)`` is/are for importing your validator keys in your Validator client. The ``deposit_data`` file is for uploading 
the keys into the CSM module and making the corresponding deposit.

For more info regarding validator keys generation visit this site:

`homestaker-validator-key-generation`_

.. _homestaker-validator-key-generation: https://dvt-homestaker.stakesaurus.com/keystore-generation-and-mev-boost/validator-key-generation

Importing the keys and starting the validator
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

Create and Activate the CSM operator
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now it is time to visit the CSM Lido portal

https://csm.lido.fi

1. Clic in **"Become a Node Operator"**. Make sure you have at least **2.4** ETH. 

2. **Accept the terms** and **choose your wallet** that will create the Operator and make the deposit.

3. Clic **"Create node operator"**.

4. Now, paste the ``deposit_data`` file content into **"Upload deposit data"** form.

5. **Confirm** and clic **"Create Node Operator"**.

6. **Confirm the transaction** in your wallet.

Done, you are now running a CSM Lido Validator. Now, you need to wait for the Validator to get enabled. 

.. warning::

  Remember that, currently, CSM Lido has reached its stake share limit so it won't be activated unless this limits get increased.

Running CSM on Hoodi testnet
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Running CSM on ``hoodi`` is pretty much the same process but you need to make some adjustments.

1. For the full node, add the ``hoodi`` network on EL+CL client services, for instance:

.. prompt:: bash $

  sudo systemctl start nethermind-hoodi
  sudo systemctl start lighthouse-beacon-hoodi-mev

2. MEV boost service:

.. prompt:: bash $

  sudo systemctl start mev-boost-hoodi

3. Key generation. **Wagyu** tool supports ``hoodi`` so make sure you select this network.

Regarding ``deposit`` command line, replace ``mainnet`` for ``hoodi``. **Make sure to set this withdrawal 
address** in both cases to: ``0x4473dCDDbf77679A643BdB654dbd86D67F8d32f2``

.. warning::

  **Again, be careful, Lido withdrawal address for Hoodi is 0x4473dCDDbf77679A643BdB654dbd86D67F8d32f2**

4. Key import and validator start.

In both cases (command import and service start). You will need to add the ``hoodi`` flag to target the correct network. For instance:

.. prompt:: bash $

  lighthouse account validator --network hoodi import --directory=/home/ethereum/validator_keys
  sudo systemctl start lighthouse-validator-hoodi-lido

.. note::
  These are the commands for specifying the ``hoodi`` testnet in the validator clients:

.. prompt:: bash $

  Lighthouse: lighthouse account validator --network hoodi import --directory=/home/ethereum/validator_keys
  Prysm: validator accounts import --keys-dir=/home/ethereum/validator_keys --hoodi 
  Teku: No need to specify the network as keys are not imported directly
  Nimbus: nimbus_beacon_node deposits import /home/ethereum/validator_keys --data-dir=/home/ethereum/.nimbus-validator (no need to specify the network)

5. Lido Operator Portal for Hoodi is:

https://csm.testnet.fi
