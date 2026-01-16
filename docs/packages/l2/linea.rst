Linea
=====

Description
-----------

ConsenSys Linea Mainnet Besu Client, packaged for Ethereum on ARM.
This package installs the Linea Besu client with four service profiles:

- **Basic Mainnet**: Standard Linea Mainnet node.
- **Advanced Mainnet**: Linea Mainnet node with extra features (e.g. `linea_estimateGas`).
- **Basic Sepolia**: Standard Linea Sepolia Testnet node.
- **Advanced Sepolia**: Linea Sepolia Testnet node with extra features.

Installation
------------

.. code-block:: bash

    sudo apt install linea

Service Management
------------------

The services are disabled by default. Enable the one matching your desired network and profile.

**Mainnet (Basic)**:

.. code-block:: bash

    sudo systemctl enable --now linea

**Mainnet (Advanced)**:

.. code-block:: bash

    sudo systemctl enable --now linea-advanced

**Sepolia (Basic)**:

.. code-block:: bash

    sudo systemctl enable --now linea-sepolia

**Sepolia (Advanced)**:

.. code-block:: bash

    sudo systemctl enable --now linea-advanced-sepolia

Configuration
-------------

Configuration files are located in ``/etc/ethereum/``:

- ``/etc/ethereum/linea.conf``
- ``/etc/ethereum/linea-advanced.conf``
- ``/etc/ethereum/linea-sepolia.conf``
- ``/etc/ethereum/linea-advanced-sepolia.conf``

You can edit these files to customize the ``ARGS`` variable passed to the binary.

Data Directories
----------------

By default, data is stored in the ``ethereum`` user's home directory:

- ``/home/ethereum/.linea``
- ``/home/ethereum/.linea-advanced``
- ``/home/ethereum/.linea-sepolia``
- ``/home/ethereum/.linea-advanced-sepolia``

Upstream References
-------------------

- `Linea Monorepo (GitHub) <https://github.com/Consensys/linea-monorepo>`_
- `Linea Docs <https://docs.linea.build/>`_
