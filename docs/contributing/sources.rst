.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Sources
=======

The Ethereum on ARM project is fully open source. You can access the complete source 
code, contribute, and report issues on our GitHub repository:

`EOA-Blockchain-Labs/ethereumonarm <https://github.com/EOA-Blockchain-Labs/ethereumonarm>`_

Repository Structure
--------------------

The repository contains the following main components:

**docs/**
  The source files for this documentation, built with Sphinx and hosted on 
  Read the Docs. Contributions to improve the documentation are welcome.

**fpm-package-builder/**
  A comprehensive package builder that creates Debian packages for all Ethereum 
  clients (execution, consensus, and Layer 2) as well as related tools and utilities. 
  This includes build scripts, configuration files, and systemd service definitions.

**image-creation-tool/**
  Contains the installation script and image builder used to create the 
  Ethereum on ARM disk images for supported hardware platforms.

Contributing
------------

We welcome contributions! Please see the :doc:`/contributing/guidelines` section 
for guidelines on how to get involved.

.. seealso::
   
   For detailed technical information about the project architecture and development 
   workflow, refer to the :doc:`/contributing/building-images` section.
