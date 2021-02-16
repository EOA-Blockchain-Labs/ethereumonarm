.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Ethereum 2.0
============

Ethereum 2.0 is the new Proof of Stake chain, currently running on phase 0. If you 
want to get further info please visit the `ethereum 2.0 EF page`_ : 

.. _ethereum 2.0 EF page: https://ethereum.org/en/eth2/

An Ethereum 2.0 client consists of two components, a Beacon chain and a Validator.

Beacon Chain
------------

The Beacon Chain is a bridge between the Ethereum 1.0 and the Ethereum 2.0 worlds. 
It connects the Validator to the Ethereum 1.0 chain so the validator can detect the 
32 ETH deposit transaction (which contains the Validator public key).

Validator
---------

Here is basically where the stake happens.

The validator is the client that proposes blocks and does attestations according to 
the Ethereum 2.0 specification (proposing a block would be equivalent to "mine" a block) 
in the Ethereum 1.0 chain.

.. warning::

  There is a chance of losing your ETH if your validator does something wrong (this is 
  called being slashed), so be extremely carefull and always follow the Ethereum 2.0 
  specification.

Staking Requirements
--------------------

In order to stake and run a validator you will need:

  * 32 ETH
  * An Ethereum 1.0 node client
  * An Ethereum 2.0 node client consisting of:
    * A Beacon Chain
    * A/several Validator(s)

For making the 32 ETH deposit you need to create 2 key pairs and a Json file with the 
necessary information to interact with the Eth2 mainnet contract through a transaction.

The Ethereum Foundation provides a tool (eth2.0-deposit-tool) to create the keys and the 
deposit information (which among others contains your validator(s) public key(s)). This 
tool is already installed in your node.

Additionally, the Ethereum Foundation set up a web Launchpad to make the staking process 
much more easy. Here you can upload the generated file and make the 32 ETH transaction 
with your wallet or a web3 provider (such as Metamask or Walletconnect).

Validator setup and 32 ETH deposit
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The validator setup is a client agnostic process so it will be valid for all Ethereum 2.0 clients.

.. note::
  At this point, you should have an Ethereum 1.0 node running with the blockchain synced. 
  You can not propose blocks without an Ethereum 1.0.

  You can use a third party Ethereum 1.0 provider such as Infura_, QuikNode_, Chainstack_, 
  or Alchemy_, but we'd love to see you running your own Ethereum 1.0 node ir order to contribute 
  to the network decentralization and to avoid any issues with a third party provider.

.. _Infura: https://infura.io
.. _QuikNode: https://www.quiknode.io
.. _Chainstack: https://chainstack.com
.. _Alchemy: https://alchemyapi.io
  
The first step is to visit the EF Launchpad website to start the process:

`https://launchpad.ethereum.org`_

.. _https://launchpad.ethereum.org: https://launchpad.ethereum.org

Click **“Get started”**

Read and accept all warnings. In the next screen, select 1 validator and go to your 
Raspberry Pi console. Under the ethereum account run:

.. prompt:: bash $

    cd && deposit --num_validators 1

Choose your mnemonic language and type a password for keeping your keys safe. Write 
down your mnemonic password, press any key and type it again as requested.

.. warning::

  Make sure you wrote down the nnemonic on a safe place. Without it you will NOT be
  able to withdrawn your ETH in the future.

  Again, please, make sure your mnemonic is safe!!!

Now you have 2 Json files under the ``validator_keys`` directory:

  * A deposit data file for making the 32 ETH transaction to the mainnet (which contains 
    your validator public key as well).
  * A keystore file with your validator keys that will be used by your Ethereum 2.0 
    client

Back to the Launchpad website, check **"I am keeping my keys safe and have written down 
my mnemonic phrase"** and click **"Continue"**.

It is time to send the 32 ETH deposit to the Ethereum 1.0 mainnet. You need the 
deposit file (located in your Raspberry Pi). You can, either copy and paste the 
file content and save it as a new file in your desktop computer or copy the file 
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

Now, back to the Launchpad website, upload the ``deposit_data`` file and select 
Metamask, click continue and check all warnings. Continue and click 
**“Initiate the Transaction”**. Confirm the transaction in Metamask and wait 
for the confirmation (a notification will pop up shortly).

The Beacon Chain (which is connected to the Ethereum 1.0 chain) will detect 
this deposit and the Validator will be enabled.

Congrats!, you just started your validator activation process.

Running an Ethereum 2.0 client
------------------------------



