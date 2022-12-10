.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Using your node
===============

Besides contributing to the network decentralization, you can use your node for sending transactions  
or to query the Ethereum API.

Our image includes an **Nginx proxy** that connects to the **Execution Layer RPC** and make the node communication easier.

The Nginx proxy is included in the last images. If you are running an old one make sure it is installed by 
typing:

.. prompt:: bash $

  sudo apt-get update && sudo apt-get install ethereumonarm-nginx-proxy-extras


SSL config
----------

An SSL preconfiguration is included in the ``/etc/nginx/sites-available/ethereum-ssl.conf`` file as well. 
It is intended to be used with your own certificate or Let's Encrypt. Use this only if you know what you 
are doing.

Sending transactions
--------------------

You can use your favourite wallet to send transactions to the network. For instance, let's 
see how to connect **Metamask** to your node.

1. Open the extension in your browser and click in the top network menu (probably showing "Ethereum Mainnet").

2. Click **"Add Network"** button.

.. figure:: /_static/images/metamask-add-network.jpg
   :figwidth: 600px
   :align: center

3. Click **"Add a network manually"** at the page bottom.

.. figure:: /_static/images/metamask-add-network-manually.jpg
   :figwidth: 600px
   :align: center

4. Fill in the data with your node data.

.. figure:: /_static/images/metamask-settings.jpg
   :figwidth: 600px
   :align: center

For instance. This is a configured local node:

.. figure:: /_static/images/metamask-node.jpg
   :figwidth: 600px
   :align: center

Querying the blockchain
-----------------------

You can query the API using several method. This is an example using ``curl`` (from your desktop terminal):

Replace $YOUR_NODE_IP for your node IP address.

.. prompt:: bash $

  curl --data '{"method":"eth_blockNumber","params":[],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST $YOUR_NODE_IP