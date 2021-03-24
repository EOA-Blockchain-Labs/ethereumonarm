This is a collection of Makefiles and scripts used to create all the Ethereum on ARM related packages

* Clone the repository::

.. code:: bash

	git clone https://github.com/diglos/ethereumonarm.git

* Install the requiered dependencies::
	
.. code:: bash

	apt-get update
	apt-get install -y clang pkg-config file make cmake gcc-aarch64-linux-gnu g++-aarch64-linux-gnu ruby ruby-dev rubygems build-essential rpm vim git jq   curl wget python3-pip
	gem install --no-document fpm
	curl https://sh.rustup.rs -sSf | sh -s -- -y
        cat <<EOF >> ~/.cargo/config
        [target.aarch64-unknown-linux-gnu]
        linker = "aarch64-linux-gnu-gcc"
        EOF
        source ~/.cargo/env
        rustup target add aarch64-unknown-linux-gnu
        rustup update
	
* Fix an FPM bug https://github.com/jordansissel/fpm/issues/1749::

.. code:: bash

	sed -i '22a \t: # Ensure this if-clause is not empty. If it were empty, and we had an 'else', then it is an error in shell syntax' /var/lib/gems/2.7.0/gems/fpm-1.12.0/templates/deb/postinst_upgrade.sh.erb 
	

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
