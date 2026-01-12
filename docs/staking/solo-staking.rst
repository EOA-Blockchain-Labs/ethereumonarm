Solo Staking
============

.. meta::
   :description lang=en: Complete solo staking guide for Ethereum on ARM. Generate validator keys, deposit 32 ETH, import keys, and run validators with Lighthouse, Prysm, or Teku.
   :keywords: solo staking guide, ethstaker-deposit-cli, 32 ETH validator, Ethereum launchpad, home staking

.. warning::

  **DISCLAIMER**: Ethereum is an experimental technology. **Running the Ethereum on ARM image as
  a Consensus Layer validator node can lead you to ETH loss**. This is a risky operation and you
  alone are responsible for your actions using the Ethereum software included in this image
  or following the instructions of this guide.

  We strongly recommend to try first a Consensus Layer testnet and get
  familiarized with the process before staking real ETH.

  **REMEMBER: Staking is NOT necessary for running a full Ethereum node**. For this, you just need a 
  synced Execution Client running along with a synced Consensus Layer Beacon Chain.

Ethereum staking is the process of participating in the proof-of-stake (PoS) consensus mechanism 
of the Ethereum network by locking up 32 ETH in the validator deposit contract. Staking serves as 
a way to secure the network, validate transactions, and create new blocks on the Ethereum blockchain, 
while also rewarding participants for their contributions.

Staking Workflow
----------------

The staking process follows these steps:

1. **🔑 Generate Keys** - Use ethstaker-deposit-cli to create validator keys
2. **💰 Deposit 32 ETH** - Submit deposit via Ethereum Launchpad
3. **📥 Import Keys** - Import keys to your validator client
4. **▶️ Start Validator** - Enable and monitor validator service

In order to stake you need to set up a Validator Client that will propose blocks and do attestations 
according to the Consensus Layer specification (proposing a block would be the equivalent to "mine" a block 
in the former Proof of Work Ethereum chain).

The validator client is included in all Consensus Layer clients along with the Beacon Chain clients.

.. warning::

  There is a chance of losing your ETH if your validator does something wrong (this is 
  called being slashed), so be extremely careful and always follow the protocol 
  specification.

  And **never (EVER)** run the same validator keys in two different nodes at the same time. 
  **You will be slashed**.

Staking Requirements
--------------------

In order to stake and run a validator you will need:

  * 32 ETH
  * A synced Ethereum Execution Layer client
  * A synced Ethereum Consensus Layer client consisting of: A Beacon Chain instance and a 
    Validator instance (with one or more validator keys)

Before making the 32 ETH deposit you need to create 2 key pairs and a Json file with the 
necessary information to interact with the mainnet staking contract through a transaction.

The community provides a tool (ethstaker-deposit-cli) to create the keys and the 
deposit information (which among others contains your validator(s) public key(s)). This 
tool is already installed in your Ethereum on ARM node. If you are running an older image 
please, run:

.. prompt:: bash $

  sudo apt-get update
  sudo apt-get install ethstaker-deposit-cli

.. warning::
   **Important: Tool Update**
   
   The original ``staking-deposit-cli`` from the Ethereum Foundation has been **deprecated**. 
   The official repository now recommends using ``ethstaker-deposit-cli``, which is an 
   actively maintained fork by the ETHStaker community. 
   
   See: `ethstaker-deposit-cli <https://github.com/eth-educators/ethstaker-deposit-cli>`_

Additionally, the Ethereum Foundation developed a web Launchpad to walk you through the staking process. 
Here you can upload the Deposit Json file and make the 32 ETH transaction 
with your wallet or a web3 wallet (such as Metamask or Wallet Connect).

Validator setup
---------------
.. note::
  Remember that you need 32 ETH for each validator you want to run.

The validator setup is client agnostic so it will be valid for all Consensus Layer clients.

.. note::
  At this point, you should have an Execution Layer + Consensus Layer clients combo in sync (both clients 
  running along one 1 on 1).
  
The first step is to visit the EF Launchpad website to start the process:

`https://launchpad.ethereum.org`_

.. _https://launchpad.ethereum.org: https://launchpad.ethereum.org

1. Click **“Become a validator”**

2. Read carefully and accept all warnings. 
   
3. You can skip the **Execution Client** selection as all clients are already installed and configured. click 
   "Continue"

4. Same for the **Consensus Clients**. Click "Continue"

5. In the next screen, select the number of validators you want to run. Remember that you need 
   32 ETH for each one.

