Running a Supernode
===================

We call **Supernode** a node that **runs both L1+L2 nodes on the same ARM64 board**. This is achieved by first syncing an L1 and later an L2 client.

As a first approach, we are setting up an L1 and an :guilabel:`Optimism` node and will be adding more L2s step-by-step guides.

L1 sync
-------

The first step is to sync an L1 node. You can choose any client combo. For instance:

.. prompt:: bash $

  sudo systemctl start prysm-beacon
  sudo systemctl start geth

Once synced, you can start your L2 node.

.. note::
  We recommend to **wait for the Execution Client to finish the snapshot creation phase** as it consumes a lot of resources. 
  Check the logs and make sure the client is just importing blocks. 

L2 sync
-------

Once the L1 is up and running, we can start syncing the L2 node. 

Optimism
~~~~~~~~

First, we need to change a couple of configuration parameters.

As we are running a **Supernode**, we will be using *localhost* as the L1 provider. Let's set *localhost* as our host:

.. prompt:: bash $

  sudo sed -i 's/l1ip/localhost/' /etc/ethereum/op-node.conf
  sudo sed -i 's/l1beaconip/localhost/' /etc/ethereum/op-node.conf

Now we can start both clients: :guilabel:`op-geth` and :guilabel:`op-node`.

First, start :guilabel:`op-geth`:

.. prompt:: bash $

  sudo systemctl start op-geth

.. note::
  As :guilabel:`op-geth` is configured to use **snap sync**, the client needs peers to download the info. So 
  we need to forward the port **31303** to allow peers to connect.

Once :guilabel:`op-geth` is running, we can start :guilabel:`op-node`:

.. prompt:: bash $

  sudo systemctl start op-node

The snap sync process will start shortly (and will take ~10-15 hours). Once in sync, you will be running a SuperNode.
