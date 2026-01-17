dvt-anchor for Debian
---------------------

Anchor is an SSV client implementation by Sigma Prime.

Service Configuration
---------------------
The service is configured via:
  /etc/ethereum/anchor.conf

Service Management
------------------
  sudo systemctl start anchor
  sudo systemctl stop anchor
  sudo systemctl restart anchor
  sudo systemctl status anchor

Logs
----
  journalctl -u anchor -f

Data Directory
--------------
  /home/ethereum/.anchor

 -- Ethereum on ARM <info@ethereumonarm.com>  Fri, 17 Jan 2026 12:00:00 +0000
