.. _pivpn-wireguard-intra-vpn:

#######################################################################################################################
PiVPN and WireGuard: Enabling Intra-VPN Communication without Full Tunneling (Our Configuration - Use at Your Own Risk)
#######################################################################################################################

This guide details the steps we took to install and configure PiVPN with WireGuard to allow communication *between* VPN clients on a private network (10.1.25.0/24 in our example) while still allowing each client to use its own direct internet connection. This is *not* a full-tunnel VPN setup. Clients will access the internet through their *local* gateway, *not* the VPN server. This is useful for accessing resources on a private network (e.g., shared files, internal servers) from remote locations without routing all internet traffic through the VPN. The diagram below illustrates the network topology this guide describes.


.. warning::

   This document describes *our* specific PiVPN and WireGuard installation process. It is provided for informational purposes only. Your system and requirements may differ, and this configuration may not be suitable for your needs. We make no guarantees about its effectiveness or security. Use this guide at your own risk. We strongly recommend consulting the official PiVPN and WireGuard documentation before proceeding.

.. _official-documentation:

Official Documentation
----------------------

*   PiVPN: https://pivpn.io/
*   WireGuard: https://www.wireguard.com/

.. _prerequisites:

Prerequisites
-------------

*   A Linux-based system (we used Ubuntu Server 22.04 LTS (headless), but other distributions may work).  *At least 1GB of RAM and 10GB of disk space are recommended for the server OS.*
*   A static public IP address or a dynamic DNS service *for the VPN server* (if you want to access your VPN from outside your local network).
*   Basic Linux command-line knowledge.
*   A user account with ``sudo`` privileges.

.. _installation-steps:

Installation Steps
------------------

.. _step-0-initial-server-setup:

**Step 0: Initial Server Setup (Highly Recommended)**

This step is *optional* if you already have a server set up, but it's highly recommended for security and best practices, especially on a fresh OS install:

1.  **Create a PiVPN User:**

    .. code-block:: bash

        sudo adduser pivpn
        sudo usermod -aG sudo pivpn


2.  **Log in as the New User:**  Log out of the root account and log in as the new user you just created.  All subsequent steps should be performed as this non-root user.

3.  **Configure SSH Key-Based Authentication (Recommended):**

    *   **On your local machine (not the server):** Generate an SSH key pair if you don't already have one:

        .. code-block:: bash

            ssh-keygen -t ed25519  # Or -t rsa -b 4096 if ed25519 is not supported

        Follow the prompts.  You can optionally set a passphrase for added security.

    *   **Copy the Public Key to the Server:**

        .. code-block:: bash

            ssh-copy-id pivpn@<your_server_ip>

        Replace ``pivpn`` and ``<your_server_ip>`` with the correct values. You'll be prompted for the user's password on the server.

    *   **Test SSH Key Authentication:**  Try logging in again using ``ssh pivpn@<your_server_ip>``.  You should be logged in without being prompted for a password (unless you set a passphrase for the key).

    *   **Disable Password Authentication (Highly Recommended):**

        .. code-block:: bash

            sudo nano /etc/ssh/sshd_config

        Find the following lines and change them:

        .. code-block::

            PasswordAuthentication no
            ChallengeResponseAuthentication no

        Save the file and restart the SSH service:

        .. code-block:: bash

            sudo systemctl restart sshd

4.  **Configure a Basic Firewall (UFW):**

    .. code-block:: bash

        sudo apt update
        sudo apt install ufw -y
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw allow ssh  # Or sudo ufw allow 2222/tcp if you use a non-standard SSH port
        sudo ufw enable
        sudo ufw status

    *   **Explanation:**

        *   ``default deny incoming``: Blocks all incoming connections by default.
        *   ``default allow outgoing``: Allows all outgoing connections by default.
        *   ``allow ssh``:  Allows SSH connections (adjust the port if necessary).
        *   ``enable``: Enables the firewall.
        *   ``status``:  Shows the current firewall rules.

