.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Ethereum 2.0
============

.. warning::

  **DISCLAIMER**: Ethereum is an experimental technology. Running the Ethereum on ARM image as 
  an Ethereum 2.0 validator node can lead to loss of ETH. This is a risk operation and you 
  alone are responsible for your actions using the Ethereum sofware included in this image 
  or following the instructions of this guide.

  We strongly recommend to try first an Ethereum 2.0 testnet (**Pyrmont** or **Prater** and get 
  familiarized with the process before staking with real ETH.


Ethereum 2.0 is the new Proof of Stake chain, currently running on phase 0. If you 
want to get further info please visit the `ethereum 2.0 EF page`_ : 

.. _ethereum 2.0 EF page: https://ethereum.org/en/eth2/

An Ethereum 2.0 client consists of two components, a Beacon chain and a Validator.

Beacon Chain
------------

The Beacon Chain is a bridge between the Ethereum 1.0 and the Ethereum 2.0 worlds. 
It connects the Validator to the Ethereum 1.0 chain so the validator can detect the 
32 ETH deposit transaction (which contains the Validator public key). In order to 
propose (create) blocks in Ethereum 2.0 you need the Beacon Chain synced and  
connected to an Ethereum 1.0 provider (it can be an Ethereum 1.0 local node or 
a third party Ethereum 1.0 provider (see below).

Validator
---------

Here is basically where the stake process happens.

The validator is the client that proposes blocks and does attestations according to 
the Ethereum 2.0 specification (proposing a block would be the equivalent to "mine" a block 
in the Ethereum 1.0 chain).

.. warning::

  There is a chance of losing your ETH if your validator does something wrong (this is 
  called being slashed), so be extremely carefull and always follow the Ethereum 2.0 
  specification.

  And never run the same validator (same private keys) in two nodes at the same time. You 
  will be slashed.

Staking Requirements
--------------------

In order to stake and run a validator you will need:

  * 32 ETH
  * An Ethereum 1.0 node client or a Ethereum 1.0 provider
  * An Ethereum 2.0 node client consisting of:
    * A Beacon Chain
    * A/several Validator(s)

For making the 32 ETH deposit you need to create 2 key pairs and a Json file with the 
necessary information to interact with the Eth2 mainnet contract through a transaction.

The Ethereum Foundation provides a tool (eth2.0-deposit-tool) to create the keys and the 
deposit information (which among others contains your validator(s) public key(s)). This 
tool is already installed in your node.

Additionally, the Ethereum Foundation set up a web Launchpad to make the staking process 
much more easy. Here you can upload the Json file and make the 32 ETH transaction 
with your wallet or a web3 wallet (such as Metamask or Walletconnect).

Validator setup and 32 ETH deposit
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The validator setup is client agnostic so it will be valid for all Ethereum 2.0 clients.

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

1. Click **“Get started”**

2. Read carefully and accept all warnings. 
   
3. You can skip the Ethereum 1.0 selection as all clients are already installed. click 
   "Continue"

4. Same for Ethereum 2.0 client. Click "Continue"

5. In the next screen, select the number of validators you want to run. Remember that you need 
   32 ETH for each.

6. Ethereum on ARM provides the Ethereum Foundation tool to generate, so, in you Raspberry Pi 
   terminal and under the ethereum account, run (assuming 1 validator):

.. prompt:: bash $

    cd && deposit new-mnemonic --num_validators 1 --chain mainnet

7. Choose your mnemonic language and type a password for keeping your keys safe. Write 
down your mnemonic password, press any key and type it again as requested.

.. warning::

  Make sure you wrote down the nnemonic on a safe place. Without it you will NOT be
  able to withdrawn your ETH in the future.

  Again, please, make sure your mnemonic is safe!!!

8. Now you have 2 Json files under the ``validator_keys`` directory:

  * A deposit data file for making the 32 ETH transaction to the mainnet (which contains 
    your validator public key as well).
  * A keystore file with your validator keys that will be used by your Ethereum 2.0 
    client.

9. Back to the Launchpad website, check **"I am keeping my keys safe and have written down 
my mnemonic phrase"** and click **"Continue"**.

10. It is time to send the 32 ETH deposit to the Ethereum 1.0 mainnet. You need the 
deposit file (located in your Raspberry Pi). You can, either copy and paste the 
file content and save it as a new json file in your desktop computer or copy the file 
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

The Beacon Chain (which is connected to the Ethereum 1.0 chain) will detect 
this deposit and the Validator will be enabled.

Congrats!, you just started your validator activation process.

Running an Ethereum 2.0 client
------------------------------

.. warning::

  **DISCLAIMER**: As of March 2021 we only tested :guilabel:`Geth` (Ethereum 1.0) and :guilabel:`Lighthouse` 
  (Ethereum 2.0) in a Raspberry Pi 4. In the coming weeks, we will try other Ethereum 1.0 and 2.0 clients 
  and label them as tested.

  As so, we recommend to choose these 2 clients while we make sure the others are suitable to run in 
  these devices.


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

.. csv-table::
  :header: Systemd Services, Home Directory, Config Files, Default TCP/UDP Port

  `lighthouse-beacon lighthouse-validator`, `/home/ethereum/.lighthouse`, `/etc/ethereum/lighthouse-beacon.conf /etc/ethereum/lighthouse-validator.conf`, `9000`

.. tip::
  :guilabel:`Lighthouse` is the Ethereum 2.0 client that we've been running since December 
  2020 (along with a Geth Ethereum 1.0 node), and, so far, the only client tested on this architecture 
  in production.

1.- Port forwarding

You need to open the 9000 port in your router (both UDP and TCP)

2.- Start the beacon chain

Under the ethereum account, run:

.. prompt:: bash $

  sudo systemctl enable lighthouse-beacon
  sudo systemctl start lighthouse-beacon

The Lighthouse client will start to sync the Beacon Chain. This can take several hours.

3.- Start de validator

We need to import the previously generated validator keys. Run under the ethereum account:

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

.. csv-table::
  :header: Systemd Services, Home Directory, Config Files, Default TCP/UDP Port

  `prysm-beacon prysm-validator`, `/home/ethereum/.eth2`, `/etc/ethereum/prysm-beacon.conf /etc/ethereum/prysm-validator.conf`, `13000 12000`

.. note::

  You need to accept the Prylabs terms of service. To do so, edit the above config files and add the --accept-terms-of-use flag.

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

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `teku`, `/home/ethereum/.teku/data_teku`, `/etc/ethereum/teku.conf`, `9151`

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

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `nimbus`, `/home/ethereum/.nimbus`, `/etc/ethereum/nimbus.conf`, `19000`

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

