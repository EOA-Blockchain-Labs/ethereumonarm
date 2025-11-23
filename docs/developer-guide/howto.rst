.. _development_guide:

Development Guide
=================

This guide outlines the development process for the Ethereum on ARM project, covering repository setup, dependency management, package creation, and image generation.

1. Clone the Repository
-----------------------

Begin by cloning the Ethereum on ARM repository from GitHub:

.. code-block:: bash

   git clone https://github.com/EOA-Blockchain-Labs/ethereumonarm.git


2. Setup for Package Building (fpm-package-builder)
---------------------------------------------------

Navigate to the ``fpm-package-builder`` directory within the cloned repository:

.. code-block:: bash

   cd ethereumonarm/fpm-package-builder

From here, you have two options for setting up the development environment: installing dependencies manually or using a Vagrant machine.

2.1 Install Dependencies Manually (Ubuntu 24.04)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you prefer to install dependencies directly on an Ubuntu 24.04 system, follow these steps:

* **Prepare APT sources:**

  .. code-block:: bash

     echo "# See /etc/apt/sources.list.d/ for repository configuration" > /etc/apt/sources.list
     rm -f /etc/apt/sources.list.d/ubuntu.sources
     UBUNTU_CODENAME=$(lsb_release -cs)
     cat <<EOF > /etc/apt/sources.list.d/ubuntu-amd64.sources
     Types: deb
     URIs: http://us.archive.ubuntu.com/ubuntu
     Suites: ${UBUNTU_CODENAME} ${UBUNTU_CODENAME}-updates ${UBUNTU_CODENAME}-security ${UBUNTU_CODENAME}-backports
     Components: main restricted universe multiverse
     Architectures: amd64
     Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
     EOF
     cat <<EOF > /etc/apt/sources.list.d/ubuntu-arm64.sources
     Types: deb
     URIs: http://ports.ubuntu.com
     Suites: ${UBUNTU_CODENAME} ${UBUNTU_CODENAME}-updates ${UBUNTU_CODENAME}-security ${UBUNTU_CODENAME}-backports
     Components: main restricted universe multiverse
     Architectures: arm64
     Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
     EOF

* **Add ARM64 architecture and update package lists:**

  .. code-block:: bash

     dpkg --add-architecture arm64
     echo 'Acquire::http::Pipeline-Depth "0";' > /etc/apt/apt.conf.d/90localsettings
     apt-get update -y

* **Install development tools and dependencies:**

  .. code-block:: bash

     apt-get install -y libssl-dev:arm64 pkg-config software-properties-common docker.io docker-compose clang file make cmake gcc-aarch64-linux-gnu g++-aarch64-linux-gnu ruby ruby-dev rubygems build-essential rpm vim git jq curl wget python3-pip

* **Install FPM (fpm-package management tool for Ruby):**

  .. code-block:: bash

     gem install --no-document fpm

* **Add Go PPA and install Go:**

  .. code-block:: bash

     add-apt-repository -y ppa:longsleep/golang-backports
     apt-get update -y
     apt-get -y install golang-go

* **Add `vagrant` user to `docker` group:**

  .. code-block:: bash

     usermod -aG docker $USER

* **Install Rustup and add aarch64 target:**

  .. code-block:: bash

     curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable
     source ~/.cargo/env && rustup target add aarch64-unknown-linux-gnu

* **Configure linker for aarch64 Rust target:**

  .. code-block:: bash

     mkdir -p ~/.cargo && cat <<EOF > ~/.cargo/config
     [target.aarch64-unknown-linux-gnu]
     linker = "aarch64-linux-gnu-gcc"
     EOF

* **Add Node.js and Yarn installation:**

  .. code-block:: bash

     curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
     export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install 20
     export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && npm install -g yarn

2.2. Alternatively, use the Provided Vagrantfile (Recommended)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

For an easier and recommended setup, use the provided Vagrantfile to create an Ubuntu 24.04 VM with all necessary dependencies. You will need `Vagrant <https://www.vagrantup.com/docs/installation>`_ and `VirtualBox <https://www.virtualbox.org/wiki/Downloads>`_ installed.

.. code-block:: bash

   cd ethereumonarm/fpm-package-builder
   vagrant up
   vagrant ssh
   cd ethereumonarm/

