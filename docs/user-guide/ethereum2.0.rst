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

The validator setup is client agnostic so it will be valid for all Ethereum 2.0 clients.


.. note::
  At this point, you should have an Ethereum 1.0 node running with the blockchain synced. 
  You can not propose blocks without an Ethereum 1.0.

  You can use a third party Ethereum 1.0 provider such as Infura or , but we'd like you to 
  run your own Ethereum 1.0 node ir order to contribute to the network and avoid  

The first step is to visit the EF Launchpad website to start the process:

`https://launchpad.ethereum.org`_

_https://launchpad.ethereum.org

Click “Get started”

Read and accept all warnings. In the next screen, select 1 validator and go to your 
Raspberry Pi console. Under the ethereum account run:

cd && deposit --num_validators 1

Choose your mnemonic language and type a password for keeping your keys safe. Write 
down your mnemonic password, press any key and type it again as requested.

.. warning::

  Make sure you wrote down the nnemonic on a safe place. Without it you will NOT be
  able to withdrawn your ETH in the future.

Now you have 2 Json files under the validator_keys directory:

  * A deposit data file for make the 32 ETH transaction to the mainnet (which contains 
    your validator
  * A keystore file with your validator keys which will be used by your Ethereum 2.0 
    client

Back to the Launchpad website, check "I am keeping my keys safe and have written down 
my mnemonic phrase" and click "Continue".

It is time to send the 32 ETH deposit to the Ethereum 1.0 mainnet. You need the 
deposit file (located in your Raspberry Pi). You can, either copy and paste the 
file content and save it as a new file in your desktop computer or copy the file 
from the Raspberry to your desktop through SSH.

1.- Copy and paste: Connected through SSH to your Raspberry Pi, type:

cat validator_keys/deposit_data-$FILE-ID.json (replace $FILE-ID with yours)

Copy the content (the text in square brackets), go back to your desktop, paste it 
into your favourite editor and save it as a json file.

Or

2.- Pull the file from your desktop through SSH, copy the file:

scp ethereum@$YOUR_RASPBERRYPI_IP:/home/ethereum/validator_keys/deposit_data-$FILE_ID.json /tmp

Replace the variables ($YOUR_RASPBERRYPI_IP and $FILE_ID) with your data. 
This will copy the file to your desktop /tmp directory.

Upload the deposit file

Now, back to the Launchpad website, upload the deposit_data file and select 
Metamask, click continue and check all warnings. Continue and click 
“Initiate the Transaction”. Confirm the transaction in Metamask and wait 
for the confirmation (a notification will pop up shortly).

The Beacon Chain (which is connected to the Ethereum 1.0 chain) will detect 
this deposit (that includes the validator public key) and the Validator 
will be enabled.

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

Prysm
~~~~~

:guilabel:`Prysm` is a full Ethereum 2.0 client written in Go.

Nimbus
~~~~~~

:guilabel:`Nimbus` is a full Ethereum 2.0 client written in Rust.

Teku
~~~~

:guilabel:`Teku` is a full Ethereum 2.0 client written in Rust.

