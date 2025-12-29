.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Managing Clients
================

.. grid:: 1 2 2 4
   :gutter: 2

   .. grid-item-card:: 🔧 Systemd
      :link: #systemd-services
      :link-type: ref
      :text-align: center
      :class-card: sd-border-info
      
      ⚙️
      
      Start/Stop/Enable services

   .. grid-item-card:: 📝 Configure
      :link: #changing-parameters
      :link-type: ref
      :text-align: center
      :class-card: sd-border-info
      
      ✏️
      
      Edit client parameters

   .. grid-item-card:: 🔄 Update
      :link: #updating-clients
      :link-type: ref
      :text-align: center
      :class-card: sd-border-info
      
      📦
      
      Upgrade via APT

   .. grid-item-card:: 📊 Monitor
      :link: #monitoring-dashboards
      :link-type: ref
      :text-align: center
      :class-card: sd-border-info
      
      📈
      
      Grafana dashboards


Systemd Services
----------------

All clients use :guilabel:`Systemd` services for running. :guilabel:`Systemd` 
takes care of the processes and automatically restarts them in case something 
goes wrong. It can enable a service to automatically start it on boot as well.

:guilabel:`Systemd` command ``systemctl`` manages all operations related to 
the services. The available options are as follows:

  * **Enable**: Activate the service to start on boot
  * **Disable**: Remove the service from boot start
  * **Start**: Start the client process
  * **Stop**: Stop the client process
  * **Restart**: Restart the clients process

The general syntax is:

.. prompt:: bash $

  sudo systemctl enable|disable|start|stop|restart service_name

.. note::
  You need the ``sudo`` command as root permissions are necessary. Type your 
  etherereum user password.

For instance, to enable :guilabel:`Nethermind` client on boot and start it, type:

.. prompt:: bash $

  sudo systemctl enable nethermind
  sudo systemctl start nethermind

:guilabel:`Nethermind` will now start in the background and run automatically 
on next boot.

These are the list of services available for all clients:

.. tab-set::

   .. tab-item:: ⚡ Execution Layer
      
      .. grid:: 2
         :gutter: 2
      
         .. grid-item-card:: Geth
            :class-card: sd-border-primary
            
            .. code-block:: bash
               
               sudo systemctl start geth
         
         .. grid-item-card:: Nethermind
            :class-card: sd-border-primary
            
            .. code-block:: bash
               
               sudo systemctl start nethermind
         
         .. grid-item-card:: Erigon
            :class-card: sd-border-primary
            
            .. code-block:: bash
               
               sudo systemctl start erigon
         
         .. grid-item-card:: Reth
            :class-card: sd-border-primary
            
            .. code-block:: bash
               
               sudo systemctl start reth
         
         .. grid-item-card:: Besu
            :class-card: sd-border-primary
            
            .. code-block:: bash
               
               sudo systemctl start besu
         
         .. grid-item-card:: EthRex
            :class-card: sd-border-primary
            
            .. code-block:: bash
               
               sudo systemctl start ethrex

   .. tab-item:: 🔮 Consensus Layer
      
      .. grid:: 2
         :gutter: 2
      
         .. grid-item-card:: Lighthouse
            :class-card: sd-border-success
            
            .. code-block:: bash
               
               sudo systemctl start lighthouse-beacon
               sudo systemctl start lighthouse-validator
         
         .. grid-item-card:: Prysm
            :class-card: sd-border-success
            
            .. code-block:: bash
               
               sudo systemctl start prysm-beacon
               sudo systemctl start prysm-validator
         
         .. grid-item-card:: Nimbus
            :class-card: sd-border-success
            
            .. code-block:: bash
               
               sudo systemctl start nimbus-beacon
               sudo systemctl start nimbus-validator
         
         .. grid-item-card:: Teku
            :class-card: sd-border-success
            
            .. code-block:: bash
               
               sudo systemctl start teku-beacon
               sudo systemctl start teku-validator
         
         .. grid-item-card:: Lodestar
            :class-card: sd-border-success
            
            .. code-block:: bash
               
               sudo systemctl start lodestar-beacon
               sudo systemctl start lodestar-validator
         
         .. grid-item-card:: Grandine
            :class-card: sd-border-success
            
            .. code-block:: bash
               
               sudo systemctl start grandine-beacon



Changing Parameters
-------------------

:guilabel:`Systemd` services read client variables from ``/etc/ethereum`` directory files. If
you want to change any client parameter you have to edit the correspondent config file. For 
instance, this is the ``/etc/ethereum/geth.conf`` content::

  ARGS="--metrics --metrics.expensive --pprof --http --authrpc.jwtsecret=/etc/ethereum/jwtsecret"

