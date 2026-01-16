Maru
====

Description
-----------

ConsenSys Maru Client (Validium/Prover Helper), packaged for Ethereum on ARM.

Installation
------------

.. code-block:: bash

    sudo apt install maru

Service Management
------------------

The service is disabled by default.

.. code-block:: bash

    sudo systemctl enable --now maru
    
    # Or for Sepolia:
    sudo systemctl enable --now maru-sepolia

Configuration
-------------

Configuration file is located at ``/etc/ethereum/maru.conf``.

.. code-block:: bash

    # /etc/ethereum/maru.conf (Mainnet)
    ARGS="--network=linea-mainnet ..."
    
    # /etc/ethereum/maru-sepolia.conf (Sepolia)
    ARGS="--network=linea-sepolia ..."

Data Directories
----------------

By default, data is stored in the ``ethereum`` user's home directory.

Upstream References
-------------------

- `Maru GitHub <https://github.com/Consensys/maru>`_