5.  **Set the Timezone (Optional, but Recommended):**

    .. code-block:: bash

        sudo timedatectl set-timezone <Your_Timezone>

    Replace ``<Your_Timezone>`` with your desired timezone (e.g., ``America/Los_Angeles``).  You can find a list of timezones with ``timedatectl list-timezones``.


.. _step-1-system-update:

**Step 1: System Update**

Ensure your system is up-to-date to have the latest security patches and software versions.

.. code-block:: bash

    sudo apt update
    sudo apt upgrade -y
    sudo apt dist-upgrade -y  # For more comprehensive upgrades

.. _step-2-install-pivpn:

**Step 2: Install PiVPN**

We will download and inspect the PiVPN installation script before running it. This is a safer approach than piping directly from ``curl`` to ``bash``.

.. code-block:: bash

    curl -L https://install.pivpn.io -o install_pivpn.sh
    less install_pivpn.sh  # Inspect the script (use 'q' to exit)
    sudo bash install_pivpn.sh

Follow the on-screen prompts during the PiVPN installation. These prompts will guide you through the initial configuration. Here's a breakdown of what each prompt is asking for:

*   **Static IP:**  The installer will ask you to confirm or set a static IP address for your server.  This is important for the VPN to function correctly.

*   **User:**  You'll likely be asked to choose a user to hold the VPN configurations.  This should be the non-root user you created in Step 0.

*   **Unattended Upgrades:** The installer will ask if you want to enable unattended upgrades. It is generally recommended for security.

*   **VPN Protocol:**  Choose **WireGuard**.

*   **VPN Port:**  The default port is 51820 (UDP). You can change it if you want, but remember to adjust your firewall rules accordingly. (We used 51820).

*   **DNS Provider:** Select a DNS provider.  This is what your VPN clients will use to resolve domain names.  We used Cloudflare DNS (1.1.1.1 and 1.0.0.1), but you can choose others (Google, Quad9, OpenDNS, etc.) or even set up your own recursive DNS server.

*   **Public IP or DNS:** Enter your server's public IP address or the hostname you've configured with a dynamic DNS service (e.g., ``vpn.example.com``).

*   **Server Information:** Review the information displayed and confirm to proceed.

*   **Reboot:** After installation, it's a good idea to reboot:

    .. code-block:: bash

        sudo reboot

**Our Configuration Choices (Example - Adapt to your needs):**

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

.. _step-3-modify-setupvars-conf:

**Step 3: Modify setupVars.conf (Important for Intra-VPN Communication and Keepalive):**

After PiVPN is installed but *before* generating client configurations, adjust the ``/etc/pivpn/wireguard/setupVars.conf`` file. This is **critical** for enabling communication *between* VPN clients while preventing full tunnel routing.

.. code-block:: bash

    sudo nano /etc/pivpn/wireguard/setupVars.conf

Find and modify (or add) the following lines (adjust to your network):

.. code-block:: bash

    ALLOWED_IPS="10.1.25.0/24"  # This is your VPN network's subnet
    PersistentKeepalive=25      # Set the persistent keepalive value (important for maintaining connections)

*   **``ALLOWED_IPS="10.1.25.0/24"``:** This setting is **critical** for enabling communication *between* VPN clients while preventing full tunnel routing.  ``10.1.25.0/24`` defines the range of IP addresses available for your VPN clients (in this case, 254 usable addresses from 10.1.25.1 to 10.1.25.254).  The ``/24`` is CIDR notation representing the subnet mask (255.255.255.0).
*   **``PersistentKeepalive=25``:** This setting helps maintain stable connections, especially through NATs and firewalls.

Save the file and exit the editor (Ctrl+O, Enter, Ctrl+X in nano).

.. _step-4-firewall-configuration:

**Step 4: Firewall Configuration (Important\!):**

PiVPN might not automatically configure your firewall. **We strongly recommend enabling and configuring a firewall.** We will use UFW (Uncomplicated Firewall).

