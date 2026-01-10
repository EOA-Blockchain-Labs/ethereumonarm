.. _contributing-guidelines:

Contributing Guidelines
=======================

Thank you for your interest in contributing to Ethereum on ARM! This guide will help you get started.

.. tip::
   We welcome contributions of all kinds—code, documentation, bug reports, and feature requests.

Quick Links
-----------

.. grid:: 1 2 2 3
   :gutter: 3

   .. grid-item-card:: 🛠️ Building Images
      :link: /contributing/building-images
      :link-type: doc
      :class-card: sd-border-primary

      Create custom ARM images for Ethereum nodes.

   .. grid-item-card:: 📚 Sources
      :link: /contributing/sources
      :link-type: doc
      :class-card: sd-border-info

      Reference materials and upstream project links.

   .. grid-item-card:: 📦 Package Repository
      :link: https://github.com/EOA-Blockchain-Labs/ethereumonarm
      :class-card: sd-border-success

      View the source code on GitHub.

Getting Started
---------------

1. Fork the Repository
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   git clone https://github.com/EOA-Blockchain-Labs/ethereumonarm.git
   cd ethereumonarm

2. Set Up Development Environment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For package building, see the :doc:`Building Images </contributing/building-images>` guide.

For documentation changes:

.. code-block:: bash

   cd docs
   docker compose up  # Live preview at http://localhost:8000

3. Make Your Changes
~~~~~~~~~~~~~~~~~~~~

- Create a feature branch: ``git checkout -b feature/my-change``
- Follow existing code style and conventions
- Test your changes locally

4. Submit a Pull Request
~~~~~~~~~~~~~~~~~~~~~~~~

- Push your branch: ``git push origin feature/my-change``
- Open a PR against the ``main`` branch
- Describe your changes clearly

Contribution Areas
------------------

.. dropdown:: 📦 Package Development
   :icon: package

   Add or update Ethereum client packages in ``fpm-package-builder/``:

   - **L1 Clients**: ``l1-clients/`` (Geth, Nethermind, Lighthouse, etc.)
   - **L2 Clients**: ``l2-clients/`` (Arbitrum, Optimism, Starknet)
   - **Infrastructure**: ``infra/`` (Monitoring, DVT, MEV tools)

   Each package includes:
   
   - ``Makefile`` - Build automation
   - ``sources/`` - Configuration files
   - ``extras/`` - Systemd service units

.. dropdown:: 📝 Documentation
   :icon: book

   Improve docs in the ``docs/`` directory:

   - Fix typos, clarify instructions
   - Add new guides for supported software
   - Update hardware compatibility info
   - Translate documentation

   Build locally:

   .. code-block:: bash

      cd docs && docker compose up

.. dropdown:: 🐛 Bug Reports
   :icon: bug

   Found a bug? Open an issue on GitHub with:

   - Device model and RAM
   - Ethereum on ARM version
   - Steps to reproduce
   - Error messages or logs

   `Open an Issue → <https://github.com/EOA-Blockchain-Labs/ethereumonarm/issues>`_

.. dropdown:: 💡 Feature Requests
   :icon: light-bulb

   Have an idea? We'd love to hear it!

   - New client support
   - Hardware compatibility
   - Tooling improvements

   `Start a Discussion → <https://github.com/EOA-Blockchain-Labs/ethereumonarm/discussions>`_

Code Style
----------

.. csv-table::
   :align: left
   :header: Area, Guidelines

   Shell Scripts, Use ``shellcheck``; quote variables; use ``set -e``
   Makefiles, Use tabs for indentation; document targets with ``##``
   RST Docs, 80-char lines; use semantic sections; include code examples
   Commits, Conventional commits (``feat:``, ``fix:``, ``docs:``)

Community
---------

.. grid:: 1 2 2 2
   :gutter: 3

   .. grid-item-card:: 💬 Discord
      :link: https://discord.gg/ve2Z8fxz5N
      :class-card: sd-border-primary

      Join our community for support and discussion.

   .. grid-item-card:: 🐦 Twitter
      :link: https://twitter.com/EthereumOnARM
      :class-card: sd-border-info

      Follow for updates and announcements.

   .. grid-item-card:: 📧 Email
      :link: mailto:info@ethereumonarm.com
      :class-card: sd-border-secondary

      Contact the maintainers directly.

   .. grid-item-card:: 🌐 Website
      :link: https://ethereumonarm.com
      :class-card: sd-border-success

      Official project website.

License
-------

By contributing, you agree that your contributions will be licensed under the project's existing license (GNU GPL v3.0).

.. seealso::

   - :doc:`Building Images </contributing/building-images>` - Detailed development guide
   - :doc:`Sources </contributing/sources>` - Upstream project references
