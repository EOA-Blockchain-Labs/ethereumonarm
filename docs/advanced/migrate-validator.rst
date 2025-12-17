Migrating a Validator
=====================

.. danger::

   **SLASHING RISK: DOUBLE SIGNING**

   Never run the same validator keys on two different machines at the same time. This can result in a slashing event, causing you to be ejected from the network and lose a significant portion of your stake.  
   Always ensure the old validator is completely stopped and disabled before starting the new one.

Overview
--------

This document explains how to safely move an Ethereum validator from one machine to another (for example, from a cloud VPS or an old desktop to an Ethereum on ARM board), while minimizing the risk of slashing.  
The procedure applies to common consensus clients (Grandine, Lighthouse, Nimbus, Prysm, Teku, Lodestar) and assumes you already have working execution and consensus clients on both machines.

Prerequisites
-------------

* **New node**: Your Ethereum on ARM board (Rock 5B, Orange Pi, etc.) must be installed, powered on, and fully synced (both execution and consensus clients).
* **Old node**: You must have terminal access to your current validator host.
* **Key material**: Your original ``keystore-m_....json`` files and their password must be safely backed up and available.

Step 1: Sync the new node (without keys)
----------------------------------------

1. Start your execution client on the new node (for example, Geth, Nethermind, Erigon, Reth) and let it fully sync.
2. Start your consensus client (for example, Lighthouse, Nimbus, Prysm, Teku, Lodestar, Grandine) and let the beacon node sync to the head of the chain.
3. Do **not** import validator keys yet; the new node must be fully synced before it is allowed to sign duties.

Step 2: Stop the old validator and export slashing protection
-------------------------------------------------------------

1. **Stop the validator on the old machine** before exporting slashing protection, to ensure no new duties are signed during export.

   .. code-block:: bash

      sudo systemctl stop validator.service
      # Replace with your actual service name, for example:
      # sudo systemctl stop prysm-validator.service
      # sudo systemctl stop lighthouse-validator.service
      # sudo systemctl stop lodestar-validator.service

2. Export the slashing protection history from your **old** validator client using its native command (EIP-3076 where supported).

   Grandine
     .. code-block:: bash

        grandine --network <NETWORK> interchange export slashing_protection.json

   Lighthouse
     .. code-block:: bash

        lighthouse account validator slashing-protection export slashing_protection.json

   Prysm
     .. code-block:: bash

        validator slashing-protection-history export \
          --datadir=/path/to/your/validator/db \
          --slashing-protection-export-dir=/path/to/export

   Nimbus
     .. code-block:: bash

        nimbus_beacon_node slashingdb export \
          --data-dir=/path/to/nimbus-data \
          slashing_protection.json

   Teku
     .. code-block:: bash

        teku slashing-protection export \
          --data-path=/home/ethereum/.teku \
          --to=slashing_protection.json

   Lodestar
     .. code-block:: bash

        lodestar validator slashing-protection export \
          --network <NETWORK> \
          --file slashing_protection.json \
          --dataDir /path/to/data

3. Verify that the export file (for example, ``slashing_protection.json`` or ``interchange.json``) is present and back it up securely.

Step 3: Disable and clean up the old validator
----------------------------------------------

1. Disable the validator service so it cannot auto-start after a reboot.

   .. code-block:: bash

      sudo systemctl disable validator.service

2. Confirm that no validator processes are running (for example, using ``ps``, ``systemctl status``, or your process supervisor tools).
3. Once you have confirmed your backups (keystores and slashing protection JSON) are safe, **delete or move** the validator keys from the old machine to prevent accidental restart.
4. Best practice is to wait at least **2–3 epochs** (≈15–20 minutes) and confirm on a block explorer that your validator is missing attestations before starting the new validator.

   * On Ethereum mainnet: use ``https://beaconcha.in``.
   * On Gnosis: use ``https://gnosischa.in``.

Step 4: Transfer keystores and slashing protection to the new node
-------------------------------------------------------------------

Copy the following from the old machine (or your backups) to the new Ethereum on ARM node using ``scp``, ``rsync``, or a removable drive:

* All ``keystore-m_....json`` files for your validators.
* The slashing protection JSON you exported in Step 2 (for example, ``slashing_protection.json``).

Example using ``scp``:

.. code-block:: bash

   scp /path/on/old-node/keystore-m_*.json user@new-node:/path/to/keystores/
   scp /path/on/old-node/slashing_protection.json user@new-node:/path/to/slashing/

Ensure file permissions and ownership match the user that will run your validator service (for example, ``ethereum``).

Step 5: Import keys and slashing protection on the new node
-----------------------------------------------------------

.. note::

   Replace ``<NETWORK>`` with ``mainnet``, ``gnosis``, ``holesky``, or ``hoodi`` (testnet) as appropriate.  
   When possible, import **slashing protection first**, then import keys, following client documentation.

Grandine
~~~~~~~~

1. Import keys:

   .. code-block:: bash

      grandine --network <NETWORK> validator import \
        --data-dir /home/ethereum/.grandine-validator \
        --keystore-dir /path/to/keystores \
        --keystore-password-file /path/to/password.txt

