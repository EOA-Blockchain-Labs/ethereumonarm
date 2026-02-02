.. _development_guide:

.. meta::
   :description lang=en: Build Ethereum on ARM images and packages. Development guide for FPM package builder, Armbian images, and cloud image creation with Packer.
   :keywords: build ARM image, FPM packages, Armbian Ethereum, cloud image builder, development guide

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

From here, you have **three** options for setting up the development environment: using Docker (recommended), installing dependencies manually, or using a Vagrant machine.

2.1 Use Docker (Recommended)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The **only supported way** to create a fully configured, reproducible build environment is to use the included Docker setup.
This ensures that you are using the exact same toolchain as the official builds.

**Steps:**

1. **Build the builder image** (only needed once):

   .. code-block:: bash

      make docker-image

   .. warning::

      **Cross-Compilation on x86_64 / AMD64 hosts**

      If you are building on an Intel/AMD machine (x86_64), you **must** install QEMU user-static emulation to build the ARM64 Docker image. Run this command once before building:

      .. code-block:: bash

         docker run --privileged --rm tonistiigi/binfmt --install all

2. **Run a build**:

   To build all packages:

   .. code-block:: bash

      make docker-run cmd="make all"

   To build a specific package (e.g., Geth):

   .. code-block:: bash

      make docker-run cmd="make geth"

   If you need to debug or run multiple commands, you can enter an interactive shell inside the builder:

   .. code-block:: bash

      make docker-shell

2.2 Install Dependencies Manually (Ubuntu 24.04)
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

2.3. Alternatively, use the Provided Vagrantfile (Recommended)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

For an easier and recommended setup, use the provided Vagrantfile to create an Ubuntu 24.04 VM with all necessary dependencies. You will need `Vagrant <https://www.vagrantup.com/docs/installation>`_ and `VirtualBox <https://www.virtualbox.org/wiki/Downloads>`_ installed.

.. code-block:: bash

   cd ethereumonarm/fpm-package-builder
   vagrant up
   vagrant ssh
   cd ethereumonarm/

2.4. Create .deb Packages
^^^^^^^^^^^^^^^^^^^^^^^^^

Once your environment is set up (either manually or with Vagrant), you can create ``.deb`` packages.

* To create all ``.deb`` packages, simply type ``make``:

  .. code-block:: bash

     make

* **New:** To create a specific package directly from the root (e.g., ``geth``, ``prysm``), type:

  .. code-block:: bash

     make geth
     make prysm

* Alternatively, you can still navigate to the desired client or package directory (e.g., ``geth``) and type ``make``:

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

4. Adding a New Package
-----------------------

This section guides you through adding a new software package (Client, Tool, or Service) to the repository using our standardized templates.

4.1. Directory Setup
^^^^^^^^^^^^^^^^^^^^

Navigate to ``fpm-package-builder`` and choose the appropriate category:

*   **Layer 1**: ``l1-clients/consensus-layer/`` or ``l1-clients/execution-layer/``
*   **Layer 2**: ``l2-clients/``
*   **Infrastructure**: ``infra/`` or ``infra/dvt/``
*   **Tools/Web3**: ``tools/`` or ``web3/``

Instead of creating directories manually, copy the standard template:

.. code-block:: bash

   # Example: Adding a new tool called "my-new-tool"
   cp -r build-scripts/templates infra/my-new-tool
   cd infra/my-new-tool

The template creates the following structure for you:

*   ``Makefile``: The build script.
*   ``extras/``: Directory for service files and scripts.
*   ``sources/``: Directory for configuration files.

4.2. Customize the Package
^^^^^^^^^^^^^^^^^^^^^^^^^^

Follow the detailed guide included in the template or `view it online <https://github.com/EOA-Blockchain-Labs/ethereumonarm/blob/main/fpm-package-builder/build-scripts/templates/HOWTO_ADD_PROJECT.md>`_.

**Key Steps:**

1.  **Makefile**:
    Update ``PKG_NAME``, ``PKG_DESCRIPTION``, and the ``prepare`` target to download your specific binary.

    .. important::
       You **MUST** verify the upstream binary using SHA256 or GPG.

2.  **Service File**:
    Rename ``extras/service.service`` to ``extras/<pkg-name>.service`` and update the ``ExecStart`` command.

3.  **Configuration**:
    Rename ``sources/etc/ethereum/config.conf`` to ``sources/etc/ethereum/<pkg-name>.conf`` and set your default flags.

4.3. Test the Build
^^^^^^^^^^^^^^^^^^^

Run ``make`` inside your directory. If successful, the ``.deb`` will appear in the relative ``packages/`` directory.

4.4. Test the Build
^^^^^^^^^^^^^^^^^^^

Run ``make`` inside your directory. If successful, the ``.deb`` will appear in the relative ``packages/`` directory.

5. Image Creation Tool
----------------------

The ``image-creation-tool`` directory contains scripts to build custom Armbian images for various Single Board Computers (SBCs).

4.1. Setup
^^^^^^^^^^

Navigate to the ``image-creation-tool/ubuntu`` directory:

.. code-block:: bash

   cd ethereumonarm/image-creation-tool/ubuntu

4.2. Building Images
^^^^^^^^^^^^^^^^^^^^

The ``Makefile`` in this directory automates the download, customization, and packaging of Armbian images. It uses a standalone script ``modify_image.sh`` to robustly detect partitions and inject the necessary files.

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

For more information, the existing documentation includes a :doc:`Getting Started Guide </getting-started/introduction>` and a :doc:`Operation Guide </running-a-node/introduction>`, which offer further details on Ethereum and client management.

4.4. Cloud Image Builder
^^^^^^^^^^^^^^^^^^^^^^^^