2.3. Create .deb Packages
^^^^^^^^^^^^^^^^^^^^^^^^^

Once your environment is set up (either manually or with Vagrant), you can create ``.deb`` packages.

* To create all ``.deb`` packages, simply type ``make``:

  .. code-block:: bash

     make

* Alternatively, to create only a specific package, navigate to the desired client or package directory (e.g., ``geth``) and type ``make``:

  .. code-block:: bash

     cd geth
     make

3. Deep Dive: Understanding the Packaging Process
-------------------------------------------------

This section provides a detailed look at how the packaging process works, why we use FPM, and the structure of the repository.

3.1. Why FPM?
^^^^^^^^^^^^^

We use `FPM (Effing Package Management) <https://fpm.readthedocs.io/en/latest/>`_ because it simplifies the process of creating packages for multiple platforms (Debian/Ubuntu ``.deb``, RedHat/Fedora ``.rpm``, etc.) from a single source directory. It abstracts away much of the complexity associated with native packaging tools like ``dpkg-deb`` or ``rpmbuild``, allowing us to focus on the content and configuration of the package.

3.2. The Generic Packaging Procedure
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The packaging process is automated via ``Makefile`` scripts in each client's directory. The general workflow is:

1.  **Prepare**: The ``make prepare`` target downloads the upstream binary (e.g., Geth, Teku) and verifies its integrity.
2.  **Stage**: Files are organized into a ``sources/`` directory that mirrors the target system's file structure (e.g., ``/usr/bin``, ``/etc/ethereum``).
3.  **Build**: FPM takes the ``sources/`` directory and combines it with metadata (version, maintainer, dependencies) and extra files (systemd units) to generate the final ``.deb`` or ``.rpm`` package.

3.3. Repository Structure & Key Files
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Understanding the file structure is key to customizing packages. Here is a breakdown using **Teku** as an example:

*   **Makefile**: The heart of the build process. It defines variables like ``PKG_NAME``, ``TEKU_VERSION``, and ``FPM_OPTS``. It orchestrates the download, staging, and FPM commands.

*   **sources/**: This directory acts as a "fake root" for the package.

    *   ``sources/usr/bin/``: Contains the executable binaries.
    *   ``sources/etc/ethereum/``: Contains default configuration files.

        *   *Example:* ``l1-clients/consensus-layer/teku/sources/etc/ethereum/teku-beacon.conf`` defines the default flags for the Teku beacon node.

*   **extras/**: Contains files that are not part of the main file tree but are used by the package manager, such as systemd service units.

    *   *Example:* ``l1-clients/consensus-layer/teku/extras/teku-beacon.service`` is the systemd unit file that manages the Teku service. It defines how the service starts, restarts, and what user it runs as.

*   **scripts/** (optional): Contains ``post-install`` or ``pre-remove`` scripts that run during package installation or removal (e.g., creating a user, setting permissions).

By modifying files in ``sources/`` or ``extras/``, you can customize the default configuration or service behavior of the resulting package.

4. Image Creation Tool
----------------------

The ``image-creation-tool`` directory contains scripts to build custom Armbian images for various Single Board Computers (SBCs).

4.1. Setup
^^^^^^^^^^

Navigate to the ``image-creation-tool/ubuntu`` directory:

.. code-block:: bash

   cd ethereumonarm/image-creation-tool/ubuntu

4.2. Building Images
^^^^^^^^^^^^^^^^^^^^

The ``Makefile`` in this directory automates the download, customization, and packaging of Armbian images.

* **Build all images:**

  To build images for all supported devices, run:

  .. code-block:: bash

     make all

* **Build a specific image:**

  To build an image for a specific device (e.g., ``rock5b``), run:

  .. code-block:: bash

     make build DEVICE=rock5b

  **Supported Devices:**

  - ``rpi5`` (Raspberry Pi 5)
  - ``rock5b`` (Radxa Rock 5B)
  - ``orangepi5-plus`` (Orange Pi 5 Plus)
  - ``nanopct6`` (NanoPC T6)

4.3. Clean Up
^^^^^^^^^^^^^

To remove all generated images and downloaded files, run:

.. code-block:: bash

   make clean

For more information, the existing documentation includes a `Quick Start Guide </quick-guide/about-quick-start>`_ and a `User Guide </user-guide/about-user-guide>`_, which offer further details on Ethereum and client management.