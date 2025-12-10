Running an Optimism Supernode
=============================

This comprehensive guide will walk you through setting up an Optimism "Supernode" on a Rock 5B (32GB model) or an Orange Pi 5 Plus (32GB model).  A Supernode is a powerful setup that simultaneously runs both a Layer 1 (L1) Ethereum node and a Layer 2 (L2) Optimism node on the same hardware. This allows you to fully participate in both the Ethereum mainnet and the Optimism network, contributing to network health and potentially accessing advanced features.

**Why run a Supernode?**

*   **Full Network Participation:**  Connect directly to both Ethereum and Optimism networks without relying on centralized intermediaries.
*   **Enhanced Security & Privacy:**  Increased control over your node and data compared to using third-party node providers.
*   **Support Decentralization:** Contribute to the robustness and decentralization of both networks.
*   **Advanced Functionality (Potential Future Use Cases):**  Running your own Supernode may unlock advanced features and capabilities in the future within the Optimism ecosystem.

.. warning::

   **CRITICAL 32GB RAM REQUIREMENT:**  Running a Supernode is resource-intensive.  **You MUST use a board with 32GB of RAM**. This guide is specifically for the **Rock 5B (32GB model)** and the **Orange Pi 5 Plus (32GB model)**.  **Attempting this on devices with less than 32GB of RAM will likely lead to failure, instability, and a frustrating experience.** Do *not* proceed if your hardware does not meet this requirement.

**Glossary of Terms:**

*   **L1 (Layer 1):**  In this context, refers to the Ethereum mainnet blockchain.
*   **L2 (Layer 2):** Refers to the Optimism blockchain, a scaling solution built on top of Ethereum.
*   **Supernode:** A node running both an L1 and L2 node simultaneously on the same hardware.
*   **Execution Layer (EL):** The part of an Ethereum node that executes transactions and manages the state (e.g., Geth, Nethermind, Erigon, Besu).
*   **Consensus Layer (CL):** The part of an Ethereum node that handles consensus and block validation (e.g., Lighthouse, Prysm, Nimbus, Teku, Lodestar, Grandine). Also known as the Beacon Chain.
*   **Checkpoint Sync:** A fast synchronization method for the Consensus Layer, allowing quick initial sync by downloading a recent state checkpoint.
*   **Snap Sync:** A synchronization method used by Optimism Geth (`op-geth`) for faster initial synchronization of the L2 chain.
*   **op-node:** The core software component of an Optimism node, responsible for interacting with the L1 Ethereum node and managing the L2 chain state.
*   **op-geth:** A modified version of Geth specifically for the Optimism network.

.. contents:: :local:
    :depth: 2

Pre-Installation Checklist
--------------------------

Before you begin, ensure you have gathered all the necessary hardware and completed the preliminary steps:

-   [ ] **Hardware Assembled:** Rock 5B or Orange Pi 5 Plus (32GB), NVMe SSD, MicroSD Card, Power Supply, Ethernet Cable, Case with Heatsink are physically assembled.
-   [ ] **Buy Links Ready:** Keep the buy links for your hardware handy in case you need to re-order or check specifications.
-   [ ] **Download Links Saved:** You have saved the download links for the Ethereum on ARM images for your chosen board.
-   [ ] **Checksum Verification Tools Installed:** You have tools installed on your computer to verify SHA256 checksums (e.g., ``sha256sum`` on Linux/macOS, or a checksum verification tool on Windows).
-   [ ] **Flashing Software Installed:** Balena Etcher is downloaded and installed on your computer.
-   [ ] **SSH Client Ready:** You have an SSH client installed (PuTTY for Windows, or Terminal on Linux/macOS).
-   [ ] **(Optional) Monitor, Keyboard, HDMI Cable:** Available for initial setup and troubleshooting if needed.

Hardware Requirements - **In Detail**
-------------------------------------

Choosing the right hardware is crucial for a stable and performant Supernode.  Let's examine each component in detail:

*   **Rock 5B (32GB RAM model)  OR  Orange Pi 5 Plus (32GB RAM model)**

    *   **Why 32GB RAM?** Running both L1 and L2 nodes concurrently is memory-intensive. 32GB of RAM is the *minimum* recommended to prevent crashes, slowdowns, and out-of-memory errors during synchronization and operation.  Less RAM will severely impact performance and stability.

    *   **Rock 5B Buy Links (Verify 32GB Variant!):**

        *   `Rock 5B board 32 GB <https://shop.allnetchina.cn/products/rock5-model-b?variant=43726698709295>`_ **(Important: Ensure you select the 32GB RAM option on the product page!)**
        *   `Radxa power supply <https://shop.allnetchina.cn/products/radxa-power-pd-30w?variant=39929851904102>`_ (Official recommended power supply for Rock 5B)
    *   **Orange Pi 5 Plus Buy Links (Verify 32GB Variant!):**

        *   `Orange Pi 5 Plus 32 GB RAM <http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-5-plus-32GB.html>`_ **(Important: Confirm you are purchasing the 32GB RAM version. Check official site for authorized distributors in your region as links may change.)**
        *   Orange Pi 5 Plus kits often include a compatible power supply; check the product description.

*   **MicroSD Card:** 16GB minimum, Class 10 recommended.

    *   **Purpose:**  The MicroSD card will hold the operating system and boot files.  16GB is sufficient for the Ethereum on ARM image. Class 10 or higher ensures decent read/write speeds for smooth booting.

*   **NVMe SSD:** 4TB recommended (2TB *absolute minimum*).

    *   **Why NVMe SSD?**  Blockchain data is constantly being read and written. NVMe SSDs offer significantly faster read and write speeds compared to traditional SATA SSDs or hard drives. This speed is *essential* for blockchain synchronization and node performance.
    *   **Why 4TB (Recommended) / 2TB (Minimum)?**  The Ethereum blockchain is large and constantly growing.  A 4TB SSD provides ample space for both L1 and L2 chain data, allowing for future growth. While a 2TB SSD *might* be sufficient initially, it will become tighter over time, and 4TB is strongly recommended for long-term operation and to avoid disk space issues.
    *   **Recommended 4TB NVMe SSDs (High-End - Reliable and Performant):**

        *   **Western Digital SN850X 4TB:**  Widely regarded as a top-tier, highly reliable, and performant NVMe SSD.
        *   **Samsung 990 PRO 4TB:** Another excellent high-end option known for its speed and endurance.
        *   **SK Hynix Platinum P41 4TB:**  A strong performer with good power efficiency and reliability.
        *   **Crucial P3 Plus 4TB:** A good mid-range option that provides a balance of performance and reliability at a slightly lower price point than the top-tier drives.

    *   **Check Compatibility Resources:**

        *   `SSD list <https://docs.google.com/spreadsheets/d/1B27_j9NDPU3cNlj2HKcrfpJKHkOf-Oi1DbuuQva2gT4/edit>`_ (Community-maintained list of SSD compatibility for SBCs)
        *   `Great and less =great SSDs for Ethereum nodes <https://gist.github.com/yorickdowne/f3a3e79a573bf35767cd002cc977b038>`_ (Guidance on choosing suitable SSDs for Ethereum node workloads)

*   **Power Supply:**  Use the official power supply for your chosen board.

    *   **Importance of Official Power Supply:**  These powerful boards require stable and sufficient power. Using an underpowered or incompatible power supply can lead to instability, crashes, and even hardware damage.  Always use the official or recommended power supply.

*   **Ethernet Cable:**  Wired network connection is essential.

    *   **Why Wired Connection?**  A stable and reliable network connection is critical for a blockchain node.  Ethernet provides a more consistent and lower-latency connection than Wi-Fi, which is crucial for syncing and communicating with the network.  **Wi-Fi is strongly discouraged for node operation.**

*   **Case with Heatsink:** Proper cooling is critical.

    *   **Why Cooling?**  Rock 5B and Orange Pi 5 Plus are powerful single-board computers that can generate significant heat, especially under continuous 24/7 operation running resource-intensive blockchain nodes.  Overheating can lead to CPU throttling (slowing down performance), instability, and potentially shorten the lifespan of your hardware.
    *   **Heatsink (and Fan Recommended):**  A good case with a substantial heatsink is the *minimum*.  For optimal cooling, especially in warmer environments or for sustained high loads, consider a case with an *active* cooling solution (a heatsink with a fan).
    *   **Rock 5B Case Buy Links:**

        *   `Acrylic protector with passive heatsink <https://shop.allnetchina.cn/products/rock5-b-acrylic-protector?variant=39877626396774>`_ (Basic passive cooling)
        *   `Aluminum case with passive/active cooling <https://shop.allnetchina.cn/collections/rock5-model-b/products/ecopi-5b-aluminum-housing-for-rock5-model-b?variant=47101353361724>`_ (More robust cooling options)
    *   **Orange Pi 5 Plus case with heatsink Buy links:**

        *   `Orange Pi 5 Plus Case with heatsink <https://aliexpress.com/item/1005005728553439.html>`_ (Check AliExpress and other retailers for Orange Pi 5 Plus cases with cooling solutions.)