Supported clients
~~~~~~~~~~~~~~~~~

Ethereum on ARM supports the main Ethereum 2.0 clients available.

.. csv-table::
   :header: Client, Official Binary, Language, Home

   `Lighthouse`, `Yes`, `Rust`, lighthouse-book.sigmaprime.io_
   `Prysm`, `Yes`, `Go`, docs.prylabs.network_
   `Nimbus`,`Yes`, `Nim`, nimbus.team_
   `Teku`, `Yes`, `Java`, consensys.net_

.. _lighthouse-book.sigmaprime.io: https://lighthouse-book.sigmaprime.io
.. _docs.prylabs.network: https://docs.prylabs.network/docs/getting-started/
.. _nimbus.team: https://nimbus.team
.. _consensys.net: https://consensys.net/knowledge-base/ethereum-2/teku/

Lighthouse
~~~~~~~~~~

:guilabel:`Lighthouse` is a full Ethereum 2.0 client written in Rust. It is very capable on
running in resource-constrained devices such as the Raspberry Pi 4.

.. tip::
  :guilabel:`Lighthouse` is the Ethereum 2.0 client that we've been running since December 
  2020 (along with a Geth Ethereum 1.0 node), so it is well tested on a Raspberry Pi 4

1.- Port forwarding

You need to open the 9000 port in your router (both UDP and TCP)

2.- Start the beacon chain

Under the ethereum account, run:

.. prompt:: bash $

  sudo systemctl enable lighthouse-beacon
  sudo systemctl start lighthouse-beacon

3.- Start de validator

We need to import the validator keys. Run under the ethereum account:

.. prompt:: bash $

  lighthouse account validator import --directory=/home/ethereum/validator_keys

Then, type your previously defined password and run:

.. prompt:: bash $

  sudo systemctl enable lighthouse-validator
  sudo systemctl start lighthouse-validator

The Lighthouse beacon chain and validator are now enabled.


Prysm
~~~~~

:guilabel:`Prysm` is a full Ethereum 2.0 client written in Go.

1.- Port forwarding

You need to open the 13000 and 12000 ports in your router (both UDP and TCP)

2.- Start the beacon chain

Under the ethereum account, run:

.. prompt:: bash $

  sudo systemctl enable prysm-beacon
  sudo systemctl start prysm-beacon

3.- Start de validator

We need to import the validator keys. Run under the ethereum account:

.. prompt:: bash $

  validator accounts-v2 import --keys-dir=/home/ethereum/validator_keys

Accept the default wallet path and enter a password for your wallet. Now enter 
the password previously defined.

Lastly, set up your password and start the client:

.. prompt:: bash $

  echo "$YOUR_PASSWORD" > /home/ethereum/validator_keys/prysm-password.txt
  sudo systemctl enable prysm-validator
  sudo systemctl start prysm-validator

The Prysm beacon chain and the validator are now enabled.

Teku
~~~~

:guilabel:`Teku` is a full Ethereum 2.0 client written in Java.

1.- Port forwarding

You need to open the 9151 port (both UDP and TCP)

2.- Start the Beacon Chain and the Validator

Under the Ethereum account, check the name of your keystore file:

.. prompt:: bash $

  ls /home/ethereum/validator_keys/keystore*

Set the keystore file name in the teku config file (replace the $KEYSTORE_FILE variable with the file listed above)

.. prompt:: bash $

  sudo sed -i 's/changeme/$KEYSTORE_FILE/' /etc/ethereum/teku.conf

Set the password previously entered:

.. prompt:: bash $

  echo "yourpassword" > validator_keys/teku-password.txt

Start the beacon chain and the validator:

.. prompt:: bash $

  sudo systemctl enable teku
  sudo systemctl start teku

The Teku beacon chain and validator are now enabled.

Nimbus
~~~~~~

:guilabel:`Nimbus` is a full Ethereum 2.0 client written in Nim.

1.- Port forwarding

You need to open the 19000 port (both UDP and TCP)

2.- Start the Beacon Chain and the Validator

We need to import the validator keys. Run under the ethereum account:

.. prompt:: bash $

  beacon_node deposits import /home/ethereum/validator_keys --data-dir=/home/ethereum/.nimbus --log-file=/home/ethereum/.nimbus/nimbus.log

Enter the password previously defined and run:

.. prompt:: bash $

  sudo systemctl enable nimbus
  sudo systemctl start nimbus

The Nimbus beacon chain and validator are now enabled.

