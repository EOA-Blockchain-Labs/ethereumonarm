Migrating a Validator
=====================

.. danger::

   **SLASHING RISK: DOUBLE SIGNING**

   Never run the same validator keys on two different machines at the same time.
   This can result in a slashing event, causing you to be ejected from the network
   and lose a significant portion of your stake.

   Always ensure the old validator is completely stopped and disabled before
   starting the new one.

Overview
--------

This document explains how to safely move an Ethereum validator from one machine
to another (for example, from a cloud VPS or an old desktop to an Ethereum on ARM
board), while minimizing the risk of slashing.

The procedure applies to common consensus clients:

- Grandine
- Lighthouse
- Nimbus
- Prysm
- Teku
- Lodestar

It assumes you already have working execution and consensus clients on both
machines.

Prerequisites
-------------

* **New node**: Your Ethereum on ARM board (Rock 5B, Orange Pi, etc.) must be
  installed, powered on, and fully synced (execution + consensus).
* **Old node**: You must have terminal access to your current validator host.
* **Key material**: Your original ``keystore-m_*.json`` files and their password
  must be safely backed up and available.

Step 1: Sync the new node (without keys)
----------------------------------------

1. Start your execution client on the new node (Geth, Nethermind, Erigon, Reth)
   and allow it to fully sync.
2. Start your consensus client (Lighthouse, Nimbus, Prysm, Teku, Lodestar,
   Grandine) and allow the beacon node to reach head.
3. **Do NOT import validator keys or start any validator service yet.**

The new node must be fully synced before it is allowed to sign duties.

Step 2: Stop the old validator and export slashing protection
-------------------------------------------------------------

.. note::

   On Ethereum on ARM, validator services are client-specific.
   Common service names include:

   * ``lighthouse-validator``
   * ``nimbus-validator``
   * ``prysm-validator``
   * ``teku-validator``
   * ``lodestar-validator``
   * ``grandine-validator``

1. Stop the validator **before exporting slashing protection**.

   .. code-block:: bash

      sudo systemctl stop lighthouse-validator
      sudo systemctl stop nimbus-validator
      sudo systemctl stop prysm-validator
      sudo systemctl stop teku-validator
      sudo systemctl stop lodestar-validator
      sudo systemctl stop grandine-validator

2. Export slashing protection from the **old node**.

   Grandine
     .. code-block:: bash

        grandine --network <NETWORK> interchange export slashing_protection.json

   Lighthouse
     .. code-block:: bash

        lighthouse slashing-protection export \
          --datadir /home/ethereum/.lighthouse \
          --output slashing_protection.json

   Prysm
     .. code-block:: bash

        prysmctl slashing-protection export \
          --datadir=/home/ethereum/.eth2 \
          --output=slashing_protection.json

   Nimbus
     .. code-block:: bash

        nimbus_beacon_node slashingdb export \
          --data-dir=/home/ethereum/.local/share/nimbus \
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
          --dataDir /home/ethereum/.lodestar-validator

3. Verify that ``slashing_protection.json`` exists and back it up securely.

Step 3: Disable and clean up the old validator
----------------------------------------------

1. Disable the validator service so it cannot auto-start:

   .. code-block:: bash

      sudo systemctl disable lighthouse-validator
      sudo systemctl disable nimbus-validator
      sudo systemctl disable prysm-validator
      sudo systemctl disable teku-validator
      sudo systemctl disable lodestar-validator
      sudo systemctl disable grandine-validator

2. Confirm no validator processes are running:

   .. code-block:: bash

      ps aux | grep validator | grep -v grep

3. Once backups are confirmed, **delete or move** validator keys from the old
   machine.
4. Wait **2–3 epochs** (≈15–20 minutes) and confirm on a beacon explorer that
   attestations are missing:

   * Ethereum: https://beaconcha.in
   * Gnosis: https://gnosischa.in

Step 4: Transfer keystores and slashing protection
--------------------------------------------------

Copy to the new Ethereum on ARM node:

* ``keystore-m_*.json`` files
* ``slashing_protection.json``

Example:

.. code-block:: bash

   scp keystore-m_*.json ethereum@new-node:/home/ethereum/validator_keys/
   scp slashing_protection.json ethereum@new-node:/home/ethereum/

