.. _pivpn-wireguard-intra-vpn:

################################
PiVPN and WireGuard: "Intra-VPN"
################################

.. contents::
   :local:
   :depth: 2

This guide details the steps to install and configure PiVPN with WireGuard so that VPN clients on a private network (e.g., 10.1.25.0/24) can communicate with each other while each client uses its own local internet connection. This is **not** a full-tunnel VPN setup; internet traffic will continue to use each client's local gateway. This configuration is particularly useful for accessing resources on a private network (such as shared files or internal servers) from remote locations without routing all internet traffic through the VPN.

.. warning::
   The steps in this document describe a specific PiVPN and WireGuard installation process. Your system and requirements may differ. This configuration might not be suitable for your needs. **Use at your own risk.** We strongly recommend consulting the official PiVPN and WireGuard documentation before proceeding.

---------------------------------------
Official Documentation
---------------------------------------

* **PiVPN:** https://pivpn.io/
* **WireGuard:** https://www.wireguard.com/

---------------------------------------
Prerequisites
---------------------------------------

Before proceeding, ensure you have the following:

* A Linux-based system (this guide uses Ubuntu Server 22.04 LTS, headless; other distributions may work).
* A static public IP address or a dynamic DNS service for the VPN server.
* Basic Linux command-line knowledge.
* A user account with ``sudo`` privileges.

-------------------------------------------------
Step 0: Initial Server Setup (Highly Recommended)
-------------------------------------------------

*This step is optional if you already have a server set up, but it is highly recommended for security and best practices, especially on a fresh OS install.*

1. **Create a PiVPN User:**

   .. code-block:: bash

      sudo adduser pivpn
      sudo usermod -aG sudo pivpn

2. **Log in as the New User:**  
   Log out of the root account and log in as the new user you just created. All subsequent steps should be performed as this non-root user.

3. **Configure a Basic Firewall (UFW):**

   .. code-block:: bash

      sudo apt update
      sudo apt install ufw -y
      sudo ufw default deny incoming
      sudo ufw default allow outgoing
      sudo ufw allow ssh  # Or use: sudo ufw allow 2222/tcp if you use a non-standard SSH port
      sudo ufw enable
      sudo ufw status

   *Explanation:*
   
   - **default deny incoming:** Blocks all incoming connections by default.
   - **default allow outgoing:** Allows all outgoing connections by default.
   - **allow ssh:** Permits SSH connections (adjust the port if needed).
   - **enable:** Activates the firewall.
   - **status:** Displays current firewall rules.

4. **Set the Timezone (Optional, but Recommended):**

   .. code-block:: bash

      sudo timedatectl set-timezone <Your_Timezone>

   Replace ``<Your_Timezone>`` (e.g., ``Europe/Madrid``). You can list available timezones with:

   .. code-block:: bash

      timedatectl list-timezones

---------------------------------------
Step 1: System Update
---------------------------------------

Ensure your system is up-to-date with the latest security patches and software versions:

.. code-block:: bash

   sudo apt update
   sudo apt upgrade -y
   sudo apt dist-upgrade -y  # For a more comprehensive upgrade

---------------------------------------
Step 2: Install PiVPN
---------------------------------------

Download and inspect the PiVPN installation script before running it. This adds an extra layer of security compared to piping directly from curl to bash.

.. code-block:: bash

   curl -L https://install.pivpn.io -o install_pivpn.sh
   less install_pivpn.sh  # Inspect the script (press 'q' to exit)
   sudo bash install_pivpn.sh

After you run ``sudo bash install_pivpn.sh``, the installer will prompt you with a series of questions. Here’s a brief explanation of the choices:

* **Static IP:** Confirm or set a static IP address for your server. This is essential for the VPN’s proper functioning.
* **User:** Choose the non-root user (e.g., pivpn) that will manage VPN configurations.
* **Unattended Upgrades:** Decide whether to enable automatic security upgrades. This is generally recommended.
* **VPN Protocol:** Select **WireGuard**.
* **VPN Port:** The default port is 51820 (UDP). If you change this, remember to update your firewall settings.
* **DNS Provider:** Choose a DNS provider for your VPN clients (e.g., Cloudflare with 1.1.1.1 and 1.0.0.1, Google, Quad9, etc.) or set up your own.
* **Public IP or DNS:** Enter your server’s public IP address or the hostname provided by your dynamic DNS service (e.g., ``vpn.example.com``).
* **Server Information:** Review the details displayed and confirm to proceed.

Once the installation completes, you will be prompted to reboot the server:

.. code-block:: bash

   sudo reboot

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Our Configuration Choices (Example)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1

   * - Setting
     - Value
   * - VPN Protocol
     - WireGuard
   * - Port
     - 51820 (UDP)
   * - DNS Provider
     - Cloudflare (1.1.1.1, 1.0.0.1)
   * - Hostname/Public IP
     - vpn.example.com (or your public IP)

---------------------------------------------------------------------
Step 3: Modify setupVars.conf (Critical for Intra-VPN Communication)
---------------------------------------------------------------------

Before generating client configurations, update the ``/etc/pivpn/wireguard/setupVars.conf`` file to enable communication between VPN clients and set keepalive options.

.. code-block:: bash

   sudo nano /etc/pivpn/wireguard/setupVars.conf

Locate (or add) the following lines and adjust as needed:

.. code-block:: bash

   ALLOWED_IPS="10.1.25.0/24"  # VPN network subnet; enables client-to-client communication.
   PersistentKeepalive=25      # Helps maintain connections through NATs and firewalls.

*Explanation:*

- **ALLOWED_IPS="10.1.25.0/24":**  
  Defines the IP range for VPN clients (from 10.1.25.1 to 10.1.25.254). This setting permits communication within this subnet only, ensuring that clients do not route their full internet traffic through the VPN.

- **PersistentKeepalive=25:**  
  Maintains a steady connection by sending periodic keepalive packets (especially important for devices behind NAT or firewalls).

Save the file and exit the editor (in nano, press **Ctrl+O** to save, then **Ctrl+X** to exit).

---------------------------------------
Step 4: Firewall Configuration
---------------------------------------

PiVPN may not automatically configure your firewall. **It is highly recommended to set up your firewall.** The following example uses UFW (Uncomplicated Firewall):

.. code-block:: bash

   # Allow WireGuard traffic on the chosen port
   sudo ufw allow 51820/udp

   # Permit traffic between VPN clients (essential for intra-VPN communication)
   sudo ufw allow in from 10.1.25.0/24 to 10.1.25.0/24
   sudo ufw route allow in on wg0 out on wg0

   sudo ufw status  # Verify the rules

.. warning::
   Review and adjust the firewall rules according to your security requirements. The rule ``allow in from 10.1.25.0/24 to 10.1.25.0/24`` enables all traffic between devices in the VPN subnet. If you need granular control, specify more detailed rules. The command ``ufw route allow in on wg0 out on wg0`` is necessary to permit forwarded traffic between VPN clients.

---------------------------------------
Step 5: Generate Client Configurations
---------------------------------------

For each client you want to add, run the following command:

.. code-block:: bash

   pivpn -a  # Add a new client

Follow the on-screen prompts to create a configuration file for each client. We recommend using descriptive names (e.g., ``laptop.conf``, ``phone.conf``). These files will be stored in ``/home/pivpn/configs/``.

-------------------------------------------
Step 6: Client Configuration and Activation
-------------------------------------------
1. **Install a WireGuard Client:**  
   Visit https://www.wireguard.com/install/ to download the official client for your operating system.

2. **Import the Client Configuration:**  
   Securely transfer the client configuration file (e.g., ``client1.conf``) to your device using secure methods such as ``scp`` or ``sftp``. **Avoid unencrypted methods (e.g., email or FTP).**

   Example using ``scp`` (run from your local machine):

   .. code-block:: bash

      scp pivpn@<your_server_ip>:/home/pivpn/configs/client1.conf /path/to/local/destination/

   Replace ``<your_server_ip>`` and ``/path/to/local/destination/`` with the appropriate values.