*   **(Optional) USB Keyboard, Monitor, and HDMI Cable:**

    *   **Purpose:**  These are helpful for the initial operating system installation, network configuration, and troubleshooting if you encounter issues. Once the node is set up and running, you can operate it "headless" (without a monitor, keyboard, or mouse) via SSH.

Software Prerequisites - **Step-by-Step Guide**
---------------------------------------------

1.  **Flash the Ethereum on ARM Image - Detailed Steps:**

    We will now prepare your MicroSD card with the necessary operating system and Ethereum node software.

    *   **Download the Appropriate Image (and Verify Checksum):**

        You need to download the correct Ethereum on ARM image specifically designed for your board. **Always verify the SHA256 checksum** after downloading to ensure the file is complete and not corrupted.  A corrupted image can lead to boot failures or system instability.

        *   **For Rock 5B (32GB):**

            *   Download Link: |rock5b_file|_
            *   SHA256 Checksum: |rock5b_sha256|

            **Verifying Checksum on Windows:**

            1.  Download a checksum verification tool like `HashCheck` (free and open-source).
            2.  Install HashCheck.
            3.  Right-click on the downloaded ``.img.zip`` file.
            4.  Select "Checksums" from the context menu.
            5.  HashCheck will calculate various checksums, including SHA256.
            6.  **Compare the calculated SHA256 value to the provided checksum:** |rock5b_sha256|.  **They MUST match exactly.** If they do not match, re-download the image file.

            **Verifying Checksum on macOS/Linux:**

            7.  Open your terminal application.
            8.  Navigate to the directory where you downloaded the ``.img.zip`` file using the ``cd`` command (e.g., ``cd Downloads``).
            9.  Run the following command in your terminal:

            .. prompt:: bash $

                sha256sum ethonarm_rock5b_25.11.00.img.zip

            10. **Compare the output to the provided checksum:** |rock5b_sha256|. **They MUST match exactly.** If they do not match, re-download the image file.

        *   **For Orange Pi 5 Plus (32GB):**

            *   Download Link: |orangepi5-plus_file|_
            
            *   SHA256 Checksum: |orangepi5-plus_sha256|

            **Verify Checksum (using the same methods as described for Rock 5B, but comparing against the Orange Pi 5 Plus checksum: |orangepi5-plus_sha256|).**

    *   **Flashing the Image onto the MicroSD Card - Using Etcher (Recommended):**

        Etcher is a user-friendly and reliable tool for flashing operating system images to SD cards and USB drives.

        1.  **Download and Install Etcher:**  If you haven't already, download and install Balena Etcher from `<https://www.balena.io/etcher/>`_. Choose the version for your operating system.

        2.  **Open Etcher:** Launch the Etcher application.

        3.  **Select Image:** Click "Flash from file" and choose the downloaded ``.img.zip`` file.  **(Do NOT unzip the file, Etcher can handle .zip directly.)**

        4.  **Select Target:** Click "Select target" and **carefully select your MicroSD card drive.**  **Double-check that you have chosen the correct drive letter for your MicroSD card.  Flashing to the wrong drive will erase data on that drive!** Etcher usually highlights removable drives to help prevent mistakes.

            .. image:: /_static/images/balena.png
               :alt: Etcher interface example
               :width: 600 px
               :align: center


        5.  **Flash!:** Click the "Flash!" button. Etcher will write the image to your MicroSD card and then verify the write process.

        6.  **Flash Complete:**  Wait until Etcher displays a "Flash Complete!" message. This may take several minutes.

        7.  **Safely Eject:** Safely eject the MicroSD card from your computer.  This is important to prevent data corruption. Use your operating system's "eject" or "safely remove hardware" function.

    *   **Flashing the Image - Using ``dd`` (Linux/macOS - Advanced Users):**

        The ``dd`` command is a powerful command-line tool for copying data, including flashing images to disk.  **However, it is also potentially dangerous if used incorrectly, as it can easily overwrite your hard drive.  Use this method with extreme caution and double-check all commands before executing.**

        1.  **Identify MicroSD Card Device Name:**  You need to determine the device name assigned to your MicroSD card by your operating system.  **Incorrectly identifying this device name can lead to data loss on your computer's hard drive.**

            Open your terminal and run:

            .. prompt:: bash $

                sudo fdisk -l

            Examine the output carefully. Look for a device that corresponds to the size of your MicroSD card. It will likely be something like ``/dev/mmcblk0`` or ``/dev/sdX`` (where X is a letter like ``a``, ``b``, ``c``, etc.).  **Be absolutely sure you have identified the correct device name.**

            **Example Output (Device names may vary):**

            .. code-block:: text

                Disk /dev/sda: 256GB ... (Your Hard Drive - DO NOT USE)
                Disk /dev/mmcblk0: 15.9GB ... (Likely your MicroSD Card - VERIFY SIZE!)


            **If you are unsure, remove and re-insert the MicroSD card and run ``sudo fdisk -l`` again to see which device appears/disappears.**

        2.  **Unzip the Image File:** Navigate to the directory where you downloaded the ``.img.zip`` file in your terminal and unzip it. For example, for the Rock 5B:

            .. prompt:: bash $

                unzip ethonarm_rock5b_24.09.00.img.zip

            This will extract the ``.img`` file (e.g., ``ethonarm_rock5b_24.09.00.img``).

        3.  **Flash the Image using ``dd``:**  **Double-check the command below VERY carefully before executing! Incorrect device name can lead to data loss!**

            Replace ``/dev/mmcblk0`` with the **correct device name** you identified for your MicroSD card.  Replace ``ethonarm_rock5b_24.09.00.img`` with the correct ``.img`` filename if you are using the Orange Pi 5 Plus image.

            .. prompt:: bash $

                sudo dd bs=1M if=ethonarm_rock5b_24.09.00.img of=/dev/mmcblk0 conv=fdatasync status=progress

            **Explanation of ``dd`` command options:**

            *   ``sudo``:  Runs the command with administrator privileges (required to write to disk devices).
            *   ``dd``: The command itself.
            *   ``bs=1M``: Sets the block size to 1 megabyte for faster transfer.
            *   ``if=ethonarm_rock5b_24.09.00.img``:  Specifies the **input file** – the ``.img`` file you extracted.
            *   ``of=/dev/mmcblk0``: Specifies the **output file** – **YOUR MICROSD CARD DEVICE NAME (VERY IMPORTANT TO BE CORRECT)**.
            *   ``conv=fdatasync``: Ensures data is physically written to disk before ``dd`` completes.
            *   ``status=progress``: Shows a progress bar during the flashing process (requires a recent version of ``dd``).

        4.  **Wait for Completion:** The ``dd`` command will take some time to complete.  The ``status=progress`` option will show you the progress.  **Do not interrupt the process.**  It is finished when you see output indicating completion and the command prompt returns.

        5.  **Safely Eject:** Safely eject the MicroSD card after the command completes.

2.  **Boot the Board - Initial Setup:**

    Now we will boot your Rock 5B or Orange Pi 5 Plus with the flashed MicroSD card and start the initial setup process.

    1.  **Insert MicroSD Card:** Insert the flashed MicroSD card into the MicroSD card slot on your Rock 5B or Orange Pi 5 Plus.
    2.  **Connect NVMe SSD:** Ensure your NVMe SSD is properly inserted into the NVMe slot on the board.
    3.  **Connect Ethernet Cable:** Connect an Ethernet cable from your router to the Ethernet port on the board.
    4.  **Connect Power Supply:** Connect the official power supply to the board and plug it into a power outlet. The board should power on automatically.
    5.  **Initial Boot & Setup Script:** The first boot will take significantly longer than subsequent boots (10-15 minutes).  During this time, the system will:

        *   Expand the filesystem on the MicroSD card to use the full space.
        *   Initialize the operating system.
        *   Install necessary software components.
        *   **The device will reboot automatically after the initial setup is complete.**

    6.  **Wait for Reboot:** Allow the board to complete the reboot process.  Do not interrupt power during this time.

    **Troubleshooting Boot Issues:**

    *   **Board Does Not Power On:**

        *   Check power supply connection at both the board and power outlet.
        *   Ensure you are using the official or recommended power supply.
        *   Try a different power outlet.
    *   **Board Powers On but No Network Connection:**

        *   Check Ethernet cable connection at both the board and router.
        *   Ensure the Ethernet cable is not damaged.
        *   Check your router to ensure it is functioning and providing DHCP addresses.
        *   Try booting the board *without* the NVMe SSD connected initially to rule out SSD-related boot issues.
    *   **Board Seems to be Booting but No Output (If using monitor):**

        *   Ensure HDMI cable is properly connected to both the board and monitor.
        *   Try a different HDMI cable and monitor if possible.
        *   Verify your monitor is powered on and set to the correct HDMI input source.
        *   It's possible the initial boot process is running headless, and you need to find the IP address (see next step) even if you have a monitor connected.


