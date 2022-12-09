.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Node Security
=============

User account
------------

In order to run the Ethereum software the image deletes the default ubuntu user account, 
enables ssh access, and creates a system user called ``ethereum``, all these steps are done by 
our installation script. Also, on first ethereum user login, it asks the user to set a new safe password.

You can access the device using a keyboard / monitor or through SSH.

UFW
---

We included the UFW firewall with a set of policies according to the Ethereum software installed.

It is disabled by default (as usually we run the devices behind a router) but you can enable it by running:


.. prompt:: bash $

  systemctl enable ufw
  systemctl start ufw


