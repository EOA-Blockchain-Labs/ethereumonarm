.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

About user guide
================

This User Guide explains in detail how to run an Ethereum node **post-merge** (both Execution Layer and Consensus Layer clients) and 
to manage them through Systemd services. You will find here:

  * How to manage the Ethereum client Systemd services and other common tasks
  * What is an Ethereum node and what types nodes are there
  * Detailed info about the Execution Layer clients (formerly known as Ethereum 1.0 clients) and how to run them
  * Detailed info about the Consensus Layer clients (formerly known as Ethereum 2.0 clients) and how to run them
  * Detailed info about how to set up a Validator (Staking)
  * How to run an Ethereum L2 node
  * How to run and configure Web 3 clients

.. warning::

  You need to run along both clients (Execution client+Consensus client) at the same time. You can choose 
  any EL+CL combination (we recommend to run minority clients) but once started you need to keep them running 
  one by one (for instance: Geth+Lighthouse)

More info about **The Merge**

`launchpad.ethereum.org/en/merge-readiness`_

.. _launchpad.ethereum.org/en/merge-readiness: https://launchpad.ethereum.org/en/merge-readiness