3.  **Log In and Change Password - Initial Access:**

    After the initial boot and automatic reboot, you need to log in to your Supernode to proceed with the setup. You can log in either via SSH (remotely from another computer on your network) or directly using a monitor and keyboard connected to the board.

    *   **Finding the IP Address - Methods:**

        To log in via SSH, you need to know the IP address assigned to your board on your local network. There are several ways to find this:

        *   **Method 1: Router Administration Interface (Recommended):**

            1.  Access your router's administration interface using a web browser.  The address is usually something like ``192.168.1.1`` or ``192.168.0.1``, but consult your router's documentation.
            2.  Look for a section like "DHCP Clients," "Attached Devices," or "Device List."
            3.  Find a device with the hostname likely related to your board (it might be generic or have a name like "orangepi," "rock5b," or similar). The IP address will be listed next to it.

        *   **Method 2: Using ``nmap`` (Network Scanner):**

            1.  If ``nmap`` is not installed on your desktop computer, install it.

                *   **Debian/Ubuntu/Raspberry Pi OS:** ``sudo apt-get update && sudo apt-get install nmap``
                *   **macOS (using Homebrew):** ``brew install nmap``
                *   **Windows:** Download from `<https://nmap.org/download.html>`_ and install.
            2.  Open your terminal or command prompt on your desktop computer.
            3.  Run the following command, replacing ``192.168.1.0/24`` with your network's subnet if it is different (your router's IP address usually indicates your subnet, e.g., if your router is ``192.168.0.1``, try ``192.168.0.0/24``):

            .. prompt:: bash $

                nmap -sP 192.168.1.0/24

            4.  ``nmap`` will scan your network and list devices that are up. Look for a device that is likely your board based on its MAC address (if you know it) or hostname (if available). The IP address will be listed next to it.

        *   **Method 3: Using ``fping`` (Faster Network Ping Scan):**

            1.  If ``fping`` is not installed, install it:

                *   **Debian/Ubuntu/Raspberry Pi OS:** ``sudo apt-get update && sudo apt-get install fping``
                *   **macOS (using Homebrew):** ``brew install fping``
                *   **Windows:**  ``fping`` is less common on Windows, ``nmap`` is generally preferred.
            2.  Run the following command, adjusting the subnet if needed:

            .. prompt:: bash $

                fping -a -g 192.168.1.0/24

            3.  ``fping`` will list live hosts on your network by IP address. You may need to cross-reference with MAC addresses or other methods to identify your board if multiple devices respond.

    *   **Logging in via SSH (Recommended for Remote Access):**

        1.  Open an SSH client on your desktop computer.

            *   **Linux/macOS:** Use the built-in ``ssh`` command in your terminal.
            *   **Windows:** Use PuTTY (download from `<https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html>`_).
        2.  Connect to the board's IP address using the following command (replace ``your_board_IP`` with the actual IP address you found):

            .. prompt:: bash $

                ssh ethereum@your_board_IP

        3.  **Default Credentials:** The default username is ``ethereum`` and the default password is ``ethereum``.

    *   **Direct Login (Monitor/Keyboard - If connected):**

        If you have a monitor and keyboard connected to your board, you can log in directly at the console prompt. Use the same default username (``ethereum``) and password (``ethereum``).

    *   **Changing the Default Password - Security Best Practice (Mandatory on First Login):**

        **Immediately upon your *first* successful login (either via SSH or direct login), you will be prompted to change the default password.**  This is a crucial security step.

        1.  You will be prompted to enter the "current password" (which is ``ethereum``).
        2.  Then, you will be prompted to enter a "new password."
        3.  Finally, you will be asked to "retype new password" to confirm.

        **Choose a strong, unique password that you will remember, and store it securely.  Write it down in a safe place if needed, but do not store it in plain text on your computer.**

        **You will need to log in *again* after changing the password, using your new password.** This completes the initial login and password change process.

Step 1: Setting up the Layer 1 (Ethereum) Node
-----------------------------------------------

The first crucial step in setting up your Optimism Supernode is to establish a fully synchronized Layer 1 (L1) Ethereum node.  This L1 node will serve as the foundation for your Layer 2 (Optimism) node.  It's important to ensure your L1 node is completely synchronized *before* proceeding to the L2 setup.

1.  **Choose your L1 Clients - Execution Layer (EL) and Consensus Layer (CL):**

    An Ethereum node is comprised of two main components:

    *   **Execution Layer (EL):**  Handles transaction execution, state management, and the Ethereum Virtual Machine (EVM).  Examples of EL clients include Geth, Nethermind, Erigon, and Besu.
    *   **Consensus Layer (CL):**  (Also known as the Beacon Chain) Handles block production, attestation, and finalization, ensuring network consensus. Examples of CL clients include Lighthouse, Prysm, Nimbus, Teku, Lodestar, and Grandine.

    The Ethereum on ARM image you flashed comes pre-configured to support several client combinations.  For this detailed guide, **we will use Geth as the Execution Layer (EL) client and Prysm as the Consensus Layer (CL) client.** These are popular and well-regarded clients. You can explore other client options later, but for a first-time setup, Geth and Prysm are recommended.

2.  **Start the Consensus Layer (CL) Client - Prysm Beacon Chain:**

    The Consensus Layer client (specifically, the Beacon Chain component) *must* be started and synchronized first. The Execution Layer client depends on the Consensus Layer for information about the canonical chain and consensus. Thanks to **Checkpoint Sync**, introduced in recent Ethereum upgrades, the initial synchronization of the Beacon Chain should be relatively fast, usually completing within minutes.

    .. prompt:: bash $

        sudo systemctl start prysm-beacon

    This command uses ``systemctl``, the system service manager in Linux, to start the ``prysm-beacon`` service.  This service is configured to run the Prysm Beacon Chain client.

3.  **Monitor the Beacon Chain Sync - Using ``journalctl``:**

    To check the progress of the Beacon Chain synchronization, we will use ``journalctl``, a tool for viewing systemd logs.  We will "follow" the logs of the ``prysm-beacon`` service, which means we will see new log messages in real-time as they are generated.

    .. prompt:: bash $

        sudo journalctl -fu prysm-beacon

    *   ``sudo``:  Runs the command with administrator privileges (needed to access system logs).
    *   ``journalctl``: The command for viewing systemd logs.
    *   ``-f``:  "Follow" mode - displays new log messages as they are added.
    *   ``-u prysm-beacon``:  Specifies that we want to see logs only for the ``prysm-beacon`` service.

    **Interpreting the ``journalctl -fu prysm-beacon`` Output:**

    When you run this command, you will see a stream of log messages in your terminal.  Look for the following indicators of successful synchronization:

    *   **"Synced" or "In sync" messages:**  Prysm will output log messages explicitly stating that it is synchronized or in sync with the Beacon Chain.  These messages are the primary indicator of successful Checkpoint Sync.
    *   **"Checkpoint sync completed" or similar messages:**  You might see messages indicating the Checkpoint Sync process has finished successfully.
    *   **Relatively stable log output:** Once synced, the log output will become less verbose and will show regular activity related to block processing and attestation, rather than continuous synchronization progress messages.

    **Example of Log Messages Indicating Sync Progress (These are illustrative, actual messages may vary slightly):**

    .. code-block:: text

        time="2024-10-27T10:00:00Z" level=info msg="Starting checkpoint sync" component=beacon
        time="2024-10-27T10:01:30Z" level=info msg="Checkpoint sync progress: 50%" component=beacon
        time="2024-10-27T10:02:45Z" level=info msg="Checkpoint sync progress: 90%" component=beacon
        time="2024-10-27T10:03:15Z" level=info msg="Checkpoint sync completed successfully" component=beacon
        time="2024-10-27T10:03:16Z" level=info msg="Beacon chain is now synced" component=beacon

    Once you see messages indicating "synced" or "checkpoint sync completed," you can typically stop monitoring the ``prysm-beacon`` logs by pressing ``Ctrl+C`` in the terminal.

    **Common Issues and Troubleshooting - Beacon Chain Sync:**

    *   **No Log Output or Errors:** If you run ``sudo journalctl -fu prysm-beacon`` and see no output or error messages, it could indicate:

        *   **Prysm Beacon Chain service failed to start:** Check the service status using ``sudo systemctl status prysm-beacon``.  If it's failed, try restarting it with ``sudo systemctl restart prysm-beacon``. Examine the output of ``sudo systemctl status prysm-beacon`` for more specific error details.
        *   **Firewall blocking connections:** Ensure your firewall (if enabled - UFW configuration is later in this guide) is not blocking outgoing connections for Prysm.
        *   **Network connectivity issues:** Double-check your Ethernet cable and router connection.

    *   **Syncing Stuck at a Low Percentage for a Long Time:** Checkpoint sync should be fast. If it appears stuck for more than 10-15 minutes, it could be a network issue or a problem with reaching checkpoint providers.  Restarting the ``prysm-beacon`` service (``sudo systemctl restart prysm-beacon``) might resolve temporary network glitches.

    *   **"Out of Memory" Errors in Logs:** While Checkpoint Sync is not usually memory intensive, if you see "out of memory" or similar errors, it could indicate a more serious system resource issue.  However, this is unlikely on a 32GB RAM system unless other processes are consuming excessive memory.