2. Import slashing protection:

   .. code-block:: bash

      grandine --network <NETWORK> interchange import slashing_protection.json

Lighthouse
~~~~~~~~~~

1. Import keys:

   .. code-block:: bash

      lighthouse account validator import \
        --network <NETWORK> \
        --directory /path/to/keystores \
        --datadir /home/ethereum/.lighthouse

2. Import slashing protection:

   .. code-block:: bash

      lighthouse account validator slashing-protection import \
        --network <NETWORK> \
        slashing_protection.json \
        --datadir /home/ethereum/.lighthouse

Lodestar
~~~~~~~~

1. Import keys:

   .. code-block:: bash

      lodestar validator import \
        --network <NETWORK> \
        --importKeystores /path/to/keystores \
        --dataDir /home/ethereum/.lodestar-validator

2. Import slashing protection:

   .. code-block:: bash

      lodestar validator slashing-protection import \
        --network <NETWORK> \
        --file slashing_protection.json \
        --dataDir /home/ethereum/.lodestar-validator

Nimbus
~~~~~~

1. Import keys:

   .. code-block:: bash

      nimbus_beacon_node deposits import \
        --data-dir=/home/ethereum/.nimbus-validator \
        /path/to/keystores

2. Import slashing protection:

   .. code-block:: bash

      nimbus_beacon_node slashingdb import \
        --data-dir=/home/ethereum/.nimbus-validator \
        slashing_protection.json

Prysm
~~~~~

1. Import keys into a Prysm wallet (nondeterministic wallet example):

   .. code-block:: bash

      validator accounts import \
        --keys-dir=/path/to/keystores \
        --wallet-dir=/home/ethereum/.prysm-wallet

   Adjust ``--wallet-dir`` to match your actual Prysm wallet directory.

2. Import slashing protection history on the new node:

   .. code-block:: bash

      validator slashing-protection-history import \
        --datadir=/home/ethereum/.prysm-validator \
        --slashing-protection-json-file=/path/to/slashing_protection.json

Teku
~~~~

1. Import keys:

   .. code-block:: bash

      teku validator import \
        --data-path=/home/ethereum/.teku \
        --from=/path/to/keystores

2. Import slashing protection:

   .. code-block:: bash

      teku slashing-protection import \
        --data-path=/home/ethereum/.teku \
        --from=slashing_protection.json

Step 6: Start the validator service on the new node
---------------------------------------------------

1. Enable and start your validator service via ``systemd`` (adjust the unit name for your client):

   .. code-block:: bash

      # Examples for different clients:
      sudo systemctl enable --now lighthouse-validator
      sudo systemctl enable --now prysm-validator
      sudo systemctl enable --now nimbus-validator
      sudo systemctl enable --now teku-validator
      sudo systemctl enable --now lodestar-validator

2. Tail the logs to confirm the validator is running and performing duties (look for messages like “Published attestation” or equivalent):

   .. code-block:: bash

      # Replace with your validator service name:
      sudo journalctl -fu lighthouse-validator

3. Verify on a block explorer that:

   * The validator status is ``Active``.
   * New attestations are appearing and marked as successful (green).

   Use ``beaconcha.in`` for Ethereum mainnet or ``gnosisscan.io`` / ``gnosischa.in`` for Gnosis.

Reinstalling the OS (Re-flashing SD Card)
-----------------------------------------

If you need to re-flash your SD card (for example, due to an OS failure or upgrade) but your execution and consensus data is safely stored on the NVMe drive, you can proceed without a full resync.

1. **Flash the SD card**: Flash the new Ethereum on ARM image onto your SD card and insert it into the device.
2. **First Boot**: Power on the device. The ``first-boot`` script will automatically detect the existing ``/home/ethereum`` partition on your NVMe drive and **will not** format it. It will preserve your data.
3. **Restore Configs**: If you previously used ``ethereumonarm-config-sync``, your configuration files will be automatically restored from the NVMe backup.
4. **Re-enable Services**: The new OS image comes with services disabled by default. You must manually enable and start the clients you were running.

   For example, if you were running Geth and Lighthouse:

   .. code-block:: bash

      sudo systemctl enable --now geth
      sudo systemctl enable --now lighthouse-beacon
      sudo systemctl enable --now lighthouse-validator

   If you were using **MEV-Boost** or **Commit-Boost**, remember to enable them as well:

   .. code-block:: bash

      sudo systemctl enable --now mev-boost
      sudo systemctl enable --now commit-boost

   If you are a **Lido** operator, ensure you enable the specific Lido validator service (refer to the :doc:`Lido documentation <../advanced/lido>` for details on your specific client):

   .. code-block:: bash

      # Example for Lighthouse with Lido
      sudo systemctl enable --now lighthouse-validator-lido

Additional safety recommendations
---------------------------------

* Always keep independent backups of your keystore files and slashing protection JSON before making changes.
* Consider enabling doppelganger protection where supported (Lighthouse, Lodestar, Nimbus, Prysm, Teku) during the first start on the new machine, to further reduce the risk if something went wrong in the timing.
* Never rely solely on the waiting period; slashing protection history (EIP-3076) is your primary defense against double signing.
