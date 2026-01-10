.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Operation Guide
===============

This User Guide explains in detail how to run an Ethereum node and manage it through Systemd services. You will find here:

  * How to manage the Ethereum client Systemd services and other common tasks
  * What is an Ethereum node and what types nodes are there
  * Detailed info about the Execution Layer clients and how to run them
  * Detailed info about the Consensus Layer clients and how to run them
  * Detailed info about how to set up a Validator (Staking)
  * How to run an Ethereum L2 node
  * How to run and configure Web 3 clients

.. warning::

  You need to run both clients (Execution client + Consensus client) at the same time. You can choose 
  any EL+CL combination (we recommend running minority clients) but once started you need to keep them running 
  together (for instance: Geth + Lighthouse).