6. Ethereum on ARM provides the ethstaker-deposit-cli tool to generate the keys and 
set the withdrawal address (where the staked ETH will be deposited periodically). so, 
**in your terminal** and under the ethereum account, run (assuming 1 validator):

.. prompt:: bash $

    cd && deposit new-mnemonic --num_validators 1 --execution_address YOUR_ETH_ADDRESS --chain mainnet

7. You will see a warning about the withdrawal address. Please, **make sure you have control over the 
address you are setting. Otherwise you won't be able to withdraw your ETH and the staked ETH.**

Choose your mnemonic language and type a password for keeping your keys safe.

.. warning::

  Now, **Make sure you wrote down the mnemonic in a safe place**. Without it you will NOT be
  able to withdraw your ETH in the future.

  **Again, please, make sure your mnemonic is safe!!!**

Write down your mnemonic password, press any key and type it again as requested.

8. Now you have 2 JSON files under the ``validator_keys`` directory:

  * A deposit data file for making the 32 ETH transaction to the mainnet (which contains 
    your validator public key as well).
  * A keystore file with your validator keys that will be used by your Consensus Layer 
    client.

9. Back to the Launchpad website, check **"I am keeping my keys safe and have written down 
my mnemonic phrase"** and click **"Continue"**.

.. warning::

  Again, **make sure you have both an Execution Layer client + a Consensus Layer client synced, 
  running along and properly configured**.

10. It is time to send the 32 ETH deposit to the Ethereum mainnet contract. You need the 
deposit file (located in your Board). You can, either copy and paste the 
file content and save it as a new JSON file in your desktop computer or copy the file 
from the Raspberry to your desktop through SSH.

.. tabs::

  .. tab:: Copy and Paste

     Connected through SSH to your Raspberry Pi, type:

     .. prompt:: bash $

        cat validator_keys/deposit_data-$FILE-ID.json (replace $FILE-ID with yours)

     Copy the content (the text in square brackets), go back to your desktop, paste it 
     into your favourite editor and save it as a json file.

  .. tab:: SCP (SSH remote copy)

     Pull the file from your desktop through SSH, copy the file:

     .. prompt:: bash $

        scp ethereum@$YOUR_RASPBERRYPI_IP:/home/ethereum/validator_keys/deposit_data-$FILE_ID.json /tmp

     Replace the variables (``$YOUR_RASPBERRYPI_IP`` and ``$FILE_ID``) with your data. 
     This command will copy the file to your desktop computer ``/tmp`` directory.

11. Now, back to the Launchpad website, upload the ``deposit_data`` file and select 
Metamask, click continue and check all warnings. Click "Continue" and click 
**“Initiate the Transaction”**. Confirm the transaction in Metamask and wait 
for the confirmation (a notification will pop up shortly).

The Beacon Chain (which is connected to the Execution Layer client) will detect 
this deposit and the Validator will be enabled.

12. Go back to your chosen validator client, import the keys located in the ``validator_keys`` directory 
and start the service (check the specific client documentation above for further instructions).

Congrats!, you just started your validator activation process.

.. _running-validator-client-internal-alt:

Running Validator Client
------------------------

Once the Beacon Chain is synchronized and we have our keys and deposit created, we need to start the Validator Client. 
Choose the tab for the client you are using:

.. tab-set::

   .. tab-item:: Lighthouse

      Import the previously generated validator keys:

      .. prompt:: bash $

        lighthouse account validator import --directory=/home/ethereum/validator_keys

      Enter your password when prompted. Then set the fee recipient address:

      .. prompt:: bash $

        sudo sed -i 's/changeme/0x1234567890abcdef1234567890abcdef12345678/' /etc/ethereum/lighthouse-validator.conf

      Replace ``0x1234567890abcdef1234567890abcdef12345678`` with your actual Ethereum address.

      Start the validator service:

      .. prompt:: bash $

        sudo systemctl start lighthouse-validator

      The Lighthouse Validator is now started.

   .. tab-item:: Prysm

      Import the validator keys:

      .. prompt:: bash $

        validator accounts import --keys-dir=/home/ethereum/validator_keys

      Accept the default wallet path and enter a password for your wallet, then enter the password you defined earlier.

      Set the fee recipient address:

      .. prompt:: bash $

        sudo sed -i 's/changeme/0x1234567890abcdef1234567890abcdef12345678/' /etc/ethereum/prysm-validator.conf

      Replace ``0x1234567890abcdef1234567890abcdef12345678`` with your actual Ethereum address.

      Set up your password file and start the validator:

      .. prompt:: bash $

        echo "$YOUR_PASSWORD" > /home/ethereum/validator_keys/prysm-password.txt
        sudo systemctl start prysm-validator

      The Prysm validator is now enabled.

   .. tab-item:: Nimbus

      Import your validator keys:

      .. prompt:: bash $

        nimbus_beacon_node deposits import /home/ethereum/validator_keys --data-dir=/home/ethereum/.nimbus-validator --log-file=/home/ethereum/.nimbus-validator/nimbus.log

      Enter the password you defined earlier.

      Set the fee recipient address:

      .. prompt:: bash $

        sudo sed -i 's/changeme/0x1234567890abcdef1234567890abcdef12345678/' /etc/ethereum/nimbus-validator.conf

      Replace ``0x1234567890abcdef1234567890abcdef12345678`` with your actual Ethereum address.

      Start the Nimbus Validator:

      .. prompt:: bash $

        sudo systemctl start nimbus-validator

   .. tab-item:: Teku

      Create a password file for each validator keystore. The file must have the same name as the keystore with a ``.txt`` extension.

      View your keystore files:

      .. prompt:: bash $

        ls /home/ethereum/validator_keys

      Create password file (replace ``$KEYSTORE_NAME`` with your actual keystore filename):

      .. prompt:: bash $

        echo "$YOUR_PASSWORD" > validator_keys/$KEYSTORE_NAME.txt

      You should now have matching files like:

      .. code-block:: text

        keystore-m_12381_3600_0_0_0-1661710189.json
        keystore-m_12381_3600_0_0_0-1661710189.txt

      Set the fee recipient address:

      .. prompt:: bash $

        sudo sed -i 's/changeme/0x1234567890abcdef1234567890abcdef12345678/' /etc/ethereum/teku-validator.conf

      Replace ``0x1234567890abcdef1234567890abcdef12345678`` with your actual Ethereum address.

      Start the Teku Validator:

      .. prompt:: bash $

        sudo systemctl start teku-validator

      The Teku Validator is now enabled.

   .. tab-item:: Lodestar

      Import the validator keys:

      .. prompt:: bash $

        lodestar validator import --importKeystores /home/ethereum/validator_keys --dataDir /home/ethereum/.lodestar

      Enter the password you defined earlier.

      Set the fee recipient address:

      .. prompt:: bash $

        sudo sed -i 's/changeme/0x1234567890abcdef1234567890abcdef12345678/' /etc/ethereum/lodestar-validator.conf

      Replace ``0x1234567890abcdef1234567890abcdef12345678`` with your actual Ethereum address.

      Start the Lodestar Validator service:

      .. prompt:: bash $

        sudo systemctl start lodestar-validator

   .. tab-item:: Grandine

      .. warning::

        Make sure you are NOT running the **grandine-beacon** service before starting **grandine-validator**

      Set the fee recipient address:

      .. prompt:: bash $

        sudo sed -i 's/changeme/0x1234567890abcdef1234567890abcdef12345678/' /etc/ethereum/grandine-validator.conf

      Replace ``0x1234567890abcdef1234567890abcdef12345678`` with your actual Ethereum address.

      Set up your password file and start the validator:

      .. prompt:: bash $

        echo "$YOUR_PASSWORD" > /home/ethereum/validator_keys/grandine-password.txt
        sudo systemctl start grandine-validator

      The Grandine validator is now enabled. Wait for the Beacon Chain to sync and check the logs for further info.

   .. tab-item:: Vouch

      :guilabel:`Vouch` is a multi-node validator client written in Go.

      .. csv-table::
        :header: Systemd Services, Home Directory, Config Files, Ports

        `vouch`, `/home/ethereum/.vouch`, `/etc/ethereum/vouch.yml`, `None`

      Edit the configuration file to add your Beacon Node endpoints:

      .. prompt:: bash $

        sudo nano /etc/ethereum/vouch.yml

      Add your beacon node endpoints in the ``beacon-node-address`` list.

      Import the validator keys:

      .. prompt:: bash $

        /usr/local/bin/vouch account import --base-dir=/home/ethereum/.vouch --keys-dir=/home/ethereum/validator_keys

      Enter the password you defined earlier.

      Set the fee recipient in the config file:

      .. prompt:: bash $

        sudo nano /etc/ethereum/vouch.yml

      Set the ``fee-recipient`` field:

      .. code-block:: yaml

        fee-recipient: "0x1234567890abcdef1234567890abcdef12345678"

      Replace with your actual Ethereum address.

      Start the Vouch service:

      .. prompt:: bash $

        sudo systemctl start vouch

      The Vouch validator is now enabled. Check the logs for further info.
