Running an Optimism Supernode on Rock 5B (32GB) or Orange Pi 5 Plus
=======================================================================

This guide details how to set up an Optimism "Supernode" on a Rock 5B (32GB model) or an Orange Pi 5 Plus.  A Supernode runs both a Layer 1 (L1) Ethereum node and a Layer 2 (L2) Optimism node on the same hardware.  This allows you to participate in both the Ethereum mainnet and the Optimism network simultaneously.

.. warning::

   **32GB RAM Requirement:**  Running a Supernode requires a board with **32GB of RAM**.  This guide specifically applies to the **Rock 5B (32GB model)** and the **Orange Pi 5 Plus (32GB model)**.  Do *not* attempt this on devices with less RAM.

.. contents:: :local:
    :depth: 2

Hardware Requirements
---------------------

Before you begin, ensure you have the following hardware:

*   **Rock 5B (32GB RAM model)**  OR  **Orange Pi 5 Plus (32GB RAM model)**
 
    *   **Rock 5B Buy Links:**
        *   `Rock 5B board 32 GB <https://shop.allnetchina.cn/products/rock5-model-b?variant=43726698709295>`_  (Note: Select the 32GB variant)
        *   `Radxa power supply <https://shop.allnetchina.cn/products/radxa-power-pd-30w?variant=39929851904102>`_
    *   **Orange Pi 5 Plus Buy Links:**
        *   `Orange Pi 5 Plus 32 GB RAM <http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-5-plus-32GB.html>`_ (Check the official site for authorized distributors in your region)
        *   Orange Pi 5 Plus often comes in kits that include a power supply.

*   **MicroSD Card:**  16GB minimum, Class 10 recommended.  This will hold the operating system.

*   **NVMe SSD:** 4TB recommended (2TB *absolute minimum*). This will store the blockchain data for both L1 and L2.  *Crucially, avoid NVMe drives with Phison controllers*.  Choose a Mid-Range or High-End drive.
    *   **Recommended 4TB NVMe SSDs (High-End):**
 
        *   **Western Digital SN850X 4TB:**  A very popular and reliable high-performance drive.
        *   **Samsung 990 PRO 4TB:** Another top-tier option with excellent performance and endurance.
        *   **SK Hynix Platinum P41 4TB:** Known for its excellent performance and power efficiency.
        *  **Crucial P3 Plus 4TB** Mid-range and reliable
 
    *   *Check these resources for more options and compatibility information:*
        *   `SSD list <https://docs.google.com/spreadsheets/d/1B27_j9NDPU3cNlj2HKcrfpJKHkOf-Oi1DbuuQva2gT4/edit>`_
        *   `Great and less great SSDs for Ethereum nodes <https://gist.github.com/yorickdowne/f3a3e79a573bf35767cd002cc977b038>`_

*   **Power Supply:** Use the official power supply for your chosen board (Radxa power supply for Rock 5B, or a compatible power supply from the Orange Pi 5 Plus kit).

*   **Ethernet Cable:**  A wired network connection is essential for node stability and performance.

*   **Case with Heatsink:**  Proper cooling is critical for these powerful boards, especially when running 24/7.  Use a case with a good heatsink (and potentially a fan, depending on ambient temperature).
 
    *   **Rock 5B Case Buy Links:**
        *   `Acrylic protector with passive heatsink <https://shop.allnetchina.cn/products/rock5-b-acrylic-protector?variant=39877626396774>`_
        *   `Aluminum case with passive/active cooling <https://shop.allnetchina.cn/collections/rock5-model-b/products/ecopi-5b-aluminum-housing-for-rock5-model-b?variant=47101353361724>`_
    * **Orange Pi 5 Plus case with heatsink Buy links:**
        *  `Orange Pi 5 Plus Case with heatsink <https://aliexpress.com/item/1005005728553439.html>`_

*   **(Optional) USB Keyboard, Monitor, and HDMI Cable:** Useful for initial setup and troubleshooting, but not required for headless operation after setup.

Software Prerequisites
----------------------

1.  **Flash the Ethereum on ARM Image:** Download the appropriate image for your board (Rock 5B or Orange Pi 5 Plus) from the links provided in the original "Images download" section.  Verify the SHA256 checksum after downloading.  Then, flash the image to your MicroSD card using a tool like Etcher (recommended for ease of use) or the `dd` command (as described in the original "Image installation" section).

2.  **Boot the Board:** Insert the MicroSD card, connect the NVMe SSD, connect the Ethernet cable, and power on the board.  The initial boot and setup script will take 10-15 minutes.

