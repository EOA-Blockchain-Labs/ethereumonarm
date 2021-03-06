.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Main Features
=============

These are the main features of Ethereum on ARM images:

  * Based on Ubuntu 20.04 for ARM64
  * Automatic configuration (network, user account, etc)
  * Automatic USB disk partitioning and formatting
  * Manages and configure swap memory in order to avoid memory problems 
    (ZRAM kernel module + a swap file)
  * Automatically starts Ethereum 1.0 sync (Geth)
  * Includes all major Ethereum 1.0 and Ethereum 2.0 clients with default configuration  
  * Includes an APT repository for installing and upgrading Ethereum software
  * Includes EF eth2.0-deposit-cli tool to start staking process
  * Includes monitoring dashboards based on Grafana / Prometheus
  * Includes UFW firewall
