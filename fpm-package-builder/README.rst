This is a collection of Makefiles and scripts used to create all the Ethereum on ARM related packages

* Clone the repository::

.. code:: bash

	git clone https://github.com/diglos/ethereumonarm.git

* Install the requiered dependencies::
	
.. code:: bash

  # Set up the Ubuntu package repositories with the appropriate architecture
  # For x86_64 architecture:
  echo "deb [arch=amd64] http://us.archive.ubuntu.com/ubuntu/ $(lsb_release -cs) main restricted universe multiverse" > /etc/apt/sources.list
  echo "deb [arch=amd64] http://us.archive.ubuntu.com/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse" >> /etc/apt/sources.list
  echo "deb [arch=amd64] http://us.archive.ubuntu.com/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse" >> /etc/apt/sources.list
  echo "deb [arch=amd64] http://us.archive.ubuntu.com/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse" >> /etc/apt/sources.list
  # For ARM64 architecture:
  echo "deb [arch=arm64] http://ports.ubuntu.com/ $(lsb_release -cs) main restricted universe multiverse" >> /etc/apt/sources.list
  echo "deb [arch=arm64] http://ports.ubuntu.com/ $(lsb_release -cs)-updates main restricted universe multiverse" >> /etc/apt/sources.list
  echo "deb [arch=arm64] http://ports.ubuntu.com/ $(lsb_release -cs)-security main restricted universe multiverse" >> /etc/apt/sources.list
  echo "deb [arch=arm64] http://ports.ubuntu.com/ $(lsb_release -cs)-backports main restricted universe multiverse" >> /etc/apt/sources.list
  # Add arm64 architecture
  dpkg --add-architecture arm64
  
  # Update the package lists for all repositories
  echo 'Acquire::http::Pipeline-Depth "0";' > /etc/apt/apt.conf.d/90localsettings
  apt-get update
  # Install development tools and dependencies
  apt-get install -y libssl-dev:arm64 pkg-config software-properties-common docker.io docker-compose clang pkg-config file make cmake gcc-aarch64-linux-gnu g++-aarch64-linux-gnu ruby ruby-dev rubygems build-essential rpm vim git jq curl wget python3-pip
  # Install the fpm package management tool for Ruby
  gem install --no-document fpm
  # Add the longsleep/golang-backports PPA to the list of repositories
  add-apt-repository ppa:longsleep/golang-backports
  # Update the package lists again, including the newly added PPA
  apt-get update
  # Retrieve the GPG key for the repository containing the Go package
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F6BC817356A3D45E
  # Install the Go programming language
  apt-get -y install golang-go golang-1.18
  # Add the vagrant user to the docker group
  adduser vagrant docker
  # Install Rustup, the Rust toolchain installer, as the vagrant user
  su - vagrant -c "curl https://sh.rustup.rs -sSf | sh -s -- -y"
  # Reload the vagrant user's shell environment to pick up the changes made by Rustup
  su - vagrant -c "source ~/.cargo/env"
  # Add the aarch64 architecture as a Rust target
  su - vagrant -c "rustup target add aarch64-unknown-linux-gnu"
  sudo -u vagrant bash -c 'cat <<EOF > /home/vagrant/.cargo/config
  [target.aarch64-unknown-linux-gnu]
  linker = "aarch64-linux-gnu-gcc"
  EOF	

* Alternatively easier and recommended, use the provided Vagrantfile to create an Ubuntu 20.04 VM with all the needed dependencies (you will need vagrant_ and virtualbox_) ::

.. _vagrant: https://www.vagrantup.com/docs/installation
.. _virtualbox: https://www.virtualbox.org/wiki/Downloads

.. code:: bash

	cd ethereumonarm/fpm-package-builder
	vagrant up
	vagrant ssh
	cd ethereumonarm/

* Just type make to create all the deb packages::

.. code:: bash

	make

* Alternatively you can simple cd into any dir and type make to create only the desired package::

.. code:: bash

	cd geth
	make