The ``image-creation-tool/cloud`` directory contains tools to build custom ARM64 cloud images for Ethereum nodes using `HashiCorp Packer <https://www.packer.io/>`_.

The templates are optimized for **Full Nodes**, defaulting to high-performance ARM64 instances (4 vCPUs, 16GB RAM) and large storage (2TB).

**Prerequisites:**

1. **Packer**: Install Packer on your local machine.

   * MacOS: ``brew install packer``
   * Linux: Follow instructions at `packer.io <https://learn.hashicorp.com/tutorials/packer/get-started-install-cli>`_

2. **Cloud Credentials**: You must have active credentials for the provider you want to build for.

**Usage:**

AWS Images
""""""""""

1. **Initialize**:

   .. code-block:: bash

      cd image-creation-tool/cloud
      packer init aws.pkr.hcl

2. **Build**:
   The default build uses a ``t4g.xlarge`` instance (4 vCPU, 16GB RAM) and a 2TB disk.

   .. code-block:: bash

      # Using environment variables for auth (Recommended)
      export AWS_ACCESS_KEY_ID="your_key"
      export AWS_SECRET_ACCESS_KEY="your_secret"
      packer build aws.pkr.hcl

      # OR passing variables explicitly
      packer build \
        -var "aws_access_key=your_key" \
        -var "aws_secret_key=your_secret" \
        aws.pkr.hcl

GCP Images
""""""""""

1. **Initialize**:

   .. code-block:: bash

      packer init gcp.pkr.hcl

2. **Build**:
   Requires a Service Account JSON file or Application Default Credentials. Defaults to ``t2a-standard-4`` instance and 2TB disk.

   .. code-block:: bash

      packer build \
        -var "project_id=your-project-id" \
        -var "account_file=path/to/key.json" \
        gcp.pkr.hcl

Azure Images
""""""""""""

1. **Initialize**:

   .. code-block:: bash

      packer init azure.pkr.hcl

2. **Build**:
   Defaults to ``Standard_D4ps_v5`` instance and 2TB disk.

   .. code-block:: bash

      # Ensure variables like ARM_CLIENT_ID are set in your environment OR pass them manually
      packer build \
        -var "resource_group=my-images-rg" \
        -var "client_id=..." \
        -var "client_secret=..." \
        -var "subscription_id=..." \
        -var "tenant_id=..." \
        azure.pkr.hcl

**Customization:**

You can override the following variables at build time:

.. list-table::
   :widths: 15 20 25 40
   :header-rows: 1

   * - Provider
     - Variable
     - Default Value
     - Description
   * - **All**
     - ``disk_size_gb``
     - ``2048`` (2TB)
     - Root disk size. Required for Full Node sync.
   * - **AWS**
     - ``instance_type``
     - ``t4g.xlarge``
     - 4 vCPU, 16GB RAM.
   * - **GCP**
     - ``machine_type``
     - ``t2a-standard-4``
     - 4 vCPU, 16GB RAM.
   * - **Azure**
     - ``vm_size``
     - ``Standard_D4ps_v5``
     - 4 vCPU, 16GB RAM.

Example:

.. code-block:: bash

   packer build -var "disk_size_gb=100" aws.pkr.hcl

**Example: Successful AWS AMI Creation**

When you run ``packer build aws.pkr.hcl``, a successful build output will look like this:

.. code-block:: text

   ==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: Prevalidating AMI Name: ethereum-on-arm-node-2026-01-07-2018
   ==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: Found Image ID: ami-0071c8c431eea0edb
   ==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: Launching a source AWS instance...
   ==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: Provisioning with shell script: scripts/provision.sh
       ethereum-on-arm-aws.amazon-ebs.ethereum-node: Updating system...
       ethereum-on-arm-aws.amazon-ebs.ethereum-node: Installing Ethereum packages...
       ethereum-on-arm-aws.amazon-ebs.ethereum-node: Installing Monitoring packages...
   ==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: Stopping the source instance...
   ==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: Waiting for the instance to stop...
   ==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: Creating AMI: ethereum-on-arm-node-2026-01-07-2018
   ==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: AMI: ami-0925af779d95c2b3e
   ==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: Terminating the source AWS instance...
   ==> Builds finished. The artifacts of successful builds are:
   --> ethereum-on-arm-aws.amazon-ebs.ethereum-node: AMIs were created:
   us-east-1: ami-0925af779d95c2b3e

**Start Node with Terraform**

Once your AMI is created (e.g., ``ami-0925af779d95c2b3e``), you can use it in Terraform to launch a node:

.. code-block:: hcl

   resource "aws_instance" "ethereum_node" {
     ami           = "ami-0925af779d95c2b3e"
     instance_type = "t4g.xlarge" # Recommended: 4 vCPUs, 16GB RAM

     root_block_device {
       volume_size = 2048 # 2 TB disk
       volume_type = "gp3"
     }

     tags = {
       Name = "Ethereum Node"
     }
   }

**Monthly Cost Simulation**

.. note::
   These cost simulations are estimates generated by AI and may vary based on region, pricing changes, and specific configuration.

Based on the default configuration (4 vCPU, 16GB RAM, 2TB SSD) in the US region:

.. list-table::
   :widths: 15 25 30 30
   :header-rows: 1

   * - Provider
     - Instance
     - Storage
     - Approx. Monthly Cost
   * - **AWS**
     - ``t4g.xlarge``
     - 2TB ``gp3``
     - ~$260
   * - **GCP**
     - ``t2a-standard-4``
     - 2TB ``pd-balanced``
     - ~$310
   * - **Azure**
     - ``Standard_D4ps_v5``
     - 2TB Managed SSD
     - ~$250