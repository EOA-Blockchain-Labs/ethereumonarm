This is a collection of Makefiles and scripts used to create all the Ethereum on ARM related packages

* Clone the repository::

	$ git clone https://github.com/diglos/ethereumonarm.git

* Optional but recommended use the provided Vagrantfile to create an Ubuntu 20.04 VM with all the needed dependencies::


	$ cd ethereumonarm/fpm-package-builder
	$ vagrant up
	$ vagrant ssh
	$ cd ethereumonarm/


* Just type make to create all the deb packages::


	$ make



* Alternatively you can simple cd into any dir and type make to create only the desired package::


	$ cd geth
	$ make
