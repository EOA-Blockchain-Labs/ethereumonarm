.. _migrating_validator:

Migrating a Validator
=====================

Moving a validator from one machine to another (e.g., migrating from a cloud VPS or an old desktop to an ARM board) is a critical operation.

.. danger::
    **SLASHING RISK: DOUBLE SIGNING**

    Never run the same validator keys on two different machines at the same time. This will result in a **slashing event**, causing you to be ejected from the network and lose a significant portion of your stake.

    **Always ensure the old validator is completely stopped and disabled before starting the new one.**

Prerequisites
-------------

* **New Node:** Your Ethereum on ARM board (Rock 5B, Orange Pi, etc.) should be installed, powered on, and fully synced (both Execution and Consensus clients).
* **Old Node:** Access to the terminal of your current validator.
* **Key Files:** Your original ``keystore-m_....json`` files and their password.

Step 1: Sync the New Node (Without Keys)
----------------------------------------

Before migrating your keys, ensure your Ethereum on ARM node is fully synced.

1.  Start the Execution Client (Geth, Nethermind, Erigon, Reth).
2.  Start the Consensus Client (Lighthouse, Nimbus, Prysm, Teku, Lodestar).
3.  **Do not import keys yet.** Let the Beacon Node sync to the head of the chain.

Step 2: Export Slashing Protection (Old Node)
---------------------------------------------

To prevent the new node from signing a block that contradicts history, you must export the slashing protection database from your old client.

Run the appropriate command on your **OLD** machine depending on the client you are using:

**Lighthouse**

.. code-block:: bash

    lighthouse account validator slashing-protection export slashing_protection.json

**Prysm**

.. code-block:: bash

    prysm.sh validator slashing-protection-history export --datadir=/path/to/wallet --slashing-protection-export-dir=/path/to/export

**Nimbus**

.. code-block:: bash

    nimbus_beacon_node slashingdb export slashing_protection.json

**Teku**

.. code-block:: bash

    teku slashing-protection export --to=slashing_protection.json

Step 3: Stop and Delete the Old Validator
-----------------------------------------

This is the most important step to avoid slashing.

1.  **Stop the service:**

    .. code-block:: bash

        # Replace 'validator.service' with your actual service name
        # (e.g., prysm-validator.service, lighthouse-validator.service, etc.)
        sudo systemctl stop validator.service
        sudo systemctl disable validator.service

        # Example for Docker
        docker-compose down

2.  **Verify it is stopped:** Check that no validator processes are running.
3.  **Delete the keys:** Once you have your backups safe (Keystores and Slashing Protection JSON), **delete the keys from the old machine** to prevent an accidental restart.

.. tip::
    **The Waiting Period**: It is highly recommended to wait **2 to 3 epochs** (approx. 15-20 minutes) after stopping the old node before starting the new one. Check a block explorer (like beaconcha.in or gnosisscan.io) to verify your validator is missing attestations. This confirms the old node is definitely offline.

Step 4: Transfer Files to Ethereum on ARM
-----------------------------------------

Copy the following files to your ARM board (using ``scp``, ``rsync``, or a USB drive):

1.  The ``keystore-m_....json`` files.
2.  The ``slashing_protection.json`` file you exported in Step 2.

Step 5: Import Keys and Protection (New Node)
---------------------------------------------

On your Ethereum on ARM board, use the client binary to import the data.

.. note::
    Replace ``<NETWORK>`` with ``mainnet``, ``gnosis``, or ``holesky`` depending on your chain.
    Ensure you run these commands with the correct user permissions (usually root or the specific service user).

**Lighthouse**

.. code-block:: bash

    # 1. Import Keys
    lighthouse account validator import \
      --network <NETWORK> \
      --directory /path/to/keystores \
      --datadir /var/lib/lighthouse

    # 2. Import Slashing Protection
    lighthouse account validator slashing-protection import \
      slashing_protection.json \
      --datadir /var/lib/lighthouse

**Nimbus**

.. code-block:: bash

    # 1. Import Keys
    nimbus_beacon_node deposits import \
      --data-dir=/var/lib/nimbus \
      /path/to/keystores

    # 2. Import Slashing Protection
    sudo /usr/bin/nimbus_beacon_node slashingdb import \
      --data-dir=/var/lib/nimbus \
      slashing_protection.json

**Prysm**

.. code-block:: bash

    # 1. Import Keys
    validator accounts import \
      --keys-dir=/path/to/keystores \
      --wallet-dir=/var/lib/prysm/validator

    # 2. Import Slashing Protection
    validator slashing-protection-history import \
      --datadir=/var/lib/prysm/validator \
      --slashing-protection-json-file=slashing_protection.json

**Teku**

.. code-block:: bash

    # 1. Import Keys
    teku validator import \
      --data-path=/var/lib/teku \
      --from=/path/to/keystores

    # 2. Import Slashing Protection
    teku slashing-protection import \
      --data-path=/var/lib/teku \
      --from=slashing_protection.json

Step 6: Start the Validator Service
-----------------------------------

Once the keys and slashing protection data are imported:

1.  Enable and start your specific validator service via systemd.

    .. note::
        Replace ``validator.service`` with the actual name of your service (e.g., ``prysm-validator.service``, ``teku-validator.service``).

    .. code-block:: bash

        sudo systemctl enable validator.service
        sudo systemctl start validator.service

2.  Check the logs to ensure it is running correctly and attempting to attest:

    .. code-block:: bash

        sudo journalctl -fu validator.service

You should see logs indicating "Published attestation" or similar success messages.

3.  **Verify on a Block Explorer:**
    Go to a block explorer like `beaconcha.in <https://beaconcha.in>`_ (or `gnosisscan.io <https://gnosisscan.io>`_ for Gnosis) and search for your validator's public key (index). Verify that:
    *   The validator status is **"Active"**.
    *   New attestations are appearing and are marked as **"Attested"** (green).