4.  **Start the Execution Layer (EL) Client - Geth:**

    After the Beacon Chain (Consensus Layer) is synchronized, you can start the Execution Layer client, Geth in our example.

    .. prompt:: bash $

        sudo systemctl start geth

    This command, similar to starting Prysm, uses ``systemctl`` to start the ``geth`` service.

5.  **Monitor the EL Client Sync - Geth Synchronization:**

    Synchronizing the Execution Layer (Geth) will take significantly longer than the Beacon Chain sync. Geth needs to download and process the entire history of the Ethereum blockchain's execution layer, which is a substantial amount of data.  Geth will go through several phases during synchronization, including:

    *   **Header Downloading:**  Downloading block headers, which contain metadata about each block in the chain.
    *   **Body Downloading:** Downloading block bodies, which contain the transactions within each block.
    *   **State Processing:** Processing the state trie, which represents the current state of the Ethereum network (accounts, balances, smart contract code, etc.). This is the most resource-intensive phase.

    **It is highly recommended to wait until Geth is fully synchronized before proceeding to the L2 setup.** Running the L2 node on top of an unsynchronized L1 node will likely lead to errors and synchronization issues on the L2 side as well.

    Monitor the Geth synchronization process using ``journalctl``:

    .. prompt:: bash $

        sudo journalctl -fu geth

    **Interpreting the ``journalctl -fu geth`` Output:**

    When you run this command, you will see a stream of logs from Geth. Look for the following indicators:

    *   **"Imported new block headers" messages:**  Initially, you will see many messages related to downloading block headers.  This is a good sign that Geth is actively syncing.
    *   **"Imported new block bodies" messages:** After header syncing, you will see messages about downloading block bodies.
    *   **"Imported new receipts" messages:** You will see messages about downloading transaction receipts.
    *   **"Imported new block headers" messages *consistently and frequently at the chain head*:**  **This is the key indicator of full synchronization.** Once Geth is fully synced, it will continuously import new blocks as they are produced on the Ethereum network. You will see "Imported new block headers" messages appearing regularly (every few seconds to tens of seconds) with increasing block numbers, reflecting the current chain head.
    *   **"Snapshot creation" phases (mentioned in original documentation - less emphasized now):** The original documentation mentions waiting for the "snapshot creation phase" to complete. This refers to Geth creating snapshots of the state for faster syncing.  While you may see messages related to snapshots, the most reliable indicator for proceeding is the consistent "Imported new block headers" at the chain head.
    *   **Absence of "Syncing" or "Catching up" messages:**  Initially, Geth logs will often include messages indicating it is "syncing" or "catching up." Once synced, these messages will subside, and you will primarily see messages about importing new blocks.

    **Example of Log Messages Indicating Geth Sync Progress (Illustrative, actual messages may vary):**

    .. code-block:: text

        ...
        INFO [10-27|10:10:00] Imported new block headers              count=192  elapsed=100ms  ...  headers=12345..12537  ...
        INFO [10-27|10:15:30] Imported new block bodies                count=256  elapsed=250ms  ...  bodies=1000..1256  ...
        INFO [10-27|10:20:45] Imported new receipts                   count=128  elapsed=150ms  ...  receipts=500..628  ...
        ... (Many more "Imported" messages as sync progresses) ...
        INFO [10-28|08:00:00] Imported new block headers              number=19000000 hash=0x... ...  elapsed=120ms  ...
        INFO [10-28|08:00:15] Imported new block headers              number=19000001 hash=0x... ...  elapsed=110ms  ...
        INFO [10-28|08:00:30] Imported new block headers              number=19000002 hash=0x... ...  elapsed=130ms  ...
        (Consistent "Imported new block headers" messages every ~10-30 seconds)

    .. note::
        Geth synchronization can take a significant amount of time, ranging from several hours to potentially a day or more, depending on your internet connection speed, SSD performance, and the current state of the Ethereum network. **Be patient and allow Geth to fully synchronize before moving on.**  You can leave the ``journalctl -fu geth`` command running in a terminal and check back periodically to monitor progress.

    **Common Issues and Troubleshooting - Geth (EL) Sync:**

    *   **Syncing Very Slow or Stuck:**

        *   **Check NVMe SSD Health and Performance:**  A slow or failing NVMe SSD will severely bottleneck Geth synchronization. Use system monitoring tools (like ``iotop``, ``iostat``, ``htop``) to check disk I/O activity and SSD performance.
        *   **Insufficient Free Disk Space:** Verify you have ample free space on your NVMe SSD.  If the SSD is nearing full capacity, Geth performance will degrade significantly, and sync may stall. Use ``df -h`` in the terminal to check disk space usage.
        *   **Slow or Unstable Internet Connection:** Geth requires a stable and reasonably fast internet connection to download blockchain data.  Check your internet speed and stability.  A poor internet connection is a common cause of slow sync.
        *   **Geth Process Consuming Excessive Resources (CPU/RAM):** While resource-intensive, Geth should run comfortably on a 32GB RAM Rock 5B or Orange Pi 5 Plus. Use ``htop`` or ``top`` to monitor CPU and RAM usage. If Geth is consuming excessive resources, and the system is swapping heavily (high swap usage in ``htop``), it might indicate a system issue or that other processes are consuming resources.  However, on a dedicated Supernode setup, this is less likely if you have followed hardware recommendations.
        *   **Geth Errors in Logs:** Examine the ``journalctl -fu geth`` output for any error messages.  Error messages can provide clues to the cause of sync problems.  Common errors might relate to network connectivity, database corruption (less common with fresh sync), or resource issues.
        *   **Restart Geth:**  Sometimes, restarting the Geth service can resolve temporary glitches or network issues.  Use ``sudo systemctl restart geth``.
        *   **Reboot the Board (as a last resort):** If restarting Geth doesn't help, a full system reboot (``sudo reboot``) might be necessary in rare cases to clear up system state issues.

    *   **"Database Corruption" or "State Trie Error" Messages (Less Common on Fresh Sync):** In rare cases, Geth may encounter database corruption issues.  If you see error messages in the logs related to database corruption or state trie errors, you *might* need to resync Geth from scratch.  However, this is less likely on a fresh installation. Resyncing from scratch is a lengthy process and should be considered only if other troubleshooting steps fail and error messages clearly point to database corruption.  (Resyncing instructions are beyond the scope of this basic guide, but involve stopping Geth, deleting the Geth data directory on your SSD, and restarting Geth).

    Once Geth is fully synchronized and you are seeing consistent "Imported new block headers" messages at the chain head, you can proceed to Step 2: Setting up the Layer 2 (Optimism) Node.

Step 2: Setting up the Layer 2 (Optimism) Node
-----------------------------------------------

