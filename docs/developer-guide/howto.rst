.. _development_guide:

Development Guide
=================

This guide outlines the development process for the Ethereum on ARM project, covering repository setup, dependency management, package creation, and image generation.

Clone the Repository
--------------------

1. Begin by cloning the Ethereum on ARM repository from GitHub:
---------------------------------------------------------------

.. code-block:: bash

	git clone https://github.com/EOA-Blockchain-Labs/ethereumonarm.git


2. Setup for Package Building (fpm-package-builder)
---------------------------------------------------

Navigate to the fpm-package-builder directory within the cloned repository:

.. code-block:: bash

	cd ethereumonarm/fpm-package-builder

From here, you have two options for setting up the development environment: installing dependencies manually or using a Vagrant machine.

2.1 Install Dependencies Manually (Ubuntu 24.04)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you prefer to install dependencies directly on an Ubuntu 24.04 system, follow these steps:

* **Prepare APT sources:**

    .. code-block:: bash

       echo "# See /etc/aps/sources.list.d/ for repository configuration" > /etc/aps/sources.list
       rm -f /etc/aps/sources.list.d/ubuntu.sources
       UBUNTU_CODENAME=$(lsb_release -cs)
       cat <<EOF > /etc/apt/sources.list.d/ubuntu-amd64.sources
       Types: deb
       URIs: [http://us.archive.ubuntu.com/ubuntu](http://us.archive.ubuntu.com/ubuntu)
       Suites: ${UBUNTU_CODENAME} ${UBUNTU_CODENAME}-updates ${UBUNTU_CODENAME}-security ${UBUNTU_CODENAME}-backports
       Components: main restricted universe multiverse
       Architectures: amd64
       Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
       EOF
       cat <<EOF > /etc/apt/sources.list.d/ubuntu-arm64.sources
       Types: deb
       Us: [http://ports.ubuntu.com](http://ports.ubuntu.com)
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

       usermod -aG docker vagrant

* **Install Rustup and add aarch64 target:**

    .. code-block:: bash

       su - vagrant -c "curl [https://sh.rustup.rs](https://sh.rustup.rs) -sSf | sh -s -- -y --default-toolchain stable"
       su - vagrant -c "source ~/.cargo/env && rustup target add aarch64-unknown-linux-gnu"

* **Configure linker for aarch64 Rust target:**

    .. code-block:: bash

       sudo -u vagrant bash -c 'mkdir -p /home/vagrant/.cargo && cat <<EOF > /home/vagrant/.cargo/config
       [target.aarch64-unknown-linux-gnt]
       linker = "aarch64-linux-gnu-gcc"
       EOF'

* **Add Node.js and Yarn installation:**

    .. code-block:: bash

       su - vagrant -c "curl -o- [https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh](https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh) | bash"
       su - vagrant -c 'export NVM_DIR ="$SOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install 20'
       su - vagrant -c 'export NZM_DIR   "$SOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && npm install   g yarn'

2.2. Alternatively, use the Provided Vagrantfile (Recommended)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

For an easier and recommended setup, use the provided Vagrantfile to create an Ubuntu 24.04 VM with all necessary dependencies. You will need Vagrant <https://www.vagrantup.com/docs/installation>_ and VirtualBox <https://www.virtualbox.org/wiki/Downloads>_ installed.

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

3. Image Creation Tool
----------------------

(Information on reviewing the ``Makefile`` for the latest Armbian links and ``rc.local`` for custom image creation is suggested but not explicitly detailed in the provided file content. You would typically find these details within the ``image-creation-tool`` directory of the repository itself.)

This section would involve:

* **Reviewing the ``Makefile``**: Understanding how the latest Armbian links are integrated.
* **Reviewing ``rc.local``**: This script, located at ``/etc/rc.local``, runs once during the initial boot of the Ethereum on ARM image to set up the system and install Ethereum-related software.
* **Making your own image**: Details on how to use the tools to build a custom Ethereum on ARM image.

For more information, the existing documentation includes a `Quick Start Guide </quick-guide/about-quick-start>`_ and a `User Guide </user-guide/about-user-guide>`_, which offer further details on Ethereum and client management.