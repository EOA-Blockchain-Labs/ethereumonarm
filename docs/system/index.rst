.. _system-utilities:

.. meta::
   :description lang=en: System utilities for Ethereum on ARM. Network configuration, VPN setup, backup and restore, security hardening, and troubleshooting guides.
   :keywords: Ethereum node utilities, ARM system config, node backup, UFW firewall, troubleshooting blockchain

System Utilities
================

Tools and guides for managing, securing, and maintaining your Ethereum on ARM node.

.. grid:: 1 2 2 2
   :gutter: 3

   .. grid-item-card:: 🌐 Network & VPN
      :link: /system/network-vpn
      :link-type: doc
      :class-card: sd-border-primary

      Configure networking, PiVPN, and remote access.

   .. grid-item-card:: 💾 Backup & Restore
      :link: /system/backup-restore
      :link-type: doc
      :class-card: sd-border-success

      Protect your validator keys and node data.

   .. grid-item-card:: 🔒 Security
      :link: /system/security
      :link-type: doc
      :class-card: sd-border-warning

      Harden your node against attacks.

   .. grid-item-card:: 🔧 Troubleshooting
      :link: /system/troubleshooting
      :link-type: doc
      :class-card: sd-border-info

      Common issues and solutions.

Maintenance Essentials
----------------------

.. dropdown:: Key Backup Checklist
   :icon: checklist
   :open:

   Before anything goes wrong, ensure you have backed up:

   - ✅ Validator keystores (``/home/ethereum/validator_keys/``)
   - ✅ Validator mnemonic (written offline, never digitally)
   - ✅ Slashing protection database
   - ✅ JWT secret (``/etc/ethereum/jwtsecret``)

   :doc:`Full backup guide → </system/backup-restore>`

.. dropdown:: Security Best Practices
   :icon: shield

   - 🔐 Change default passwords immediately
   - 🔥 Configure UFW firewall
   - 🔑 Use SSH key authentication
   - 🚫 Disable root login
   - 📡 Use VPN for remote access

   :doc:`Security guide → </system/security>`

Quick Commands
--------------

.. code-block:: bash

   # Check disk usage
   df -h

   # View system logs
   sudo journalctl -u geth -f

   # Check memory usage
   free -h

   # Monitor all Ethereum services
   sudo systemctl status geth lighthouse-beacon

.. seealso::

   - :doc:`/running-a-node/managing-clients` - Service management
   - :doc:`/getting-started/installation` - Initial setup