Once your Layer 1 (L1) Ethereum node (Geth and Prysm) is fully synchronized, you can proceed to set up the Layer 2 (L2) Optimism node. The L2 node, in our case, consists of ``op-geth`` (Optimism's modified Geth) and ``op-node`` (the core Optimism node software).

1.  **Configure ``op-node`` - Connecting to the L1 Node:**

    The ``op-node`` needs to be configured to communicate with your fully synchronized L1 Ethereum node. Since both the L1 and L2 nodes are running on the *same* machine (your Rock 5B or Orange Pi 5 Plus), we can use ``localhost`` to refer to the L1 node's network interfaces.  We will modify the ``op-node.conf`` configuration file to ensure ``op-node`` knows where to find both the Execution Layer (Geth) and Consensus Layer (Prysm) of your L1 node.

    .. prompt:: bash $

        sudo sed -i 's/l1ip/localhost/' /etc/ethereum/op-node.conf
        sudo sed -i 's/l1beaconip/localhost/' /etc/ethereum/op-node.conf

    *   ``sudo``: Runs the command with administrator privileges (needed to modify system configuration files).
    *   ``sed``:  A stream editor command used for text manipulation. Here, we use it to replace text within a file.
    *   ``-i``:  "In-place" edit - modifies the file directly. **Be careful when using ``-i`` with ``sed``, as changes are permanent.**
    *   ``'s/l1ip/localhost/'``:  This is the ``sed`` substitution command.

        *   ``s/``:  Indicates a substitution operation.
        *   ``l1ip``: The text to be replaced (in this case, a placeholder ``l1ip`` likely present in the default ``op-node.conf`` file).
        *   ``localhost``: The text to replace it with (which resolves to the loopback address, referring to the same machine).
        *   ``/etc/ethereum/op-node.conf``:  Specifies the file to be modified - the configuration file for ``op-node``.
    *   The second ``sed`` command ``'s/l1beaconip/localhost/'`` similarly replaces the placeholder ``l1beaconip`` with ``localhost``, ensuring ``op-node`` knows where to find the L1 Beacon Chain.

    These commands essentially tell ``op-node``: "My L1 Ethereum node (both EL and CL components) is running on *this same machine*."

2.  **Start ``op-geth`` - Optimism Execution Client:**

    ``op-geth`` is a specially modified version of Geth adapted for the Optimism network. It serves as the Execution Layer for Optimism.  Start the ``op-geth`` service using ``systemctl``:

    .. prompt:: bash $

        sudo systemctl start op-geth

    This command starts the ``op-geth`` service, initiating the Optimism Execution Layer client.

3.  **Port Forwarding for ``op-geth`` - Enabling Snap Sync (Important):**

    ``op-geth`` utilizes a synchronization method called **Snap Sync**, which allows for faster initial synchronization of the Optimism chain. For Snap Sync to function correctly, ``op-geth`` needs to be reachable on port ``31303`` (TCP and UDP) from other peers in the Optimism network.  While we will configure the firewall on the Supernode itself later,  you may also need to configure **port forwarding on your *router*** if you are behind a home router and want your ``op-geth`` node to be publicly accessible for peering.

    **(Note:  For basic Supernode operation and participation, router port forwarding might not be strictly necessary, especially if you are primarily interested in local access and not maximizing peer connections. However, for optimal network participation and if you intend to offer public RPC services, port forwarding is generally recommended.)**

    **Router Port Forwarding (if needed - Router specific instructions vary):**

    1.  Access your router's administration interface (usually via a web browser, e.g., ``192.168.1.1`` or similar).
    2.  Find the Port Forwarding or NAT Forwarding settings.  The exact location and terminology vary greatly between router models. Consult your router's documentation.
    3.  Create a new port forwarding rule:

        *   **Service Name/Description:** (Optional)  Give it a descriptive name, like "op-geth Snap Sync."
        *   **Protocol:**  Select "TCP/UDP" or "Both."
        *   **External Port/Port Range:**  ``31303``
        *   **Internal Port/Port Range:** ``31303``
        *   **Internal IP Address/Destination IP:** Enter the **internal IP address of your Rock 5B or Orange Pi 5 Plus Supernode**.  This is the same IP address you use to SSH into your board.
        *   **Enable:** Ensure the port forwarding rule is enabled
		1.  Save the port forwarding settings on your router.  You may need to reboot your router for the changes to take effect.

    **UFW Firewall Configuration (on the Supernode itself) for ``op-geth`` will be covered in Step 3.**

4.  **Start ``op-node`` - Core Optimism Node Software:**

    ``op-node`` is the central software component of your Optimism node. It interacts with your L1 Ethereum node, manages the L2 chain state, and handles Optimism-specific logic. Start the ``op-node`` service:

    .. prompt:: bash $

        sudo systemctl start op-node

    This command initiates the ``op-node`` service.

5.  **Monitor the L2 Sync - ``op-geth`` and ``op-node`` Synchronization:**

    Now, we need to monitor the synchronization progress of both ``op-geth`` and ``op-node``.  Use ``journalctl`` to follow the logs for both services:

    .. prompt:: bash $

        sudo journalctl -fu op-geth
        sudo journalctl -fu op-node

    Open **two separate terminal windows** (or use terminal multiplexing like ``tmux`` or ``screen``) so you can view the logs for ``op-geth`` and ``op-node`` simultaneously.

    **Interpreting ``journalctl -fu op-geth`` Output (Optimism Geth Logs):**

    *   **Snap Sync Progress Messages:**  ``op-geth`` logs should show messages indicating the progress of Snap Sync.  Look for messages mentioning "Snap sync" and percentage progress.
    *   **Imported blocks on L2:** Similar to L1 Geth, you will see messages about "Imported new block headers" and "Imported new blocks" as ``op-geth`` synchronizes the Optimism chain.
    *   **Peer Connection Information:**  You may see logs related to ``op-geth`` connecting to peers in the Optimism network.

    **Example ``op-geth`` Log Messages (Illustrative):**

    .. code-block:: text

        time="2024-10-28T14:00:00Z" level=info msg="Starting snap sync" component=op-geth
        time="2024-10-28T14:30:00Z" level=info msg="Snap sync progress: 25%" component=op-geth
        time="2024-10-28T15:15:00Z" level=info msg="Snap sync progress: 50%" component=op-geth
        ...
        time="2024-10-29T02:00:00Z" level=info msg="Snap sync completed successfully" component=op-geth
        time="2024-10-29T02:00:05Z" level=info msg="Imported new block headers              number=1234567  hash=0x... ... " component=op-geth


    **Interpreting ``journalctl -fu op-node`` Output (Optimism Node Logs):**

    *   **L1 Connection Status:**  ``op-node`` logs should show messages indicating a successful connection to your L1 Ethereum node (Geth and Prysm running on ``localhost``).
    *   **L2 Chain Synchronization Progress:** ``op-node`` will coordinate the synchronization of the L2 chain. You will see messages related to L2 block processing, state updates, and interaction with ``op-geth``.
    *   **Derivation Pipeline Activity:** ``op-node`` uses a "derivation pipeline" to process L1 data and derive L2 blocks.  Logs related to the derivation pipeline indicate L2 synchronization activity.

    **Example ``op-node`` Log Messages (Illustrative):**

    .. code-block:: text

        time="2024-10-28T14:00:10Z" level=info msg="Connected to L1 Execution Layer" component=op-node l1_endpoint="http://localhost:8551"
        time="2024-10-28T14:00:12Z" level=info msg="Connected to L1 Consensus Layer" component=op-node l1_beacon_endpoint="http://localhost:4000"
        time="2024-10-28T14:15:30Z" level=info msg="Derivation pipeline: processing L1 block number=19000050 l2_block_number=100000" component=op-node
        ...
        time="2024-10-29T03:00:00Z" level=info msg="L2 chain is synchronized" component=op-node l2_block_number=1234567


    .. note::
        **Synchronization Time - Optimism L2 (Snap Sync):**

        The Optimism L2 chain synchronization using Snap Sync is generally faster than a full L1 Ethereum sync, but it still takes time. **The documentation estimates 10-15 hours for initial L2 sync.** The actual time can vary depending on network conditions and hardware performance. Be patient and allow both ``op-geth`` and ``op-node`` to complete their synchronization processes.

        You can consider the L2 node synchronized when:

        *   `op-geth` logs indicate "Snap sync completed successfully."
        *   `op-node` logs indicate "L2 chain is synchronized."
        *   Both ``op-geth`` and ``op-node`` logs show continuous activity at the chain head, indicating they are processing new L2 blocks as they are produced.

    **Common Issues and Troubleshooting - Optimism L2 Sync:**

    *   **`op-geth` Snap Sync Slow or Stuck:**

        *   **Network Connectivity:**  Ensure stable internet connection for ``op-geth`` to download snap sync data and connect to peers.
        *   **Port 31303 Accessibility (if relying on Snap Sync peering):** If you are relying on Snap Sync peering (and have not used a custom L1 endpoint for initial sync - which is not covered in this basic guide), ensure port 31303 (TCP/UDP) is open and forwarded on your router if needed.
        *   **SSD Performance:**  While Snap Sync is generally less disk-intensive than full L1 sync, a slow SSD can still impact performance. Check SSD health and I/O activity if sync is unusually slow.
        *   **Restart ``op-geth``:**  Restarting the ``op-geth`` service (``sudo systemctl restart op-geth``) might resolve temporary network issues or glitches in the sync process.

    *   **``op-node`` Not Connecting to L1:**

        *   **Verify L1 Node is Running and Synchronized:** Ensure your L1 Geth and Prysm services are running and fully synchronized *before* starting ``op-node``.  If the L1 node is not ready, ``op-node`` will fail to connect. Check ``journalctl -fu geth`` and ``journalctl -fu prysm-beacon`` to confirm L1 sync status.
        *   **``op-node.conf`` Configuration:** Double-check that you correctly configured ``/etc/ethereum/op-node.conf`` to point ``l1ip`` and ``l1beaconip`` to ``localhost``.  Typos in the configuration can prevent ``op-node`` from finding the L1 node.
        *   **Firewall Issues:**  While less likely to be the primary cause of L1 connection problems (as it's localhost communication), ensure your firewall is not *blocking* loopback (localhost) communication, though this is usually allowed by default.

    *   **"Out of Memory" Errors during L2 Sync:**  Running both ``op-geth`` and ``op-node`` adds to the overall memory usage. While 32GB RAM is generally sufficient, if you see "out of memory" errors in ``op-geth`` or ``op-node`` logs, it could indicate a system resource issue.  Ensure no other resource-intensive applications are running on the Supernode.  Monitor RAM usage with ``htop``.

    *   **General L2 Sync Stuck or Slow:**

        *   **Check Both ``op-geth`` and ``op-node`` Logs:** Examine the logs of both services to pinpoint where the sync process might be encountering issues. Errors in either service can halt or slow down L2 sync.
        *   **Restart Both ``op-geth`` and ``op-node``:**  Restarting both L2 components together (``sudo systemctl restart op-geth && sudo systemctl restart op-node``) can sometimes resolve synchronization problems.

    Once both ``op-geth`` and ``op-node`` are synchronized and running smoothly, you have successfully set up your Optimism L2 node on top of your L1 Ethereum node, creating a functional Optimism Supernode!  Proceed to Step 3 for optional but recommended firewall configuration.

Step 3: Firewall Configuration - **Securing Your Supernode (Recommended)**
--------------------------------------------------------------------------

Configuring a firewall is a **strongly recommended** security measure to protect your Supernode and home network. A firewall acts as a gatekeeper, controlling network traffic and preventing unauthorized access to your system.  We will use **UFW (Uncomplicated Firewall)**, a user-friendly and powerful firewall management tool that is readily available on the Ethereum on ARM image.

**Understanding Firewall Basics**

Think of a firewall as a set of rules that dictate what network traffic is allowed to enter and leave your Supernode. These rules are based on factors like:

*   **Direction:**
    *   **Incoming (IN):** Connections trying to reach your Supernode from the internet or your local network.
    *   **Outgoing (OUT):** Connections originating from your Supernode going out to the internet or your local network.
*   **Protocol:** The type of network communication (e.g., TCP, UDP).
*   **Port:**  A virtual "door" on your Supernode used for specific network services (e.g., port 22 for SSH, port 30303 for Ethereum P2P).
*   **Action:**  What to do with traffic matching the rule: `ALLOW` (let it pass) or `DENY` (block it).

**Initial Firewall Setup with UFW**

By default, UFW might be inactive. We'll enable it and set up basic rules to secure your Supernode while allowing essential services to function.

1.  **Enable UFW:**

    First, enable UFW if it's not already active.

    .. prompt:: bash $

        sudo ufw enable

    You may see a warning about SSH connections. **Don't worry yet!**  We'll add a rule to allow SSH access *before* locking down incoming traffic to prevent losing your SSH connection.

2.  **Allow SSH Connections - **VERY IMPORTANT!**:**

    **Crucially, before setting default policies, allow incoming SSH connections.  If you set the default to deny incoming traffic *first*, you could block yourself from accessing your Supernode via SSH and require direct console access to fix it.**

    .. prompt:: bash $

        sudo ufw allow ssh

    This command creates a rule that allows incoming TCP traffic on port 22, the standard port for SSH. UFW conveniently understands "ssh" as port 22.

    **Verify SSH Rule:**

    Let's quickly check if the SSH rule is active:

    .. prompt:: bash $

        sudo ufw status verbose

    You should see output similar to this confirming SSH is allowed:

    .. code-block:: text

        22/tcp                     ALLOW IN    Anywhere

    For initial setup, allowing SSH from "Anywhere" is fine.  For tighter security in a production setup, you could restrict SSH to your home network's IP range (an advanced topic).

3.  **Set Default Firewall Policies - Deny Incoming, Allow Outgoing:**

    Now, set the default behavior for incoming and outgoing connections. We'll set incoming to `DENY` (block everything coming in by default) and outgoing to `ALLOW` (allow your Supernode to connect out to the internet).

    .. prompt:: bash $

        sudo ufw default deny incoming
        sudo ufw default allow outgoing

    With these defaults, any *new* incoming connection will be blocked unless we explicitly create a rule to allow it. Outgoing connections will generally be permitted unless we create specific rules to block them (which we won't do in this basic guide).

4.  **Allow Essential Ports for Supernode Services:**

    We need to open specific ports to allow the necessary communication for your Ethereum and Optimism nodes to operate correctly.  Here are the ports to allow:

    *   **Geth P2P (Ethereum Layer 1):**
        *   **Port:** `30303`
        *   **Protocol:** TCP and UDP
        *   **Purpose:**  Essential for Geth to connect to other Ethereum peers, download blockchain data, and participate in the network.

    *   **Prysm P2P (Ethereum Consensus Layer - Beacon Chain):**
        *   **Port:** `13000`
        *   **Protocol:** TCP and UDP
        *   **Purpose:**  Needed for Prysm Beacon Chain to communicate with other Beacon Chain nodes for consensus and block validation.

    *   **Prysm Web UI (Optional):**
        *   **Port:** `4000`
        *   **Protocol:** TCP
        *   **Purpose:**  If you want to access the Prysm Web UI from your local network to monitor your Beacon Chain client. **Optional but recommended for monitoring.**

    *   **`op-geth` Snap Sync (Optimism Layer 2):**
        *   **Port:** `31303`
        *   **Protocol:** TCP and UDP
        *   **Purpose:** Required for `op-geth`'s Snap Sync feature to efficiently synchronize the Optimism chain and for peering in the Optimism network.

    *   **`op-node` Metrics (Optional):**
        *   **Port:** `7300`
        *   **Protocol:** TCP
        *   **Purpose:**  Exposes Prometheus metrics from `op-node` for advanced monitoring. **Optional for basic operation but useful for detailed monitoring if you set up Prometheus.**

    Add these rules to UFW:

    .. prompt:: bash $

        sudo ufw allow 30303/tcp
        sudo ufw allow 30303/udp
        sudo ufw allow 13000/tcp
        sudo ufw allow 13000/udp
        sudo ufw allow 4000/tcp
        sudo ufw allow 31303/tcp
        sudo ufw allow 31303/udp
        sudo ufw allow 7300/tcp

    Each `sudo ufw allow ...` command creates a rule to permit incoming traffic on the specified port and protocol.

    **Verify Firewall Rules Again:**

    Check the UFW status to confirm all the rules are in place:

    .. prompt:: bash $

        sudo ufw status verbose

    The output should now list rules similar to this (including the SSH rule and the ports you just added):

    .. code-block:: text

        Status: active
        Default: deny (incoming), allow (outgoing), deny (routed)
        New profiles: skip

        To                         Action      From
        22/tcp                     ALLOW IN    Anywhere
        30303/tcp                  ALLOW IN    Anywhere
        30303/udp                  ALLOW IN    Anywhere
        13000/tcp                  ALLOW IN    Anywhere
        13000/udp                  ALLOW IN    Anywhere
        4000/tcp                   ALLOW IN    Anywhere
        31303/tcp                  ALLOW IN    Anywhere
        31303/udp                  ALLOW IN    Anywhere
        7300/tcp                   ALLOW IN    Anywhere

    This confirms your firewall is active and allowing SSH and the necessary ports for your Supernode, while blocking other unsolicited incoming traffic.

5.  **Optional: Enable Firewall Logging:**

    For auditing or more in-depth troubleshooting, you can enable UFW logging. This records firewall activity to system logs.

    .. prompt:: bash $

        sudo ufw logging on

    To disable logging later:

    .. prompt:: bash $

        sudo ufw logging off

    UFW logs are usually stored in `/var/log/ufw.log`. You can examine these logs using tools like `cat`, `less`, or `grep` for advanced diagnostics if needed.

**Important Firewall Security Notes:**

*   **Test Your Rules:** After setting up your firewall, it's good practice to test it. You can use online port scanning tools from a network *outside* your home network (e.g., using a website port scanner) to verify that the intended ports (30303, 13000, 31303, 4000, 7300 if enabled) are open if you've configured router port forwarding for them. Be cautious when using online port scanners on public nodes.
*   **Firewall is One Layer of Security:**  A firewall is a vital security component, but it's not the only one.  Keep your system and software updated with security patches, use strong passwords, and be aware of the security implications of any services you run.
*   **Advanced Rules (Beyond this Guide):** For more advanced security setups, you could explore:
    *   **Restricting SSH access by IP address range:** Limit SSH access only to your home network's IP addresses for increased security.
    *   **Rate Limiting:** Implement rules to limit the rate of incoming connections to mitigate denial-of-service attempts. (Requires more advanced UFW configuration).

By completing these steps, you've implemented a fundamental firewall on your Optimism Supernode using UFW, significantly enhancing its security.

Step 4: Verification and Monitoring - Ensuring Your Supernode is Running Correctly
----------------------------------------------------------------------------------

After completing the installation and firewall configuration, it is crucial to **verify** that your Optimism Supernode is running correctly and that all components are synchronized and operating as expected.  Regular monitoring is also important to ensure continued healthy operation.

**Verification Methods - Step-by-Step Checks:**

1.  **Check Service Status - Using `systemctl status`:**

    The most basic verification step is to check the status of all the systemd services you started: `prysm-beacon`, `geth`, `op-geth`, and `op-node`.  Use `systemctl status` for each service:

    .. prompt:: bash $

        sudo systemctl status prysm-beacon
        sudo systemctl status geth
        sudo systemctl status op-geth
        sudo systemctl status op-node

    For each service, you should look for the following in the `systemctl status` output:

    *   **"Active: active (running)"**: This is the most important indicator. It confirms that the service is currently running without errors.
    *   **"Loaded: loaded..."**: Indicates that the service unit configuration has been loaded successfully.
    *   **"Main PID: ..."**: Shows the process ID (PID) of the main process for the service.
    *   **"CGroup: ..."**:  Shows the control group the process belongs to.
    *   **"Logs:"**:  The `systemctl status` output often includes a snippet of recent logs from the service. This can be a quick way to spot any immediate errors or warnings during startup.

    **Example of a Healthy Service Status Output (Illustrative - output may vary slightly):**

    .. code-block:: text

        ● prysm-beacon.service - Prysm Beacon Chain Client
             Loaded: loaded (/etc/systemd/system/prysm-beacon.service; enabled; vendor preset: enabled)
             Active: active (running) since Mon 2024-10-28 05:00:00 UTC; 1 day 5h ago
           Main PID: 12345 (beacon-chain)
              Tasks: 25 (limit: 4915)
             CGroup: /system.slice/prysm-beacon.service
                     └─12345 /usr/bin/beacon-chain --config-file=/etc/ethereum/prysm-beacon.conf

        Oct 28 05:00:00 your_hostname systemd[1]: Started Prysm Beacon Chain Client.
        Oct 28 05:00:05 your_hostname beacon-chain[12345]: time="2024-10-28T05:00:05Z" level=info msg="Beacon chain started" ...

    If you see "Active: inactive (dead)" or "Active: failed" in the service status, it indicates that the service is not running or has encountered an error during startup.  In such cases, examine the full `systemctl status <service_name>` output, especially the "Logs" section and any error messages, to diagnose the issue.  You can also use `journalctl -u <service_name>` to view more detailed logs for the service.

2.  **Check Synchronization Status - Using Logs (`journalctl`)**:

    We have already used `journalctl -fu` to monitor synchronization *progress*. Now, we can use `journalctl` to quickly check the current synchronization *status* of each component.  We are looking for log messages that indicate "synced" or chain head activity.

    *   **Prysm Beacon Chain (CL):**

        .. prompt:: bash $

            sudo journalctl -u prysm-beacon -n 20 --no-pager | grep -i "synced\|in sync"

        *   `sudo journalctl -u prysm-beacon -n 20 --no-pager`:  Displays the last 20 log lines for the `prysm-beacon` service without using a pager (so you see all lines directly in the terminal).
        *   `| grep -i "synced\|in sync"`:  Pipes the output to `grep` to filter for lines containing either "synced" or "in sync" (case-insensitive `-i`).

        You should see output lines containing messages like: `"Beacon chain is now synced"` or `"In sync with chain head"`.  If you see these messages in the recent logs, it confirms that Prysm Beacon Chain is synchronized.

    *   **Geth (L1 EL):**

        .. prompt:: bash $

            sudo journalctl -u geth -n 20 --no-pager | grep "Imported new block headers"

        *   Similar to Prysm, but we filter for `"Imported new block headers"` messages, which indicate Geth is at the chain head and continuously importing new blocks.

        You should see output lines similar to: `"Imported new block headers              number=... hash=0x... ..."` in the recent logs, with increasing block numbers, confirming Geth is synchronized.

    *   **`op-geth` (L2 EL):**

        .. prompt:: bash $

            sudo journalctl -u op-geth -n 20 --no-pager | grep -i "snap sync completed\|imported new block"

        *   Filters for messages related to "snap sync completed" or "imported new block".

        Look for lines indicating `"Snap sync completed successfully"` or recent `"Imported new block headers"` messages to verify `op-geth` synchronization.

    *   **`op-node` (L2 Node):**

        .. prompt:: bash $

            sudo journalctl -u op-node -n 20 --no-pager | grep -i "l2 chain is synchronized\|derivation pipeline"

        *   Filters for messages containing `"l2 chain is synchronized"` or `"derivation pipeline"`.

        Look for lines indicating `"L2 chain is synchronized"` or recent `"Derivation pipeline: processing L1 block ... l2_block_number=..."` messages with increasing L2 block numbers, confirming `op-node` synchronization.

3.  **Check RPC Endpoints - Using `curl` (Optional but Recommended for Deeper Verification):**

    For a more thorough verification, you can check if the RPC (Remote Procedure Call) endpoints of your node components are responding correctly. RPC endpoints allow you to interact with your node programmatically (e.g., to query blockchain data, submit transactions, etc.).

    We will use `curl`, a command-line tool for transferring data with URLs, to make simple requests to the RPC endpoints.  The Ethereum on ARM image pre-configures RPC endpoints for Geth, Prysm, `op-geth`, and `op-node`.

    *   **Geth (L1 EL) - Check `eth_syncing` RPC Method:**

        .. prompt:: bash $

            curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' http://localhost:8551

        *   `curl`: The command-line tool for making HTTP requests.
        *   `-s`:  Silent mode - suppresses progress meter and error messages (cleaner output).
        *   `-X POST`: Specifies the HTTP method as POST (required for JSON-RPC requests).
        *   `-H "Content-Type: application/json"`: Sets the `Content-Type` header to indicate JSON data.
        *   `--data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'`:  This is the JSON-RPC request payload.  We are calling the `eth_syncing` method, which returns synchronization status.
        *   `http://localhost:8551`: The RPC endpoint for Geth (default configuration).

        **Expected Output if Geth is Synced:**

        If Geth is fully synchronized, the `eth_syncing` RPC method should return `false`:

        .. code-block:: json

            {"jsonrpc":"2.0","id":1,"result":false}

        If Geth is still syncing, it will return an object with synchronization progress details (start block, current block, highest block, etc.).  If you get an error or no response, it indicates a problem with the Geth RPC endpoint or Geth itself.

    *   **Prysm Beacon Chain (CL) - Check `eth_syncing` RPC Method (Beacon API):**

        Prysm's Beacon Chain client has a different API than Geth's. We can use its Beacon API to check sync status.  We can query the `eth/v1/syncing` endpoint:

        .. prompt:: bash $

            curl -s http://localhost:4000/eth/v1/syncing

        *   `http://localhost:4000/eth/v1/syncing`: The Beacon API endpoint for sync status.

        **Expected Output if Prysm Beacon Chain is Synced:**

        If Prysm is synced, the `syncing` endpoint should return `false`:

        .. code-block:: json

            {"data":{"head_slot":"...","syncing":false,"...":...}}

        Look for `"syncing":false` in the JSON response. If it returns `"syncing":true`, Prysm is still synchronizing.  Errors or no response indicate a problem with the Prysm Beacon API or Prysm itself.

    *   **`op-geth` (L2 EL) - Check `eth_syncing` RPC Method (same as Geth):**

        `op-geth` uses the same JSON-RPC API as Geth.  We can use the same `eth_syncing` method check:

        .. prompt:: bash $

            curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' http://localhost:8551

        **(Note:  `op-geth` and Geth, in the default configuration, both use the same RPC port `8551`.  This might seem confusing.  However, the `op-node` and other L2 components are configured to communicate with `op-geth` specifically, even if they share the same port number. In a more complex setup, you might configure them to use different ports if needed, but the default is port 8551 for both EL clients.)**

        **Expected Output (same as Geth):**

        If `op-geth` is synced, `eth_syncing` should return `false`:

        .. code-block:: json

            {"jsonrpc":"2.0","id":1,"result":false}

    *   **`op-node` (L2 Node) - Check Metrics Endpoint (Prometheus Metrics):**

        `op-node` exposes Prometheus metrics on port `7300` (if you enabled the firewall rule for it).  Prometheus metrics are used for monitoring and collecting performance data.  We can use `curl` to fetch these metrics and verify the endpoint is working.

        .. prompt:: bash $

            curl -s http://localhost:7300/metrics

        *   `http://localhost:7300/metrics`:  The Prometheus metrics endpoint for `op-node`.

        **Expected Output (Metrics Data):**

        If the `op-node` metrics endpoint is working, `curl` will return a large amount of text data in Prometheus metrics format.  You don't need to interpret all the metrics in detail right now, but if `curl` returns a long text output starting with lines like `# HELP ...` and `# TYPE ...`, it confirms that the metrics endpoint is functional and `op-node` is likely running correctly. If you get an error or no response, it indicates a problem with the `op-node` metrics endpoint or `op-node` itself.

**Regular Monitoring - Keeping an Eye on Your Supernode:**

Once your Supernode is verified and running, it's important to monitor it regularly to ensure continued healthy operation.  You can use the same `journalctl` commands and RPC endpoint checks described above for ongoing monitoring.  You can also consider setting up more advanced monitoring tools for proactive alerting and performance analysis (discussed briefly in the "Advanced Topics" section).  Regularly check for updates to the Ethereum on ARM image and your node software to ensure you are running the latest versions with security patches and performance improvements.

Step 5: Advanced Topics and Next Steps
--------------------------------------

Congratulations! You have successfully set up a basic Optimism Supernode.  With your own Supernode running, you are now directly participating in both the Ethereum and Optimism networks.  This section outlines some advanced topics and potential next steps you can explore to further enhance your Supernode setup and engagement with the ecosystem.

**1. Advanced Monitoring and Alerting:**

The verification and monitoring methods described in Step 4 are a good starting point, but for more comprehensive and proactive monitoring, consider setting up dedicated monitoring tools.

*   **Prometheus and Grafana:**

    *   **Prometheus:**  We already verified that `op-node` exposes Prometheus metrics on port `7300`. Prometheus is a powerful open-source system monitoring and alerting toolkit. You can configure Prometheus to scrape metrics from `op-node` (and potentially also Geth and Prysm if you configure their metrics endpoints, though `op-node` metrics are most relevant for L2 Supernode operation).
    *   **Grafana:** Grafana is a popular open-source data visualization and dashboarding tool. You can connect Grafana to your Prometheus instance and create custom dashboards to visualize your Supernode's performance, synchronization status, resource usage, and other key metrics in real-time.
    *   **Pre-built Dashboards:**  The Optimism and Ethereum communities often share Grafana dashboards specifically designed for monitoring nodes. Searching online for "Grafana dashboards Optimism node" or "Grafana dashboards Ethereum node" can provide useful starting points.
    *   **Alerting:** Prometheus also allows you to configure alerting rules. You can set up alerts to notify you (via email, Slack, etc.) if critical metrics deviate from expected values (e.g., node is out of sync, high CPU/memory usage, service down).

    Setting up Prometheus and Grafana is a more advanced topic and involves installing and configuring these tools, defining scrape configurations, and building dashboards.  Numerous online tutorials and guides are available for setting up Prometheus and Grafana monitoring.

*   **System Monitoring Tools (Command-line):**

    For quick checks directly on your Supernode, command-line tools like `htop`, `top`, `vmstat`, `iostat`, `iotop`, and `df -h` (mentioned earlier) are invaluable for real-time resource monitoring (CPU, RAM, disk I/O, disk space).  Become familiar with these tools to quickly assess your system's health.

**2. Maintaining Your Supernode - Updates and Security:**

*   **Operating System and Software Updates:**

    It is essential to keep your Supernode's operating system and node software up to date with the latest security patches and bug fixes. Regularly update your system using `apt update && apt upgrade`:

    .. prompt:: bash $

        sudo apt update
        sudo apt upgrade

    This will update the base operating system and any installed packages, including security updates.

*   **Ethereum on ARM Image Updates:**

    The Ethereum on ARM image itself may be updated periodically with new versions of node software, OS improvements, and configuration changes.  Stay informed about new image releases from the Ethereum on ARM project (check their website, community forums, or release announcements).  When a new image is released, consider flashing the new image to a *new* MicroSD card and migrating your configuration and data (if necessary and if you made customisations beyond the basic guide setup) to the new image.  **Always back up your configuration before making major system changes or flashing new images.**

*   **Node Client Updates (Advanced - usually managed by the image):**

    In most cases, the Ethereum on ARM image manages the versions of Geth, Prysm, `op-geth`, and `op-node` clients.  Updating the image is the recommended way to update these components.  However, if you become more advanced, you *could* potentially update individual node clients manually (e.g., by downloading new binaries and replacing existing ones).  Manual updates are generally not recommended for beginners and should be done with caution and following official documentation for each client.  Incorrect manual updates can lead to node instability or failure.

*   **Security Best Practices (Review and Enhance):**

    Revisit the firewall configuration (Step 3) periodically.  As you become more familiar with your Supernode and its network activity, you might want to refine your firewall rules to further enhance security (e.g., restrict SSH access, implement rate limiting, etc.).  Research best practices for securing Linux servers and Ethereum nodes.

**3. Exploring Advanced Configurations (For Experienced Users):**

Once you have a solid understanding of the basic Supernode setup, you can explore more advanced configuration options. **Proceed with caution when modifying advanced settings, and always back up your configuration files before making changes.**

*   **Customizing Node Client Configurations:** The Ethereum on ARM image provides default configurations for Geth, Prysm, `op-geth`, and `op-node`.  You can examine the configuration files (e.g., `/etc/ethereum/geth.conf`, `/etc/ethereum/prysm-beacon.conf`, `/etc/ethereum/op-node.conf`, `/etc/ethereum/op-geth.conf`) to understand the available settings and potentially customize them.  Configuration options might include:    
    
    *  **P2P Network Settings:**  Adjusting peer limits, network ports, and discovery settings.
    *  **Data Storage Paths:**  Changing the default directories where blockchain data is stored (if you have specific storage requirements, although the default NVMe SSD setup is generally recommended).
    *  **RPC Endpoint Configuration:**  Customizing RPC ports, enabling/disabling RPC methods, and setting RPC access control (e.g., limiting RPC access to specific IP addresses - for security if exposing RPC endpoints publicly).
    *  **Resource Limits (Advanced):** In very specific scenarios, you *might* consider adjusting resource limits for node processes (CPU affinity, memory limits, etc.), but this is generally not necessary on a properly sized 32GB RAM system for a Supernode.  Incorrectly set resource limits can harm performance.

*   **Exposing RPC Endpoints Publicly (With Security Considerations - Advanced):**

    By default, the RPC endpoints for Geth, Prysm, and `op-geth` are configured to listen on `localhost` only. This means they are only accessible from within the Supernode itself.  For certain use cases (e.g., accessing your node's RPC from applications outside your Supernode, offering public RPC services - advanced topics, not covered in this basic guide), you *could* configure the RPC endpoints to be accessible from your local network or even publicly on the internet.

    **Exposing RPC endpoints publicly significantly increases security risks.** If you choose to do this, you **must** implement strong security measures, including:
    
    *   **Firewall Rules:**  Restrict access to RPC ports to only the necessary IP addresses or network ranges.
    *   **RPC Authentication:**  Enable RPC authentication (using API keys or similar mechanisms) if supported by the client software.
    *   **Rate Limiting:** Implement rate limiting on RPC requests to prevent abuse and denial-of-service attacks.
    *   **Carefully Choose Exposed RPC Methods:** Disable or restrict access to potentially dangerous RPC methods if not absolutely necessary.
    *   **Understand the Risks:**  Thoroughly research the security implications of exposing RPC endpoints before doing so.

    **For most users running a Supernode primarily for personal use and network contribution, exposing RPC endpoints publicly is NOT recommended and adds unnecessary security complexity.** Local RPC access (from within the Supernode itself) is usually sufficient for most use cases.

**4. What Can You Do With Your Supernode? - Use Cases:**

Now that you have a running Optimism Supernode, what can you actually *do* with it?

*   **Support Decentralization and Network Health:**  By running a Supernode, you are directly contributing to the decentralization, robustness, and censorship resistance of both the Ethereum and Optimism networks. This is a valuable contribution in itself.
*   **Private and Sovereign Access to Ethereum and Optimism:**  You have your own private gateway to interact with both networks, without relying on centralized third-party providers. This enhances your privacy and control.
*   **Local RPC Access for Development and Tools:**  You can use the local RPC endpoints of your Supernode (e.g., Geth and `op-geth` RPC on `http://localhost:8551`) to connect your own software, scripts, or development tools directly to the Ethereum and Optimism networks. This can be useful for developers, researchers, or advanced users who want to interact with the blockchains programmatically.
*   **Potential Future Advanced Features:** As the Optimism ecosystem evolves, running your own Supernode might unlock access to advanced features, staking opportunities (if and when available for Optimism), or governance participation in the future. Stay informed about developments in the Optimism ecosystem.
*   **Running Local Dapps and Tools (Advanced):** With advanced configuration, you *could* potentially host certain types of decentralized applications or tools that rely on direct access to your Supernode's RPC endpoints.  However, this is an advanced topic with security considerations.

**5. Join the Community and Stay Informed:**

*   **Ethereum on ARM Community:** Engage with the Ethereum on ARM community Discord.  This is a great place to ask questions, share your experiences, get help with troubleshooting, and stay informed about updates and best practices for running Ethereum nodes on ARM hardware.
*   **Optimism Community:**  Participate in the Optimism community forums, Discord channels, or governance discussions. Stay up-to-date with Optimism network upgrades, new features, and community initiatives.
*   **Ethereum Ecosystem Resources:**  Continue learning about Ethereum, Optimism, and blockchain technology in general through online resources, documentation, blog posts, and educational materials.

**Disclaimer and Important Notes:**

*   **Running a node involves technical complexity and ongoing maintenance.** This guide provides a comprehensive starting point, but you may encounter issues or need to adapt your setup as software and network conditions evolve.
*   **Software is constantly evolving.** The specific commands, configurations, and recommendations in this guide may become outdated over time. Always refer to the latest official documentation and community resources for the most up-to-date information.
*   **Security is your responsibility.**  While this guide includes basic security recommendations (firewall configuration), it is your responsibility to ensure the security of your Supernode. Stay informed about security best practices and take appropriate measures to protect your system.
*   **Resource requirements may change.** The 32GB RAM recommendation is based on current software versions and network conditions. Future software updates or increased network activity might require more resources. Monitor your Supernode's resource usage and be prepared to adjust hardware if needed in the future.
*   **Understand the risks.** Running a blockchain node involves technical, operational, and potentially security risks. Ensure you understand these risks before proceeding.

We hope this detailed guide has been helpful in setting up your Optimism Supernode! Happy node running!