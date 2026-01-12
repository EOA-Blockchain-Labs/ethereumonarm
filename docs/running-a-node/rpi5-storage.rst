Raspberry Pi 5 Example Setup
============================

.. meta::
   :description lang=en: Raspberry Pi 5 NVMe storage guide for Ethereum nodes. Recommended NVMe HATs, compatible SSDs, and setup instructions for blockchain storage.
   :keywords: Raspberry Pi 5 NVMe, NVMe HAT, GeeekPi N04, Geekworm X1001, RPi5 Ethereum storage

This guide helps you put together and use a Raspberry Pi 5 16GB with a 52Pi Aluminum Case and NVMe HAT.


You can also follow along with a video tutorial: `Assembly Tutorial <https://youtu.be/uEBLLqBGBJc>`_

What's in the Box?
------------------

The package includes:
   * Aluminum Case
   * NVMe HAT
   * Raspberry Pi Active Cooler
   * PCIe 3.0 x1 FPC for RPI 5
   * 8.5*40mm PCIe FFC cable
   * 2.54 Connector Socket 2*2Pcs
   * 40Pin heightened pin header
   * M2.5*19mm Double-pass copper pillar
   * M2.5 5+5mm copper pillar
   * M1.5+5mm Hard drive copper pillars x 1
   * M2*3 Ball head screw x 2
   * Hexagon socket screws
   * M2.5+4mm (for board) Flat head screws
   * M2.5+4mm (for case) Flat head screws
   * Allen wrench
   * Screw driver
   * Anti-slippery rubber feet

* **Aluminum Case:** A strong case that protects your Raspberry Pi 5 and keeps it cool.
* **NVMe HAT:** A special add-on that lets you connect a fast NVMe SSD for storage.
* **Active Cooler:** A small fan that helps cool down the Raspberry Pi 5 when it's working hard.
* **Screws and Pillars:** These are for attaching the different parts together.
* **FFC Cable:** A flat cable that connects the NVMe HAT to the Raspberry Pi.
* **Connectors:** Small parts that connect to the FFC cable.
* **GPIO Header:** A row of pins that you can use to connect other things to the Raspberry Pi.
* **Tools:** An Allen wrench and screwdriver to help you put everything together.
* **Rubber Feet:** These stick to the bottom of the case so it doesn't slide around.

Putting it Together
-------------------

.. important::
   Before you begin, make sure your Raspberry Pi 5 is powered off and unplugged to avoid any risk of electrical shock.

1. **Prepare the Raspberry Pi 5:**
   	* Ensure you have a Raspberry Pi 5 16GB model.
   	* **(Recommended) Install Active Cooler:** It's easier to install the active cooler now, before putting the Pi in the case. Follow the instructions that came with the cooler. You can optionally apply thermal paste or thermal pads to the Pi's CPU for better cooling.
   	* **(Optional) Thermal Paste/Pads:** If you have thermal paste or pads, you can apply a small amount to the top of the Pi's CPU chip before installing the cooler. This helps transfer heat more efficiently.

2. **Install the NVMe SSD:**
    * **Find the M.2 Slot:** Look for a long, thin slot on the NVMe HAT. This is where the SSD goes.
    * **Check the Key:** Make sure your NVMe SSD has an **M Key** or a **B Key**.  Regular SATA SSDs won't work.
    * **Connect the SSD:** Carefully slide the SSD into the slot at an angle.
    * **Secure the SSD:** Push the SSD down until it's flat and screw it in place using the M1.5+5mm hard drive copper pillar.

3. **Connect the NVMe HAT:**
   	* **Install the GPIO Header Extension:** Before attaching the HAT, carefully align and install the 40Pin heightened pin header onto the GPIO pins of the Raspberry Pi. This will make it easier to connect the FFC cable.
   	* **Find the PCIe Connector:** There's a small connector on the Raspberry Pi and the NVMe HAT.
   	* **Connect the Cable:** Gently plug one end of the FFC cable into the Raspberry Pi and the other end into the NVMe HAT. Make sure it's connected properly on both sides. Be careful not to bend or crease the cable.
   	* **Attach the HAT:** Line up the pins on the bottom of the HAT with the extended GPIO pins on the Raspberry Pi. Gently push it down until it's secure. Use the M2.5+4mm flat head screws (for board) to attach the HAT to the Pi.

4. **Put it in the Case:**
    * Carefully place the Raspberry Pi (with the cooler, NVMe HAT, and cable) into the aluminum case.
    * **Install Side Panels:** First, slide in the USB side panel. If it's difficult, loosen the standoffs a bit. Once the USB panel is in, tighten the standoffs fully. Then, add the other side panels, making sure they are in the right places.
    * **Fit the Lid:** Place the lid on the case, making sure the ventilation holes line up correctly. Once all the panels have clicked in, use the remaining screws to secure the lid.

5. **Connect Everything:**
    * Plug in your monitor, keyboard, mouse, and power cable.


Where to Buy the Parts
----------------------

* **Raspberry Pi 5 16GB:** You can buy this from the official Raspberry Pi website or stores that sell electronics.
   * Example: `Raspberry Pi Official Website <https://www.raspberrypi.com/products/raspberry-pi-5/>`_

* **52Pi Aluminum Case with Cooler and NVMe HAT:** You can find this on the 52Pi website.
   * Example: `52Pi Product Page <https://52pi.com/collections/new-arrivals/products/52pi-aluminum-case-for-raspberry-pi-5-with-official-active-cooler-p33-m-2-nvme-m-key-poe-hat>`_ 

* **NVMe SSD:** * **Make sure it works:** Not all NVMe SSDs work with Raspberry Pi. Look for one with an **M Key** or **B Key**. Avoid SSDs with "Phison" controllers, they sometimes have problems.
    * **Size:** The case fits different sizes of SSDs. If you want a lot of storage (like 4TB), you'll need a bigger SSD.
    * **Good SSDs:**
        * **Samsung 990 Pro:** This one is very fast and reliable.
        * **Seagate FireCuda 530:** Another good option if you need a lot of speed.
        * **Crucial P5 Plus:** This one is a bit cheaper but still works well.
    * **Check before you buy:** It's always a good idea to check online forums or the 52Pi website to make sure the SSD will work with your Raspberry Pi.

* **Power Supply:** Use a good quality power supply that can provide enough power for the Raspberry Pi and the SSD.

* **Ethernet Cable:** If you want to connect your Raspberry Pi to the internet, you'll need an Ethernet cable.


Power Consumption
-----------------

* The Raspberry Pi 5, the SSD, and the cooler all use power.
* Make sure your power supply is strong enough to power everything.
* You can find more information about power usage on the official Raspberry Pi website.

Disclaimer
----------

This guide is just to help you. The information might change, so always check the official websites for the latest details.