Edit the file by running a text editor (``vim``, ``nano``):

.. prompt:: bash $

  sudo vim /etc/ethereum/geth.conf

For instance, let's change the P2P port to 30304. Add it to the ARGS line and save it::

  ARGS="--metrics --metrics.expensive --pprof --http --authrpc.jwtsecret=/etc/ethereum/jwtsecret --port 30304"

For changes to take effect, you need to restart the client:

.. prompt:: bash $

  sudo systemctl restart geth

.. note::

  All clients have its own config files in ``/etc/ethereum`` except :guilabel:`Nethermind` that 
  has an additional conf directory located in ``/opt/nethermind/configs/``

.. tip::
  Read the clients official documentation in order to learn the specific parameters
  of each client.


Updating Clients
----------------

APT repository
~~~~~~~~~~~~~~

.. note::

  If you see this warning running APT:
  
  ``Key is stored in legacy trusted.gpg keyring (/etc/apt/trusted.gpg), see the DEPRECATION section in apt-key(8) for details``
  
  run the following command:

  .. prompt:: bash $

    wget -q -O - http://apt.ethereumonarm.com/eoa.apt.keyring.gpg| sudo tee 
    /etc/apt/trusted.gpg.d/eoa.apt.keyring.gpg > /dev/null
    

**Ethereum on ARM** comes with a custom ``APT`` repository which allows users to easily
update the Ethereum software. For instance, to update the :guilabel:`Geth` client run:

.. prompt:: bash $

  sudo apt update
  sudo apt install geth

If you want to run the new version, restart the service by running:

.. prompt:: bash $

  sudo systemctl restart geth

**You can downgrade a client as well** by setting a specific version. This is particularly useful if 
a bug is found in the current version and you need to keep running the client. For example:

.. prompt:: bash $

  sudo apt install geth=1.9.25-2

The APT repository is browsable so you can download a package manually:

`https://apt.ethereumonarm.com/pool/main`_

.. _https://apt.ethereumonarm.com/pool/main: https://apt.ethereumonarm.com/pool/main/

Available Packages
~~~~~~~~~~~~~~~~~~

Browse all available packages organized by category. Click any package to view its detailed documentation.

.. tab-set::

   .. tab-item:: 🔗 L1 Clients
      
      .. grid:: 2
         :gutter: 3
      
         .. grid-item-card:: ⚡ Execution Layer
            :class-header: sd-bg-primary sd-text-white
            
            .. grid:: 2
               :gutter: 1
            
               .. grid-item::
                  :columns: 6
                  
                  :doc:`geth </packages/l1/geth>`
               
               .. grid-item::
                  :columns: 6
                  
                  :doc:`nethermind </packages/l1/nethermind>`
               
               .. grid-item::
                  :columns: 6
                  
                  :doc:`besu </packages/l1/besu>`
               
               .. grid-item::
                  :columns: 6
                  
                  :doc:`reth </packages/l1/reth>`
               
               .. grid-item::
                  :columns: 6
                  
                  :doc:`erigon </packages/l1/erigon>`
               
               .. grid-item::
                  :columns: 6
                  
                  :doc:`ethrex </packages/l1/ethrex>`
               
               .. grid-item::
                  :columns: 6
                  
                  :doc:`nimbus-ec </packages/l1/nimbus-execution>`
         
         .. grid-item-card:: 🔮 Consensus Layer
            :class-header: sd-bg-success sd-text-white
            
            .. grid:: 2
               :gutter: 1
            
               .. grid-item::
                  :columns: 6
                  
                  :doc:`lighthouse </packages/l1/lighthouse>`
               
               .. grid-item::
                  :columns: 6
                  
                  :doc:`prysm </packages/l1/prysm>`
               
               .. grid-item::
                  :columns: 6
                  
                  :doc:`nimbus </packages/l1/nimbus>`
               
               .. grid-item::
                  :columns: 6
                  
                  :doc:`teku </packages/l1/teku>`
               
               .. grid-item::
                  :columns: 6
                  
                  :doc:`lodestar </packages/l1/lodestar>`
               
               .. grid-item::
                  :columns: 6
                  
                  :doc:`grandine </packages/l1/grandine>`

   .. tab-item:: 🌐 L2 Clients
      
      .. grid:: 2 2 3 4
         :gutter: 2
      
         .. grid-item-card:: Optimism
            :class-header: sd-bg-danger sd-text-white
            
            * :doc:`op-geth </packages/l2/op-geth>`
            * :doc:`op-node </packages/l2/op-node>`
            * :doc:`op-reth </packages/l2/op-reth>`
         
         .. grid-item-card:: Arbitrum
            :class-header: sd-bg-info sd-text-white
            
            * :doc:`nitro </packages/l2/nitro>`
         
         .. grid-item-card:: Starknet
            :class-header: sd-bg-warning sd-text-white
            
            * :doc:`juno </packages/l2/juno>`
            * :doc:`madara </packages/l2/madara>`
            * :doc:`pathfinder </packages/l2/pathfinder>`
         
         .. grid-item-card:: Fuel
            :class-header: sd-bg-secondary sd-text-white
            
            * :doc:`fuel-network </packages/l2/fuel>`

   .. tab-item:: 🛠️ Infrastructure
      
      .. grid:: 2 2 2 3
         :gutter: 2
      
         .. grid-item-card:: 🎯 DVT
            :class-header: sd-bg-primary sd-text-white
            
            * :doc:`dvt-obol </packages/dvt/dvt-obol>`
            * :doc:`dvt-ssv </packages/dvt/ssv-node>`
         
         .. grid-item-card:: ⚡ MEV & Boost
            :class-header: sd-bg-success sd-text-white
            
            * :doc:`commit-boost </packages/infra/commit-boost>`
            * :doc:`mev-boost </packages/infra/mev-boost>`
         
         .. grid-item-card:: 🔐 Staking
            :class-header: sd-bg-warning sd-text-white
            
            * :doc:`ethstaker-deposit-cli </packages/tools/ethstaker-deposit-cli>`
            * :doc:`stakewise-operator </packages/tools/stakewise-operator>`
            * :doc:`vero </packages/l1/vero>`
            * :doc:`vouch </packages/l1/vouch>`
         
         .. grid-item-card:: 📊 Monitoring
            :class-header: sd-bg-info sd-text-white
            
            * :doc:`ethereum-metrics-exporter </packages/infra/ethereum-metrics-exporter>`
            * :doc:`ethereum-validator-metrics-exporter </packages/infra/ethereum-validator-metrics-exporter>`

   .. tab-item:: 🌍 Web3
      
      .. grid:: 2
         :gutter: 2
      
         .. grid-item-card:: IPFS
            :class-header: sd-bg-primary sd-text-white
            
            * :doc:`kubo </packages/web3/kubo>`
         
         .. grid-item-card:: Swarm
            :class-header: sd-bg-success sd-text-white
            
            * :doc:`bee </packages/web3/bee>`


