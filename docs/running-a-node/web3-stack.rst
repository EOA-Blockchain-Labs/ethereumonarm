Running web3 stack
==================

.. meta::
   :description lang=en: Web3 decentralized storage on ARM. Run IPFS Kubo and Swarm Bee nodes on Rock 5B and NanoPC T6 for distributed file storage.
   :keywords: IPFS ARM, Swarm Bee node, decentralized storage, Kubo IPFS, Web3 infrastructure

The Web3 refers to the set of technologies, protocols, and tools designed 
to build decentralized applications (dApps) and create a more **decentralized, 
user-centric internet.**

The Web3 stack is often associated with blockchain, but it includes other peer-to-peer (P2P) 
technologies and protocols as well such us **IPFS, Swarm, and Status.**

Ethereum on ARM includes all clients needed to run IPFS, Swarm and Status nodes.

.. note::
  If you have an Ethereum on ARM image installed prior to May 2023 you need to install the clients manually. Otherwise 
  you can skip this step:

.. prompt:: bash $

  sudo apt-get update
  sudo apt-get install kubo statusd bee

IPFS
----

IPFS (InterPlanetary File System) is a **distributed, peer-to-peer file storage and sharing 
system** designed to replace the traditional, centralized model of the internet. IPFS uses 
content-addressed storage, which means that files are stored and retrieved based on their 
cryptographic hash rather than their location on a specific server. 

This approach enables efficient and resilient file distribution, as multiple nodes can 
store and serve the same content, making it less prone to censorship and single points of 
failure. IPFS is an essential part of the Web3 stack as it provides a decentralized way to store 
and access data, complementing blockchain-based dApps.

The IPFS go implementation is called :guilabel:`Kubo`. In order to run an IPFS node you just need to 
start the Systemd Service

.. prompt:: bash $

  sudo systemctl start ipfs
  sudo journalctl -u ipfs -f 


Swarm
-----

Swarm is a **decentralized storage system** primarily associated
with the Ethereum ecosystem. Similar to IPFS, Swarm is a peer-to-peer network that allows 
users to store and share data in a distributed manner. Swarm's focus is on providing scalable 
and efficient data storage for dApps built on Ethereum. Swarm's integration 
with Ethereum makes it an important part of the Web3 stack, particularly for Ethereum-based dApps.

The Swarm implementation is :guilabel:`Bee`. In order to run a node you just need to start the Systemd Service:

.. prompt:: bash $

  sudo systemctl start bee
  sudo journalctl -u bee -f 

Status
------

Status is a **decentralized messaging platform, wallet, and dApp browser built on 
top of the Ethereum blockchain**. It aims to provide users with a unified interface to interact 
with the decentralized web (Web3) by enabling secure messaging, asset management, and access to 
various dApps. Status uses the Whisper protocol, a decentralized messaging system that is part of 
the Ethereum stack, to facilitate secure and private communication between users.

By integrating with Ethereum and providing a user-friendly interface for interacting with 
the decentralized web, Status serves as an essential tool in the Web3 stack.

The Status implementation is called :guilabel:`Status Go`. In order to run an Status node you 
just need to start the Systemd Service:

.. prompt:: bash $

  sudo systemctl start statusd
  sudo journalctl -u statusd -f 