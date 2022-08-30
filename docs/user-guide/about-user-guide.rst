.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

About user guide
================

This User Guide explains in detail how to run an Ethereum node **post-merge** (both Execution Layer and Consensus Layer clients) and 
to manage them through Systemd services. You will find here:

  * How to manage the Ethereum client Systemd services and other common tasks
  * Detailed info about the Execution Layer clients (formerly known as Ethereum 1.0 clients) and how to run them
  * Detailed info about the Consensus Layer clients (formerly known as Ethereum 2.0 clients) and how to run them
  * How to run and configure other Ethereum related software

.. warning::

  You need to run along both clients (Execution client+Consensus client) at the same time. You can choose 
  any EL+CL combination (we recommend to run minority clients) but once started you need to keep them runnning 
  one by one (for instance, Geth+Lighthouse)

More info about **The Merge**

`launchpad.ethereum.org/en/merge-readiness`_

.. _launchpad.ethereum.org/en/merge-readiness: https://launchpad.ethereum.org/en/merge-readiness