.. note::
  The `APT` command will install the last version available in the repository. Most clients 
  provide binaries for ARM64 architecture so this is just a package to handle the software.

  See our developer guide section if you want to build you own packages.

Getting Logs
------------

You can get clients info by using :guilabel:`Systemd` ``journalctl`` command. For instance, 
to get the :guilabel:`Geth` ``output``, run:

.. prompt:: bash $

  sudo journalctl -u geth -f

You can of course take a look at ``/var/log/syslog``:

.. prompt:: bash $

  sudo tail -f /var/log/syslog

Monitoring Dashboards
---------------------

We configured Grafana Dashboards to let users monitor both Execution and Consensus clients. 
To access the dashboards just open your browser and type your ``Raspberry_IP`` followed by the 3000 port::

  http://replace_with_your_IP:3000
  user: admin
  passwd: ethereum


Validator Metrics
-----------------

The **Ethereum Validator Metrics Exporter** allows you to track your validator's performance, balance, and status using data from Beaconcha.in.

Installation
~~~~~~~~~~~~

.. prompt:: bash $

  sudo apt install ethereum-validator-metrics-exporter

Configuration
~~~~~~~~~~~~~

The service requires a configuration file located at ``/etc/ethereum/validator-metrics-exporter.yaml``. You need to edit this file to add your **Beaconcha.in API Key** and your **Validator Public Keys**.

.. prompt:: bash $

  sudo nano /etc/ethereum/validator-metrics-exporter.yaml

**Obtaining Beaconcha.in API Key:**

1. Sign up for a free account at `beaconcha.in <https://beaconcha.in>`_.
2. Go to your account settings and generate an API key.
3. Add it to the config file under ``beaconcha_in.apikey``.

**Finding your Validator Public Key:**

If you are running a local validator client (e.g., Nimbus, Prysm), you can find your public key in your validator keys directory or in the service logs.

For Nimbus:

.. prompt:: bash $

  ls /home/ethereum/.nimbus-beacon/validators
  # Or check logs:
  sudo journalctl -u nimbus-beacon | grep "Local validator attached"

Add your public keys to the ``validators`` list in the config file.

**Restarting the Service:**

After saving your changes, restart the service:

.. prompt:: bash $

  sudo systemctl restart ethereum-validator-metrics-exporter



