Verifying Optimism Challenger
=============================

Once you have installed and started the Optimism Challenger, it is crucial to verify that it is operating correctly and actively participating in the Fault Proof system.

Service Status
--------------

First, ensure the service is active and running:

.. code-block:: bash

    sudo systemctl status op-challenger

You should see ``Active: active (running)`` in the output.

Log Verification
----------------

The most effective way to verify operation is by checking the logs.

.. code-block:: bash

    sudo journalctl -fu op-challenger

**Signs of a Healthy Challenger:**

1.  **Game Tracking:** You should see logs indicating that the challenger is tracking "games".
    
    .. code-block:: text
    
       INFO [01-01|12:00:00] Acted on game    game=0x... type=FaultDisputeGame status=InProgress

2.  **No Errors:** Ensure there are no repeated error messages regarding connection to the L1 node or the dispute game factory.

Monitoring
----------

A Grafana dashboard "Op - Challenger" is available in the Ethereum on ARM monitoring stack (if installed). This dashboard provides visual insights into:

-   **Game Status:** The number of active games and their statuses.
-   **Resolution Rate:** How many games are being resolved over time.
-   **Service Uptime:** Historical uptime of the challenger service.

Troubleshooting
---------------

**Issue: "Failed to connect to L1"**

-   Check that your L1 Ethereum node (Geth/Nethermind) is fully synced.
-   Verify the RPC URL in ``/etc/ethereum/op-challenger.conf``.

**Issue: "Game factory not found"**

-   Ensure you are using the correct network configuration (Mainnet vs. Sepolia).
-   Check if the ``--game-factory-address`` is correctly set for the network.