.. code-block:: bash

    # Allow WireGuard traffic on the chosen port
    sudo ufw allow 51820/udp

    # Allow traffic between VPN clients (important for intra-VPN communication)
    sudo ufw allow in from 10.1.25.0/24 to 10.1.25.0/24
    sudo ufw route allow in on wg0 out on wg0

    sudo ufw status  # Verify the firewall rules

.. warning::

   Carefully review and adjust the firewall rules to meet your security requirements. Opening ports can expose your server to security risks. The ``allow in from 10.1.25.0/24 to 10.1.25.0/24`` rule allows all traffic between devices within your VPN's IP range. If you need more granular control, you can define more specific rules.  The ``ufw route allow in on wg0 out on wg0`` command allows *forwarded* traffic (traffic passing *through* the server), which is essential for the VPN clients to communicate with each other.

.. _step-5-generate-client-configurations:

**Step 5: Generate Client Configurations:**

Run the following command *for each client* you want to add:

.. code-block:: bash

    pivpn -a  # Add a new client

Follow the prompts to create a configuration file for each client.  It's recommended to use descriptive names (e.g., ``laptop.conf``, ``phone.conf``). These files will be saved in ``/home/pivpn/configs/``.  (Remember, ``pivpn`` is the non-root user you created in Step 0.)

.. _step-6-transfer-client-configurations:

**Step 6: Transfer Client Configurations:**

Securely transfer the client configuration files (e.g., ``client1.conf``) to your client devices.  You can use ``scp``, ``sftp``, or other secure methods.  **Do not use unencrypted methods like email or FTP.**

Example ``scp`` command (run from your *local* machine):

.. code-block:: bash

    scp pivpn@<your_server_ip>:/home/pivpn/configs/client1.conf /path/to/local/destination/

Replace ``<your_server_ip>``, and ``/path/to/local/destination/`` with the correct values.

.. _step-7-client-configuration:

**Step 7: Client Configuration (Example - Adapt to your needs):**

A typical client configuration file will look like this:

.. code-block::

    [Interface]
    PrivateKey = <Client Private Key>
    Address = 10.1.25.X/32  # Client's IP address (assigned by PiVPN - the .X will be a specific number)
    DNS = 1.1.1.1, 1.0.0.1  # DNS servers

    [Peer]
    PublicKey = <Server Public Key>
    PresharedKey = <Preshared Key> # If configured during setup
    AllowedIPs = 10.1.25.0/24       # Allow communication within the VPN subnet ONLY; no full tunnel
    Endpoint = vpn.example.com:51820  # Your VPN server's address and port
    PersistentKeepalive = 25

.. important::

   Replace the placeholders with the actual values from your server and client configurations. The crucial change here is setting ``AllowedIPs`` to ``10.1.25.0/24``. This allows clients to communicate with each other on the VPN network, but *does not* route their internet traffic through the VPN. They'll use their local internet connection.  The ``Address`` will be automatically assigned by PiVPN (e.g., 10.1.25.2/32, 10.1.25.3/32, etc.). The ``/32`` indicates a single IP address.  The client DNS settings will override the client's default DNS settings *only while connected to the VPN*.

.. _step-8-connect-client:

**Step 8: Connect Client:**

Install a WireGuard client on your device (e.g., the official WireGuard app for your operating system). Download the official WireGuard app for your operating system from https://www.wireguard.com/install/. Import the client configuration file and activate the connection.

.. _step-9-verify-connection:

**Step 9: Verify Connection:**

*   **On the server:**

    .. code-block:: bash

        sudo wg show wg0

    This shows active connections and information about the ``wg0`` interface.

*   **On the client:**

    *   **Ping Test:** Try pinging another client's VPN IP address:  ``ping 10.1.25.5`` (replace ``10.1.25.5`` with the actual IP address of another client).
    *   **Internet Access Test:** Open a web browser and visit a website like google.com.  This verifies that you have internet access through your normal connection, *not* the VPN.