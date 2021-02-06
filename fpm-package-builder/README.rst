*This is a collection of Makefiles and scripts used to create all the Ethereum on ARM related packages:*

1. Clone the repository


      $ git clone https://github.com/diglos/ethereumonarm.git

2. Optional but recomended uset the provided Vagrantfile to create an Ubuntu 20.04 VM with al the needed dependences::

    More info about vagrant:
    https://www.vagrantup.com/docs/installation


      $ cd ethereumonarm/fpm-package-builder
      $ vagrant up
      $ vagrant ssh
      $ cd ethereumonarm/fpm-package-builder


3. Just tipe make to create all the deb packages


    $ make


  4. Alternatively you can simple cd into any dir and type make to create only the desired package


    $ cd geth
    $ make
