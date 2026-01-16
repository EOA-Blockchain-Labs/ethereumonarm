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

Configuration
-------------

Configuration file is located at ``/etc/ethereum/maru.conf``.

.. code-block:: bash

    # /etc/ethereum/maru.conf
    ARGS="--rpc-http-enabled=true --rpc-http-host=0.0.0.0"

Data Directories
----------------

By default, data is stored in the ``ethereum`` user's home directory.

Upstream References
-------------------

- `Maru GitHub <https://github.com/Consensys/maru>`_