Ensure ownership matches the ``ethereum`` user.

Step 5: Import keys and slashing protection (new node)
------------------------------------------------------

.. note::

   Replace ``<NETWORK>`` with ``mainnet``, ``gnosis`` or ``hoodi``.
   Import slashing protection **before starting the validator**.

Grandine
~~~~~~~~

1. Import keys:

   .. code-block:: bash

      grandine --network <NETWORK> validator import \
        --data-dir /home/ethereum/.grandine-validator \
        --keystore-dir /home/ethereum/validator_keys \
        --keystore-password-file /home/ethereum/password.txt

2. Import slashing protection:

   .. code-block:: bash

      grandine --network <NETWORK> interchange import slashing_protection.json

Lighthouse
~~~~~~~~~~

1. Import keys:

   .. code-block:: bash

      lighthouse account validator import \
        --network <NETWORK> \
        --directory /home/ethereum/validator_keys \
        --datadir /home/ethereum/.lighthouse

2. Import slashing protection:

   .. code-block:: bash

      lighthouse slashing-protection import \
        --datadir /home/ethereum/.lighthouse \
        slashing_protection.json

Lodestar
~~~~~~~~

1. Import keys:

   .. code-block:: bash

      lodestar validator import \
        --network <NETWORK> \
        --directory /home/ethereum/validator_keys \
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
        --data-dir=/home/ethereum/.local/share/nimbus \
        /home/ethereum/validator_keys

2. Import slashing protection:

   .. code-block:: bash

      nimbus_beacon_node slashingdb import \
        --data-dir=/home/ethereum/.local/share/nimbus \
        slashing_protection.json

Prysm
~~~~~

1. Import keys:

   .. code-block:: bash

      prysmctl accounts import \
        --keys-dir=/home/ethereum/validator_keys \
        --wallet-dir=/home/ethereum/.eth2validators

2. Import slashing protection:

   .. code-block:: bash

      prysmctl slashing-protection import \
        --datadir=/home/ethereum/.eth2 \
        --input=slashing_protection.json

Teku
~~~~

1. Import keys:

   .. code-block:: bash

      teku validator-client import-keystores \
        --data-path=/home/ethereum/.teku \
        --from=/home/ethereum/validator_keys \
        --recursive=true

2. Import slashing protection:

   .. code-block:: bash

      teku slashing-protection import \
        --data-path=/home/ethereum/.teku \
        --from=slashing_protection.json

Step 6: Start the validator service
-----------------------------------

Enable and start **only the validator you use**:

.. code-block:: bash

   sudo systemctl enable --now lighthouse-validator
   sudo systemctl enable --now nimbus-validator
   sudo systemctl enable --now prysm-validator
   sudo systemctl enable --now teku-validator
   sudo systemctl enable --now lodestar-validator
   sudo systemctl enable --now grandine-validator

.. note::

   If you are using MEV-Boost or Commit-Boost, you should use the ``-mev``
   systemd service variants instead. For example:

   * ``lighthouse-beacon-mev`` instead of ``lighthouse-beacon``
   * ``lighthouse-validator-mev`` instead of ``lighthouse-validator``

Follow logs:

.. code-block:: bash

   sudo journalctl -fu lighthouse-validator

Verify on a beacon explorer that:

* Validator is ``Active``
* Attestations are successful

Reinstalling the OS (Re-flashing SD Card)
------------------------------------------

If you re-flash the SD card while using NVMe storage:

1. Flash the new Ethereum on ARM image.
2. Boot the device. The ``first-boot`` script will detect the existing
   ``/home/ethereum`` partition and **will not format it**.
3. If ``ethereumonarm-config-sync`` was enabled, configs will be restored.
4. Re-enable services:

   .. code-block:: bash

      sudo systemctl enable --now geth
      sudo systemctl enable --now lighthouse-beacon
      sudo systemctl enable --now lighthouse-validator

   If using MEV-Boost or Commit-Boost:

   .. code-block:: bash

      sudo systemctl enable --now mev-boost
      sudo systemctl enable --now commit-boost

Additional safety recommendations
---------------------------------

* Always keep offline backups of keystores and slashing protection JSON.
* Enable doppelganger protection where supported during first startup.
* Slashing protection (EIP-3076) is your primary defense — waiting alone is not sufficient.