3.  **Log In and Change Password:** After the initial setup, log in via SSH (using the board's IP address and the default username/password: `ethereum`/`ethereum`) or directly using a monitor and keyboard.  You will be prompted to change the default password immediately.

Step 1: Setting up the Layer 1 (Ethereum) Node
-----------------------------------------------

The first step is to establish a fully synchronized L1 Ethereum node. This is the foundation for your Optimism Supernode.

1.  **Choose your L1 Clients:** Select a combination of an Execution Layer (EL) client and a Consensus Layer (CL) client.  The original documentation provides details on various supported clients (Geth, Nethermind, Erigon, Besu for EL; Lighthouse, Prysm, Nimbus, Teku, Lodestar, Grandine for CL).  For this example, we'll use Geth (EL) and Prysm (CL), but you can choose others.

2.  **Start the Consensus Layer (CL) Client:**  The Consensus Layer client (specifically, the Beacon Chain component) *must* be synchronized before you start the Execution Layer client.  Thanks to Checkpoint Sync, this should be relatively quick.

    .. prompt:: bash $

        sudo systemctl start prysm-beacon

3.  **Monitor the Beacon Chain Sync:** Use `journalctl` to monitor the progress:

    .. prompt:: bash $

        sudo journalctl -fu prysm-beacon

    Look for logs indicating that the Beacon Chain is synchronized. It should mention being "synced" or "in sync".  Checkpoint Sync usually completes within minutes.

4.  **Start the Execution Layer (EL) Client:** Once the Beacon Chain is synchronized, start the Execution Layer client (Geth in this example):

    .. prompt:: bash $

        sudo systemctl start geth

5.  **Monitor the EL Client Sync:**  Monitor the Geth sync process:

    .. prompt:: bash $

        sudo journalctl -fu geth

    This will take significantly longer than the Beacon Chain sync.  Geth will go through several phases, including downloading headers, downloading block bodies, and processing the state.  *It's highly recommended to wait until Geth is fully synchronized before proceeding to the L2 setup.* You can tell Geth is fully synced once it begins regularly importing new blocks at the chain head. You will see "Imported new block headers" messages frequently.

    .. note::
      The original documentation recommends waiting for the Execution Client to finish the "snapshot creation phase".  This is a resource-intensive process.  Monitor the logs, and once you see messages like "Imported new block headers" consistently, it's safe to proceed.

Step 2: Setting up the Layer 2 (Optimism) Node
-----------------------------------------------

Once your L1 node is fully synchronized, you can set up the Optimism (L2) node.

1.  **Configure `op-node`:**  The `op-node` needs to know where to find the L1 node.  Since both L1 and L2 are running on the same machine, we'll use `localhost`.

    .. prompt:: bash $

        sudo sed -i 's/l1ip/localhost/' /etc/ethereum/op-node.conf
        sudo sed -i 's/l1beaconip/localhost/' /etc/ethereum/op-node.conf

2.  **Start `op-geth`:** This is the Optimism-specific version of Geth.

    .. prompt:: bash $

        sudo systemctl start op-geth
    
3. **Port Forwarding for `op-geth`:** `op-geth` uses snap sync, so you need open the port 31303.

4.  **Start `op-node`:** This is the core Optimism node software.

    .. prompt:: bash $

        sudo systemctl start op-node

5.  **Monitor the L2 Sync:**  Monitor the progress of both `op-geth` and `op-node`:

    .. prompt:: bash $

        sudo journalctl -fu op-geth
        sudo journalctl -fu op-node

    The Optimism sync process (using snap sync) will take time (the documentation estimates 10-15 hours).

Step 3: Configure UFW (Firewall) - Optional but Recommended
------------------------------------------------------------

While often running behind a router (which provides some firewall protection), enabling UFW (Uncomplicated Firewall) on the node itself adds an extra layer of security.

1.  **Enable SSH Access:**  Allow SSH connections (so you can still access your node remotely):

    .. prompt:: bash $

        sudo ufw allow ssh

2.  **Allow Ethereum L1 Ports:** Allow the necessary ports for your chosen L1 clients.  For Geth and Prysm (our example):

    .. prompt:: bash $

        sudo ufw allow 30303/tcp  # Geth (Execution Layer)
        sudo ufw allow 30303/udp  # Geth (Execution Layer)
        sudo ufw allow 13000/tcp  # Prysm (Consensus Layer - Beacon Chain)
        sudo ufw allow 12000/udp  # Prysm (Consensus Layer - Beacon Chain)

3.  **Allow Optimism L2 Ports:**

    .. prompt:: bash $

        sudo ufw allow 31303/tcp # op-geth
        sudo ufw allow 31303/udp # op-geth

    *(op-node uses the L1 connection, so no additional ports are needed)*

4. **Enable UFW**

    .. prompt:: bash $
     
        sudo ufw enable

    You will see a message indicating the firewall is active

5. **Check UFW Status:** Verify the rules:

    .. prompt:: bash $

        sudo ufw status

.. note::
    If you're running behind a router, you also need to configure port forwarding on your *router* to forward the same ports (30303 TCP/UDP, 13000 TCP, 12000 UDP, and 31303 TCP/UDP) to your node's internal IP address.  Consult your router's documentation for instructions on how to do this.  UFW manages the firewall *on the node itself*, while port forwarding on the router directs incoming traffic from the internet to your node.  You generally need *both* for external peers to connect.

Step 4: Verification and Maintenance
------------------------------------

*   **Check Synchronization:**  Regularly monitor the logs of all four services (`prysm-beacon`, `geth`, `op-geth`, `op-node`) to ensure they remain synchronized.

*   **System Updates:** Keep your system up-to-date:

    .. prompt:: bash $

        sudo apt update
        sudo apt upgrade

*   **Resource Monitoring:**  Use tools like `htop`, `top`, or `iotop` to monitor CPU, RAM, and disk I/O usage.  A Supernode is resource-intensive, so keep an eye on these metrics.

*   **Restarting Services:** If you need to restart any of the services, use `sudo systemctl restart <service-name>`. For example:

  .. prompt:: bash $

        sudo systemctl restart geth

Troubleshooting
---------------

*   **Sync Issues:** If any of the clients fall out of sync, check the logs for error messages.  Network connectivity problems are a common cause.  You may need to restart the affected service(s).

*   **Disk Space:** Running out of disk space on the NVMe SSD will cause the node to fail. Monitor disk usage and consider a larger SSD if necessary.

*   **Overheating:** Ensure adequate cooling.  If the board is overheating, the CPU may throttle, slowing down the sync process or causing instability.

* **Phison Controller NVMe drive**: The node may experience issues. Check the compatibility list and change the drive.

This detailed guide provides a comprehensive walkthrough for setting up an Optimism Supernode on a Rock 5B (32GB) or Orange Pi 5 Plus.  Remember to carefully follow each step and monitor the system's performance.  Running a Supernode requires a good understanding of Ethereum and Optimism, so be prepared to troubleshoot any issues that may arise.