3. **Review the Client Configuration File:**  
   A typical client configuration file for WireGuard might look like this:

   .. code-block::

      [Interface]
      PrivateKey = <Client Private Key>
      Address = 10.1.25.X/32  # The client's assigned IP address (e.g., 10.1.25.2)
      DNS = 1.1.1.1, 1.0.0.1  # DNS servers for the VPN session

      [Peer]
      PublicKey = <Server Public Key>
      PresharedKey = <Preshared Key>  # If configured during setup
      AllowedIPs = 10.1.25.0/24       # Enables communication within the VPN subnet ONLY
      Endpoint = vpn.example.com:51820  # VPN server's address and port
      PersistentKeepalive = 25

   .. important::
      Replace all placeholders (e.g., ``<Client Private Key>``, ``<Server Public Key>``) with your actual configuration values. Notice that setting ``AllowedIPs`` to ``10.1.25.0/24`` allows only intra-VPN communication, ensuring that internet traffic uses the client’s local connection.

4. **Activate the Connection (for Linux-based Clients):**  
   You can manage the WireGuard interface with systemd and wg-quick:

   a. **Save the Configuration:**  
      Place your client configuration file in the ``/etc/wireguard/`` directory. For example, save it as ``/etc/wireguard/eoa.conf`` (if your interface is named "eoa").

   b. **Enable the WireGuard Service:**  
      To have the interface start automatically at boot, run:

      .. code-block:: bash

         sudo systemctl enable wg-quick@eoa.service

      This command creates a symlink for the "eoa" interface, enabling automatic startup.

   c. **Bring Up the Interface Manually:**  
      To manually start the interface, use:

      .. code-block:: bash

         wg-quick up eoa

      You can verify the status of your WireGuard interface with:

      .. code-block:: bash

         wg show eoa

   Adjust the interface name (``eoa``) as needed if your configuration file uses a different name.

---------------------------------------
Step 7: Verify the Connection
---------------------------------------

* **On the Server:**  
  Verify active connections by running:

  .. code-block:: bash

     sudo pivpn -c

* **On the Client:**  
  - **Ping Test:** Ping another client's VPN IP address (e.g., ``ping 10.1.25.5``) to ensure intra-VPN connectivity.
  - **Internet Test:** Open a web browser and navigate to a website (e.g., google.com) to confirm that internet traffic is not routed through the VPN.

---------------------------------------
Troubleshooting
---------------------------------------

Below are some common issues and suggested solutions:

* **Issue: VPN Client Cannot Connect**
  - **Check:** Verify that the WireGuard service is running on the server.
  - **Solution:** Run ``sudo systemctl status wg-quick@wg0`` and restart with ``sudo systemctl restart wg-quick@wg0`` if needed.

* **Issue: No Internet Access on the Client**
  - **Check:** Ensure that the client’s configuration file does not set a default route through the VPN.
  - **Solution:** Confirm that ``AllowedIPs`` is set to ``10.1.25.0/24`` rather than ``0.0.0.0/0``.

* **Issue: Firewall Blocking Connections**
  - **Check:** Confirm that UFW or your preferred firewall is configured to allow traffic on the WireGuard port and between VPN clients.
  - **Solution:** Revisit Step 4 and adjust the rules accordingly.

* **Issue: DNS Resolution Issues on the Client**
  - **Check:** Ensure that the DNS settings in the client configuration are correct.
  - **Solution:** Test with alternative DNS providers or verify that the chosen DNS servers are reachable.

* **Issue: PersistentKeepalive Settings Not Maintaining Connection**
  - **Check:** Verify that the keepalive setting (e.g., 25 seconds) is correctly configured on both the server (in ``setupVars.conf``) and client configurations.
  - **Solution:** Adjust the keepalive interval if network conditions require a different value.

If issues persist, consult the official PiVPN and WireGuard documentation or seek assistance from community forums.